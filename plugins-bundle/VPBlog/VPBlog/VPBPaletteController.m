//
//  VPBPaletteController.m
//  VPBlog
//
//  Created by August Mueller on 4/2/12.
//  Copyright (c) 2012 Flying Meat. All rights reserved.
//

#import "VPBPaletteController.h"
#import "JSTalk.h"

extern NSString *VPBPUTTypeMarkdownSource = @"net.daringfireball.markdown";


@interface NSObject (ThingsINeedToOpenUpInVPOrMakeBetter)
- (id)topWindowController;
- (void)setMetaValue:(NSString*)value forKey:(NSString*)aKey;
- (id)store;
- (void)setAttributesForItem:(id)item;

- (id)webExportController;
- (void)resetCache;
- (void)resetAction:(id)sender;
- (NSDictionary*)renderItem:(id<VPData>)item options:(NSDictionary*)options;

- (JSTalk*)jstalk;

@end

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
    
    
    
    debug(@"%s:%d", __FUNCTION__, __LINE__);
}

- (IBAction)publishShortAction:(id)sender {
    [self exportAndLimitToCount:10];
}

- (IBAction)publishAction:(id)sender {
    [self exportAndLimitToCount:-1];
}

- (void)exportAndLimitToCount:(NSInteger)postCount {
    id <VPPluginDocument>doc = [[NSDocumentController sharedDocumentController] currentDocument];
    
    
    if (!doc) {
        return;
    }
    
    NSString *outputPath = [doc extraObjectForKey:@"vpblog.outputPath"];
    if (!outputPath) {
        NSLog(@"No output folder set, or it doesn't exist");
        return;
    }
    
    NSURL *baseOutputURL = [NSURL fileURLWithPath:outputPath];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:outputPath]) {
        NSError *err = nil;
        if (![[NSFileManager defaultManager] createDirectoryAtURL:baseOutputURL withIntermediateDirectories:YES attributes:nil error:&err]) {
            NSBeep();
            NSLog(@"Could not make the directory %@", outputPath);
            NSLog(@"%@", err);
            return;
        }
    }
    
    JSTalk *jstalk = nil;
    NSMutableDictionary *exportContext = [NSMutableDictionary dictionary];
    
    id <VPData>scriptPage = [doc pageForKey:@"vpblogexportscript"];
    
    if (scriptPage) {
        jstalk = [(id)doc jstalk];
        [jstalk executeString:[scriptPage stringData]];
    }
    
    
    if (jstalk && [[jstalk jsController] hasFunction:@"blogExportWillBegin"]) {
        [jstalk callFunctionNamed:@"blogExportWillBegin" withArguments:[NSArray arrayWithObjects:doc, exportContext, nil]];
    }
    
    
    
    NSMutableString *indexPage = [NSMutableString string];
    
    id webExportController = [(id)doc webExportController];
    NSArray *orderedByDate = [doc orderedPageKeysByCreateDate];
    
    for (NSString *key in [orderedByDate reverseObjectEnumerator]) {
        
        id <VPData>item = [doc pageForKey:key];
        
        if (![item isText]) {
            continue;
        }
        
        BOOL shouldPublish = [[item metaValueForKey:@"vpblog.publish"] boolValue];
        if (!shouldPublish) {
            continue;
        }
        
        
        int formatForPage = 1; // VPPlainTextWebExportFormat
        
        if (UTTypeConformsTo((CFStringRef)[item uti], (CFStringRef)VPBPUTTypeMarkdownSource)) {
            debug(@"yay, markdown!");
            formatForPage = 2;
        }
        else if (UTTypeConformsTo((CFStringRef)[item uti], kUTTypeUTF8PlainText)) {
            debug(@"plain text!");
        }
        
        #pragma message "FIXME: add imagesOutputPath to this somehow"
        
        NSDictionary *renderOptions = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:formatForPage], @"formatTag", nil];
        
        NSDictionary *d = [webExportController renderItem:item options:renderOptions];
        NSString *output = [d objectForKey:@"output"];
        NSString *unwrappedOutput = [d objectForKey:@"unwrappedOutput"];
        
        if (jstalk && [[jstalk jsController] hasFunction:@"blogExportWillAppendItemToFrontPage"]) {
            [jstalk callFunctionNamed:@"blogExportWillAppendItemToFrontPage" withArguments:[NSArray arrayWithObjects:doc, item, indexPage, exportContext, nil]];
        }
        
        [indexPage appendString:unwrappedOutput];
        
        if (jstalk && [[jstalk jsController] hasFunction:@"blogExportDidAppendItemToFrontPage"]) {
            [jstalk callFunctionNamed:@"blogExportDidAppendItemToFrontPage" withArguments:[NSArray arrayWithObjects:doc, item, indexPage, exportContext, nil]];
        }
        
        
        
        //debug(@"unwrappedOutput: %@", unwrappedOutput);
        
        NSData *data = [output dataUsingEncoding:NSUTF8StringEncoding];
        
        NSURL *outURL = [baseOutputURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.html", [item key]]];
        
        
        if (jstalk && [[jstalk jsController] hasFunction:@"blogExportExtendedPathForItem"]) {
            
            NSString *suggestedPath = [outURL path];
            NSString *newPath = [jstalk callFunctionNamed:@"blogExportExtendedPathForItem" withArguments:[NSArray arrayWithObjects:doc, item, suggestedPath, exportContext, nil]];
            
            if (newPath) {
                
                NSString *parentDir = [newPath stringByDeletingLastPathComponent];
                
                NSError *err = nil;
                if (![[NSFileManager defaultManager] createDirectoryAtURL:[NSURL fileURLWithPath:parentDir] withIntermediateDirectories:YES attributes:nil error:&err]) {
                    NSBeep();
                    NSLog(@"Could not make the directory %@", parentDir);
                    NSLog(@"%@", err);
                    return;
                }
                
                outURL = [NSURL fileURLWithPath:newPath];
            }
        }
        
        NSError *writeError = nil;
        if (![data writeToURL:outURL options:NSDataWritingAtomic error:&writeError]) {
            NSLog(@"Could not write to %@", outURL);
            NSLog(@"%@", writeError);
        }
        
    }
    
    NSData *indexPageData = [indexPage dataUsingEncoding:NSUTF8StringEncoding];
    NSURL *outURL         = [baseOutputURL URLByAppendingPathComponent:@"index.html"];
    
    NSError *writeError = nil;
    if (![indexPageData writeToURL:outURL options:NSDataWritingAtomic error:&writeError]) {
        NSLog(@"Could not write to %@", outURL);
        NSLog(@"%@", writeError);
    }
    
    
    if (jstalk && [[jstalk jsController] hasFunction:@"blogExportDidEnd"]) {
        [jstalk callFunctionNamed:@"blogExportDidEnd" withArguments:[NSArray arrayWithObjects:doc, exportContext, nil]];
    }
}

@end
