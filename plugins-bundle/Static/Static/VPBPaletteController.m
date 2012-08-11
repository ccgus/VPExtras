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
#import "VPBlogPlugin.h"

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
    [_ibOutputFolderLabel release];
    [_ibChooseOutputFolderButton release];
    
    [super dealloc];
}

- (NSString*)displayName {
    return @"Static";
}

- (NSURL*)defaultOutputFolderURL {
    
    NSDocument *doc = (id)[VPBlogPlugin currentDocument];
    
    NSString *sitesFolder = [@"~/Sites/" stringByExpandingTildeInPath];
    
    if (doc) {
        
        NSString *name = [[doc fileURL] lastPathComponent];
        sitesFolder = [sitesFolder stringByAppendingPathComponent:[name stringByDeletingPathExtension]];
    }
    
    return [NSURL fileURLWithPath:sitesFolder];
    
}

- (void)documentDidChange {
    
    id doc = [VPBlogPlugin currentDocument];
    
    [_ibPagePublishCheckbox setEnabled:doc != nil];
    [_ibChooseOutputFolderButton setEnabled:doc != nil];
    
    NSString *outputPath = [doc extraObjectForKey:@"vpstatic.outputPath"];
    
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
    
    
    NSString *pubState = [item metaValueForKey:@"vpstatic.publish"];
    [_ibPagePublishCheckbox setState:[pubState boolValue]];
    
}

- (float)minimumWidth {
    return 320;
}

- (NSTextView*)currentTextView {
    
    id <VPPluginWindowController>wc  = [[VPBlogPlugin currentDocument] mainWindowController];
    
    return [wc textView];
}

- (id<VPData>)currentItem {
    
    id <VPPluginWindowController>wc  = [[VPBlogPlugin currentDocument] mainWindowController];
    
    return [wc visibleItem];
}

- (void)togglePublishPageAction:(id)sender {
    
    id item = [self currentItem];
    
    if (!item) {
        [_ibPagePublishCheckbox setState:NSOffState];
        return;
    }
    
    NSString *publish = [_ibPagePublishCheckbox state] == NSOnState ? @"1" : @"0";
    
    [item setMetaValue:publish forKey:@"vpstatic.publish"];
    
    [[item store] setAttributesForItem:item];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"VPItemMetaRefreshNotification" object:item];
    
}

- (IBAction)chooseOutputFolderAction:(id)sender {
    
    id <VPPluginDocument>doc = [VPBlogPlugin currentDocument];
    
    if (!doc) {
        return;
    }
    
    NSOpenPanel *op = [NSOpenPanel openPanel];
    
    [op setCanCreateDirectories:YES];
    [op setCanChooseDirectories:YES];
    [op setCanChooseFiles:NO];
    
    NSString *outputPath = [doc extraObjectForKey:@"vpstatic.outputPath"];
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
        
        [doc setExtraObject:path forKey:@"vpstatic.outputPath"];
        
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
        
        [tv fmReplaceCharactersInRange:r withString:@"<blockquote><# #></blockquote>"];
        [tv setSelectedRange:r]; // move back so we grab the right placeholder.
        [tv selectNextTextPlaceholder:sender];
        return;
    }
    
    NSString *s = [[[tv textStorage] mutableString] substringWithRange:r];
    
    NSString *replace = [NSString stringWithFormat:@"<blockquote>%@</blockquote>", s];
    [tv fmReplaceCharactersInRange:r withString:replace];
}

- (void)pasteHREFAction:(id)sender {
    
    NSTextView *tv = [self currentTextView];
    
    if (!tv) {
        return;
    }
    
    NSRange r = [tv selectedRange];
    
    if (r.length == 0) {
        [tv fmReplaceCharactersInRange:r withString:@"[<# link text #>](<# Earl #>)"];
        [tv setSelectedRange:r]; // move back so we grab the right placeholder.
        [tv selectNextTextPlaceholder:sender];
        return;
    }
    
    NSString *s = [[[tv textStorage] mutableString] substringWithRange:r];
    
    NSString *replace = [NSString stringWithFormat:@"[%@](<# Earl #>)", s];
    [tv fmReplaceCharactersInRange:r withString:replace];
    
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
    
    id <VPPluginDocument>doc = [VPBlogPlugin currentDocument];
    id item = [(id)doc makeItemWithDefaultValues:d];
    
    return item;
}

- (void)initDocumentAction:(id)sender {
    
    if (![[VPBlogPlugin currentDocument] pageForKey:@"VPStaticExportScript"]) {
        [self loadResourceAsPage:@"VPStaticExportScript" uti:VPBPUTTypeJSTalkSource];
    }
    
    if (![[VPBlogPlugin currentDocument] pageForKey:@"VPWebExportPageTemplate"]) {
        [self loadResourceAsPage:@"VPWebExportPageTemplate" uti:(id)kUTTypeUTF8PlainText];
    }
    
    if (![[VPBlogPlugin currentDocument] pageForKey:@"VPStaticPageEntryTemplate"]) {
        [self loadResourceAsPage:@"VPStaticPageEntryTemplate" uti:(id)kUTTypeUTF8PlainText];
    }
    
    [(id)[VPBlogPlugin currentDocument] setDefaultNewPageUTI:VPBPUTTypeMarkdownSource];
    
    [self openHelpAction:sender];
}





- (IBAction)openHelpAction:(id)sender {
    
    if (![[VPBlogPlugin currentDocument] pageForKey:@"VPStaticHelp"]) {
        [self loadResourceAsPage:@"VPStaticHelp" uti:(id)kUTTypeFlatRTFD];
    }
    
    [[VPBlogPlugin currentDocument] openPageWithTitle:@"VPStaticHelp"];
}

- (IBAction)openSiteTemplateAction:(id)sender {
    
    [self initDocumentAction:nil];
    
    [[VPBlogPlugin currentDocument] openPageWithTitle:@"VPWebExportPageTemplate"];

}

- (IBAction)openEntryTemplateAction:(id)sender {
    
    [self initDocumentAction:nil];
    
    [[VPBlogPlugin currentDocument] openPageWithTitle:@"VPStaticPageEntryTemplate"];
}

- (IBAction)openEventScriptAction:(id)sender {
    
    [self initDocumentAction:nil];
    
    [[VPBlogPlugin currentDocument] openPageWithTitle:@"VPStaticExportScript"];
}

@end
