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
@synthesize ibOutputFolderLabel=_ibOutputFolderLabel;
@synthesize ibChooseOutputFolderButton=_ibChooseOutputFolderButton;

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
    
    NSDocument *doc = (id)[self currentDocument];
    
    NSString *sitesFolder = [@"~/Sites/" stringByExpandingTildeInPath];
    
    if (doc) {
        
        NSString *name = [[doc fileURL] lastPathComponent];
        sitesFolder = [sitesFolder stringByAppendingPathComponent:[name stringByDeletingPathExtension]];
    }
    
    return [NSURL fileURLWithPath:sitesFolder];
    
}

- (void)documentDidChange {
    
    id doc = [self currentDocument];
    
    [_ibPagePublishCheckbox setEnabled:doc != nil];
    [_ibChooseOutputFolderButton setEnabled:doc != nil];
    
    NSString *outputPath = [doc extraObjectForKey:@"vpblog.outputPath"];
    
    if (outputPath) {
        
        outputPath = [outputPath stringByAbbreviatingWithTildeInPath];
    
        [_ibOutputFolderLabel setStringValue:outputPath];
    }
    else {
        [_ibOutputFolderLabel setStringValue:@""];
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

- (id <VPPluginDocument>)currentDocument {
    id <VPPluginDocument>doc = [[NSDocumentController sharedDocumentController] currentDocument];
    
    if (!doc && [[[NSDocumentController sharedDocumentController] documents] count]) {
        // wtf, appkit is holding out on us.
        doc = [[[NSDocumentController sharedDocumentController] documents] objectAtIndex:0];
        
        // sanity check.
        if (![(id)doc respondsToSelector:@selector(orderedPageKeysByCreateDate)]) {
            doc = nil;
        }
    }
    
    return doc;
    
}

- (NSTextView*)currentTextView {
    
    
    id wc  = [(id)[self currentDocument] topWindowController];
    
    return [wc textView];
}

- (id<VPData>)currentItem {
    
    id wc  = [(id)[self currentDocument] topWindowController];
    
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
    
    id <VPPluginDocument>doc = [self currentDocument];
    
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
    else if ([uti isEqualToString:(id)kUTTypeFlatRTFD]) {
        extension = @"rtfd";
    }
    
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:name ofType:extension];
    
    NSData *pageData = nil;
    
    if ([uti isEqualToString:(id)kUTTypeFlatRTFD]) {
        NSAttributedString *as = [[NSAttributedString alloc] initWithPath:path documentAttributes:nil];
        pageData = [as RTFDFromRange:NSMakeRange(0, [as length]) documentAttributes:nil];
    }
    else {
        
        NSError *err;
        NSString *script = [NSString stringWithContentsOfURL:[NSURL fileURLWithPath:path] encoding:NSUTF8StringEncoding error:&err];
        
        if (!script) {
            NSLog(@"error reading %@", path);
            NSLog(@"%@", err);
            return nil;
        }
        
        pageData = [script dataUsingEncoding:NSUTF8StringEncoding];
    }
    
    
    NSMutableDictionary *d = [NSMutableDictionary dictionary];
    [d setObject:name forKey:@"displayName"];
    [d setObject:uti forKey:@"uti"];
    [d setObject:[NSNumber numberWithBool:YES] forKey:@"skipOnExport"];
    
    [d setObject:pageData forKey:@"data"];
    
    id <VPPluginDocument>doc = [self currentDocument];
    id item = [(id)doc makeItemWithDefaultValues:d];
    
    return item;
}

- (void)initDocumentAction:(id)sender {
    
    if (![[self currentDocument] pageForKey:@"VPBlogExportScript"]) {
        [self loadResourceAsPage:@"VPBlogExportScript" uti:VPBPUTTypeJSTalkSource];
    }
    
    if (![[self currentDocument] pageForKey:@"VPWebExportPageTemplate"]) {
        [self loadResourceAsPage:@"VPWebExportPageTemplate" uti:(id)kUTTypeUTF8PlainText];
    }
    
    if (![[self currentDocument] pageForKey:@"VPBlogPageEntryTemplate"]) {
        [self loadResourceAsPage:@"VPBlogPageEntryTemplate" uti:(id)kUTTypeUTF8PlainText];
    }
    
    [(id)[self currentDocument] setDefaultNewPageUTI:VPBPUTTypeMarkdownSource];
}

- (IBAction)openHelpAction:(id)sender {
    
    if (![[self currentDocument] pageForKey:@"VPBlogHelp"]) {
        [self loadResourceAsPage:@"VPBlogHelp" uti:(id)kUTTypeFlatRTFD];
    }
    
    [[self currentDocument] openPageWithTitle:@"VPBlogHelp"];
}

- (IBAction)openSiteTemplateAction:(id)sender {
    
    [self initDocumentAction:nil];
    
    [[self currentDocument] openPageWithTitle:@"VPWebExportPageTemplate"];

}

- (IBAction)openEntryTemplateAction:(id)sender {
    
    [self initDocumentAction:nil];
    
    [[self currentDocument] openPageWithTitle:@"VPBlogPageEntryTemplate"];
}

- (IBAction)openEventScriptAction:(id)sender {
    
    [self initDocumentAction:nil];
    
    [[self currentDocument] openPageWithTitle:@"VPBlogExportScript"];
}

@end
