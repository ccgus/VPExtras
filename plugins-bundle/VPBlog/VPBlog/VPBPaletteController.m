//
//  VPBPaletteController.m
//  VPBlog
//
//  Created by August Mueller on 4/2/12.
//  Copyright (c) 2012 Flying Meat. All rights reserved.
//

#import "VPBPaletteController.h"
#import "VPPrivateStuff.h"
#import "VPBWriter.h"

NSString *VPBPUTTypeMarkdownSource = @"net.daringfireball.markdown";
NSString *VPBPUTTypeJSTalkSource = @"org.jstalk.jstalk-source";

@interface VPBPaletteController ()

@end

@implementation VPBPaletteController

@synthesize ibPagePublishCheckbox=_ibPagePublishCheckbox;
@synthesize ibFrontPageCountField=_ibFrontPageCountField;
@synthesize ibWeblogBaseURL=_ibWeblogBaseURL;
@synthesize ibOutputFolder=_ibOutputFolder;

+ (NSViewController*)makeContentViewController {
    return [[[self alloc] initWithNibName:@"VPBPaletteController" bundle:[NSBundle bundleForClass:self]] autorelease];
}

- (void)dealloc {
    
    [_ibPagePublishCheckbox release];
    [super dealloc];
}


- (NSString*)displayName {
    return @"VPBlog";
}

- (NSURL*)defaultOutputFolderURL {
    
    NSDocument *doc = [[NSDocumentController sharedDocumentController] currentDocument];
    
    NSString *sitesFolder = [@"~/Sites/" stringByExpandingTildeInPath];
    
    if (doc) {
        
        NSString *name = [[doc fileURL] lastPathComponent];
        sitesFolder = [sitesFolder stringByAppendingPathComponent:[name stringByDeletingPathExtension]];
    }
    
    return [NSURL fileURLWithPath:sitesFolder];
    
}

- (void)documentDidChange {
    
    id doc = [[NSDocumentController sharedDocumentController] currentDocument];
    
    if (!doc) {
        #pragma message "FIXME: disable some of the controls, etc."
        return;
    }
    
    NSString *outputPath = [doc extraObjectForKey:@"vpblog.outputPath"];
    
    [_ibOutputFolder setEnabled:doc != nil];
    
    if (outputPath) {
        [_ibOutputFolder setURL:[NSURL fileURLWithPath:outputPath]];
    }
    else {
        [_ibOutputFolder setURL:[self defaultOutputFolderURL]];
    }
}

- (void)itemDidChange {
    
    id item = [self currentItem];
    
    NSString *updateText = NSLocalizedString(@"Publish", @"Publish");
    
    if (item) {
        updateText = [updateText stringByAppendingFormat:@" \"%@\"", [item displayName]];
    }
    
    [_ibPagePublishCheckbox setTitle:updateText];
    [_ibPagePublishCheckbox setEnabled:item != nil];
    
    
    NSString *pubState = [item metaValueForKey:@"vpblog.publish"];
    [_ibPagePublishCheckbox setState:[pubState boolValue]];
    
}

- (float)minimumWidth {
    return 320;
}

- (NSTextView*)currentTextView {
    
    id <VPPluginDocument>doc = [[NSDocumentController sharedDocumentController] currentDocument];
    id wc  = [(id)doc topWindowController];
    
    return [wc textView];
}

- (id<VPData>)currentItem {
    
    id <VPPluginDocument>doc = [[NSDocumentController sharedDocumentController] currentDocument];
    id wc  = [(id)doc topWindowController];
    
    id item = [wc item];
    
    return item;
}

- (void)togglePublishPageAction:(id)sender {
    
    id item = [self currentItem];
    
    if (!item) {
        [_ibPagePublishCheckbox setState:NSOffState];
        return;
    }
    
    NSString *publish = [_ibPagePublishCheckbox state] == NSOnState ? @"1" : @"0";
    
    [item setMetaValue:publish forKey:@"vpblog.publish"];
    
    [[item store] setAttributesForItem:item];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"VPItemMetaRefreshNotification" object:item];
    
}

- (IBAction)chooseOutputFolderAction:(id)sender {
    
    id <VPPluginDocument>doc = [[NSDocumentController sharedDocumentController] currentDocument];
    
    if (!doc) {
        return;
    }
    
    NSOpenPanel *op = [NSOpenPanel openPanel];
    
    [op setCanCreateDirectories:YES];
    [op setCanChooseDirectories:YES];
    [op setCanChooseFiles:NO];
    
    NSString *outputPath = [doc extraObjectForKey:@"vpblog.outputPath"];
    if (outputPath && [[NSFileManager defaultManager] fileExistsAtPath:outputPath]) {
        [op setDirectoryURL:[NSURL fileURLWithPath:outputPath]];
    }
    
    [op beginWithCompletionHandler:^(NSInteger result) {
        
        if (!result) {
            return;
        }
        
        NSURL *u = [op URL];
        
        #pragma message "FIXME: add some sandbox security scoped stuff here?"
        
        NSString *path = [u path];
        
        [doc setExtraObject:path forKey:@"vpblog.outputPath"];
        
        // lazy update
        [self documentDidChange];
    }];
}

- (IBAction)publishShortAction:(id)sender {
    
    VPBWriter *writer = [[[VPBWriter alloc] init] autorelease];
    
    [writer exportAndLimitToCount:10];
}

- (IBAction)publishAction:(id)sender {
    VPBWriter *writer = [[[VPBWriter alloc] init] autorelease];
    
    [writer exportAndLimitToCount:-1];
}

- (void)insertBlockquoteAction:(id)sender {
    
    NSTextView *tv = [self currentTextView];
    
    if (!tv) {
        return;
    }
    
    NSRange r = [tv selectedRange];
        
    if (r.length == 0) {
        
        [tv insertText:@"<blockquote><# #></blockquote>"];
        [tv setSelectedRange:r]; // move back so we grab the right placeholder.
        [tv selectNextTextPlaceholder:sender];
        return;
    }
    
    NSString *s = [[[tv textStorage] mutableString] substringWithRange:r];
    
    NSString *repace = [NSString stringWithFormat:@"<blockquote>%@</blockquote>", s];
    [tv insertText:repace];
}

- (void)pasteHREFAction:(id)sender {
    
    NSTextView *tv = [self currentTextView];
    
    if (!tv) {
        return;
    }
    
    NSRange r = [tv selectedRange];
    
    if (r.length == 0) {
        
        [tv insertText:@"<a href=\"<# Earl #>\"><# #></a>"];
        [tv setSelectedRange:r]; // move back so we grab the right placeholder.
        [tv selectNextTextPlaceholder:sender];
        return;
    }
    
    NSString *s = [[[tv textStorage] mutableString] substringWithRange:r];
    
    NSString *repace = [NSString stringWithFormat:@"<a href=\"<# Earl #>\">%@</a>", s];
    [tv insertText:repace];
    
    r.length = 0;
    [tv setSelectedRange:r]; // move back so we grab the right placeholder.
    [tv selectNextTextPlaceholder:sender];
}

- (id<VPData>)loadResourceAsPage:(NSString*)name uti:(NSString*)uti {
    
    NSString *extension = @"html";
    if ([uti isEqualToString:VPBPUTTypeJSTalkSource]) {
        extension = @"jstalk";
    }
    
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:name ofType:extension];
    
    NSError *err;
    NSString *script = [NSString stringWithContentsOfURL:[NSURL fileURLWithPath:path] encoding:NSUTF8StringEncoding error:&err];
    
    if (!script) {
        NSLog(@"error reading %@", path);
        NSLog(@"%@", err);
        return nil;
    }
    
    NSMutableDictionary *d = [NSMutableDictionary dictionary];
    [d setObject:name forKey:@"displayName"];
    [d setObject:uti forKey:@"uti"];
    [d setObject:[NSNumber numberWithBool:YES] forKey:@"skipOnExport"];
    
    [d setObject:[script dataUsingEncoding:NSUTF8StringEncoding] forKey:@"data"];
    
    id <VPPluginDocument>doc = [[NSDocumentController sharedDocumentController] currentDocument];
    id item = [(id)doc makeItemWithDefaultValues:d];
    
    return item;
}

- (void)initDocumentAction:(id)sender {
    
    id <VPPluginDocument>doc = [[NSDocumentController sharedDocumentController] currentDocument];
    
    if (![doc pageForKey:@"VPBlogExportScript"]) {
        id<VPData>item = [self loadResourceAsPage:@"VPBlogExportScript" uti:VPBPUTTypeJSTalkSource];
        [doc openPageWithTitle:[item displayName]];
    }
    
    if (![doc pageForKey:@"VPWebExportPageTemplate"]) {
        id<VPData>item = [self loadResourceAsPage:@"VPWebExportPageTemplate" uti:(id)kUTTypeUTF8PlainText];
        [doc openPageWithTitle:[item displayName]];
    }
    
    if (![doc pageForKey:@"VPBlogPageEntryTemplate"]) {
        id<VPData>item = [self loadResourceAsPage:@"VPBlogPageEntryTemplate" uti:(id)kUTTypeUTF8PlainText];
        [doc openPageWithTitle:[item displayName]];
    }
    
    [(id)doc setDefaultNewPageUTI:VPBPUTTypeMarkdownSource];
}

@end
