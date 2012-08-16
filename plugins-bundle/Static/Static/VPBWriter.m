//
//  VPBWriter.m
//  VPBlog
//
//  Created by August Mueller on 4/5/12.
//  Copyright (c) 2012 Flying Meat. All rights reserved.
//

#import "VPBWriter.h"
#import "VPPrivateStuff.h"


@interface VPBWriter ()
@property (strong) NSMutableString *rssFeed;
@property (strong) NSMutableString *indexPage;
@property (strong) NSMutableDictionary *staticSetup;
@property (strong) NSString *currentArchiveMonth;
@end

@implementation VPBWriter

@synthesize rssFeed=_rssFeed;
@synthesize indexPage=_indexPage;
@synthesize staticSetup=_staticSetup;
@synthesize currentArchiveMonth=_currentArchiveMonth;

- (id)init
{
    self = [super init];
    if (self) {
        [self setRssFeed:[NSMutableString string]];
        [self setIndexPage:[NSMutableString string]];
        [self setStaticSetup:[NSMutableDictionary dictionary]];
        
        [_staticSetup setObject:@"" forKey:@"siteName"];
        [_staticSetup setObject:@"" forKey:@"copyright"];
        [_staticSetup setObject:@"10" forKey:@"frontPageCount"];
        [_staticSetup setObject:@"siteURL" forKey:@"http://example.com/wherever/"];
        
    }
    return self;
}

- (void)dealloc {
    [_rssFeed release];
    [_indexPage release];
    [_staticSetup release];
    [_currentArchiveMonth release];
    
    [super dealloc];
}



- (NSString*)escapeArchivePageName:(NSString*)name {
    
    NSArray *replaceChars = [NSArray arrayWithObjects:@" ", @"/", @"\\", @"\"", @",", @"'", @"?", @"[", @"]", @"&", @"%", nil];
    
    for (NSString *r in replaceChars) {
        name = [name stringByReplacingOccurrencesOfString:r withString:@"_"];
    }
    
    return name;
}


- (NSString*)askForArchivePathForItem:(id<VPData>)item fileName:(NSString*)fn document:(id<VPPluginDocument>)doc baseOutputURL:(NSURL*)baseOutputURL context:(NSMutableDictionary*)exportContext jstalk:(JSTalk*)jstalk isAsset:(BOOL)isAsset {
    
    NSString *functionName = isAsset ? @"staticExportArchivePathForAssetItem" : @"staticExportArchivePathForItem";
    
    if ([jstalk hasFunctionNamed:functionName]) {
        
        NSString *newPath = [jstalk callFunctionNamed:functionName withArguments:[NSArray arrayWithObjects:doc, item, fn, _staticSetup, nil]];
        
        if (newPath) {
            
            NSURL *parentDir = [baseOutputURL URLByAppendingPathComponent:[newPath stringByDeletingLastPathComponent]];
            
            NSError *err = nil;
            if (![[NSFileManager defaultManager] createDirectoryAtURL:parentDir withIntermediateDirectories:YES attributes:nil error:&err]) {
                NSBeep();
                NSLog(@"Could not make the directory %@", parentDir);
                NSLog(@"%@", err);
                return fn;
            }
            
            return newPath;
        }
    }
    
    return fn;
    
}

- (void)appendItem:(id<VPData>)item toArchiveString:(NSMutableString*)archive usingRelativePath:(NSString*)outRelativePath {
    
    NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
    [formatter setDateFormat:@"MMMM yyyy"];
    
    NSString *thisGuysMonth = [formatter stringFromDate:[item createdDate]]; 
    
    if (![thisGuysMonth isEqualToString:_currentArchiveMonth]) {
    
        if (_currentArchiveMonth) {
            [archive appendString:@"</div>\n"];
        }
    
        [self setCurrentArchiveMonth:thisGuysMonth];
        [archive appendFormat:@"<div class=\"archiveMonthEntry\"><p class=\"archiveMonthHeader\">%@</p>\n", _currentArchiveMonth];
    }
    
    [archive appendFormat:@"<p class=\"archiveEntry\"><a href=\"%@\">%@</a></p>\n", outRelativePath, [self escapeForXML:[item displayName]]];
}

- (void)exportAndLimitToCount:(NSInteger)postCount {
    
    id <VPPluginDocument>doc = [[NSDocumentController sharedDocumentController] currentDocument];
    
    if (!doc) {
        return;
    }
    
    NSData *outputBookmark = [doc extraObjectForKey:@"vpstatic.outputURLBookmark"];
    
    NSError *err;
    BOOL dataIsStale = NO;
    NSURL *baseOutputURL = [NSURL URLByResolvingBookmarkData:outputBookmark options:0 relativeToURL:[(NSDocument*)doc fileURL] bookmarkDataIsStale:&dataIsStale error:&err];
    
    if (!baseOutputURL) {
        NSLog(@"No output folder set, or it doesn't exist");
        
        NSAlert *alert = [NSAlert alertWithMessageText:@"No publish folder set" defaultButton:nil alternateButton:nil otherButton:nil informativeTextWithFormat:@"Make sure to select a folder to publish to."];
        
        [alert runModal];
        
        return;
    }
    
    [baseOutputURL startAccessingSecurityScopedResource];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:[baseOutputURL path]]) {
        NSError *err = nil;
        if (![[NSFileManager defaultManager] createDirectoryAtURL:baseOutputURL withIntermediateDirectories:YES attributes:nil error:&err]) {
            NSBeep();
            NSLog(@"Could not make the directory %@", baseOutputURL);
            NSLog(@"%@", err);
            [baseOutputURL stopAccessingSecurityScopedResource];
            return;
        }
    }
    
    JSTalk *jstalk = [(id)doc jstalk];
    NSMutableDictionary *exportContext = [NSMutableDictionary dictionary];
    
    [_staticSetup setObject:[baseOutputURL path] forKey:@"outputFolderPath"];
    
    [jstalk pushObject:_staticSetup withName:@"staticSetup"];
    
    id <VPData>scriptPage = [doc pageForKey:@"vpstaticexportscript"];
    
    if (scriptPage) {
        [jstalk executeString:[scriptPage stringData]];
    }
    
    if ([jstalk hasFunctionNamed:@"staticSetupConfiguration"]) {
        [jstalk callFunctionNamed:@"staticSetupConfiguration" withArguments:[NSArray arrayWithObjects:doc, _staticSetup, nil]];
    }
    
    if ([jstalk hasFunctionNamed:@"staticExportWillBegin"]) {
        [jstalk callFunctionNamed:@"staticExportWillBegin" withArguments:[NSArray arrayWithObjects:doc, _staticSetup, nil]];
    }
    
    NSString *entryPageTemplate = [[doc pageForKey:@"VPStaticPageEntryTemplate"] stringData];
    if (!entryPageTemplate) {
        entryPageTemplate = @"<%= pageContext.pageEntry %>";
    }
    
    
    NSString *rssEntryTemplate = [[doc pageForKey:@"VPStaticRSSEntryTemplate"] stringData];
    if (!rssEntryTemplate) {
        rssEntryTemplate = @"<%= pageContext.pageEntry %>";
    }
    
    NSString *pageTemplate = [[doc pageForKey:@"VPWebExportPageTemplate"] stringData];
    if (!pageTemplate) {
        pageTemplate = @"$page$";
    }
    
    [self makeRSSHeader];
    
    NSInteger currentPageCount = 0;
    NSInteger maxPageCount     = [[_staticSetup objectForKey:@"frontPageCount"] integerValue];
    
    NSMutableArray *linkedAssetsToWriteOut = [NSMutableArray array];
    NSMutableString *archivePage = [NSMutableString string];
    
    id webExportController = [(id)doc webExportController];
    NSArray *orderedByDate = [doc orderedPageKeysByCreateDate];
    
    for (NSString *key in [orderedByDate reverseObjectEnumerator]) {
        
        @autoreleasepool {
            
            id <VPData>item = [doc pageForKey:key];
            
            if (![item isText]) {
                continue;
            }
            
            BOOL shouldPublish = [[item metaValueForKey:@"vpstatic.publish"] boolValue];
            if (!shouldPublish) {
                continue;
            }
            
            // let's find out where they want us to write the file:
            
            NSString *archiveFileName = [self escapeArchivePageName:[[item key] stringByAppendingPathExtension:@"html"]];
            NSString *outRelativePath = [self askForArchivePathForItem:item fileName:archiveFileName document:doc baseOutputURL:baseOutputURL context:exportContext jstalk:jstalk isAsset:NO];
            NSURL *outURL             = [baseOutputURL URLByAppendingPathComponent:outRelativePath];
            
            [self appendItem:item toArchiveString:archivePage usingRelativePath:outRelativePath];
            
            
            if (currentPageCount >= maxPageCount) {
                continue;
            }
            
            currentPageCount++;
            
            NSDictionary *renderOptions = [NSDictionary dictionaryWithObjectsAndKeys:jstalk, @"jstalk", [NSNumber numberWithBool:YES], @"ignoreTemplateWrapping", nil];
            
            NSDictionary *d = [webExportController renderItem:item options:renderOptions];
            NSString *unwrappedOutput = [d objectForKey:@"output"];
            NSArray *linkedKeys = [d objectForKey:@"linkedItemKeys"];
            
            if ([jstalk hasFunctionNamed:@"staticExportWillAppendItemToFrontPage"]) {
                [jstalk callFunctionNamed:@"staticExportWillAppendItemToFrontPage" withArguments:[NSArray arrayWithObjects:doc, item, _indexPage, _staticSetup, nil]];
            }
            
            [exportContext setObject:outRelativePath forKey:@"pageArchivePath"];
            [exportContext setObject:unwrappedOutput forKey:@"pageEntry"];
            
            NSDictionary *args  = [NSDictionary dictionaryWithObjectsAndKeys:doc, @"document", item, @"page", exportContext, @"pageContext", _staticSetup, @"staticSetup", nil];
            NSString *entry     = [(id)doc renderScriptletsInHTMLString:entryPageTemplate withJSTalk:jstalk usingVariables:args];
            NSString *rssentry  = [(id)doc renderScriptletsInHTMLString:rssEntryTemplate withJSTalk:jstalk usingVariables:args];
            
            NSString *archivePage = [pageTemplate stringByReplacingOccurrencesOfString:@"$page$" withString:entry];
            archivePage           = [(id)doc renderScriptletsInHTMLString:archivePage withJSTalk:jstalk usingVariables:args];
            
            
            [_indexPage appendString:entry];
            
            //debug(@"entry: %@", entry);
            [self appendRSSEntry:rssentry archiveURL:outRelativePath toItem:item];
            
            if ([jstalk hasFunctionNamed:@"staticExportDidAppendItemToFrontPage"]) {
                [jstalk callFunctionNamed:@"staticExportDidAppendItemToFrontPage" withArguments:[NSArray arrayWithObjects:doc, item, _indexPage, _staticSetup, nil]];
            }
            
            NSData *data = [archivePage dataUsingEncoding:NSUTF8StringEncoding];
            
            NSError *writeError = nil;
            if (![data writeToURL:outURL options:NSDataWritingAtomic error:&writeError]) {
                NSLog(@"Could not write to %@", outURL);
                NSLog(@"%@", writeError);
            }
            
            
            
            for (NSString *linkedKey in linkedKeys) {
                
                if ([linkedAssetsToWriteOut indexOfObject:linkedKey] == NSNotFound) {
                    [linkedAssetsToWriteOut addObject:linkedKey];
                }
            }
        }
    }
    
    [self appendRSSFooter];
    
    NSURL *rssOutURL    = [baseOutputURL URLByAppendingPathComponent:@"rss.xml"];
    NSError *writeError = nil;
    
    if (![[_rssFeed dataUsingEncoding:NSUTF8StringEncoding] writeToURL:rssOutURL options:NSDataWritingAtomic error:&writeError]) {
        NSLog(@"Could not write to %@", rssOutURL);
        NSLog(@"%@", writeError);
    }
    
    [jstalk deleteObjectWithName:@"page"];
    
    // write the index page!
    {
        NSString *rIndexPage   = [pageTemplate stringByReplacingOccurrencesOfString:@"$page$" withString:_indexPage];
        NSDictionary *args  = [NSDictionary dictionaryWithObjectsAndKeys:doc, @"document", exportContext, @"pageContext", _staticSetup, @"staticSetup", nil];
        rIndexPage = [(id)doc renderScriptletsInHTMLString:rIndexPage withJSTalk:jstalk usingVariables:args];
        
        NSData *indexPageData = [rIndexPage dataUsingEncoding:NSUTF8StringEncoding];
        NSURL *outURL         = [baseOutputURL URLByAppendingPathComponent:@"index.html"];
        
        if (![indexPageData writeToURL:outURL options:NSDataWritingAtomic error:&writeError]) {
            NSLog(@"Could not write to %@", outURL);
            NSLog(@"%@", writeError);
        }
    }
    
    
    
    // write the archive page!
    {
        // close the opening div we've got going on.
        [archivePage appendString:@"</div>\n"];
        
        NSString *rArchivePage   = [pageTemplate stringByReplacingOccurrencesOfString:@"$page$" withString:archivePage];
        NSDictionary *args  = [NSDictionary dictionaryWithObjectsAndKeys:doc, @"document", exportContext, @"pageContext", _staticSetup, @"staticSetup", nil];
        rArchivePage = [(id)doc renderScriptletsInHTMLString:rArchivePage withJSTalk:jstalk usingVariables:args];

        NSData *archivePageData = [rArchivePage dataUsingEncoding:NSUTF8StringEncoding];
        NSURL *archiveOutURL    = [baseOutputURL URLByAppendingPathComponent:@"archive.html"];
        
        if (![archivePageData writeToURL:archiveOutURL options:NSDataWritingAtomic error:&writeError]) {
            NSLog(@"Could not write to %@", archiveOutURL);
            NSLog(@"%@", writeError);
        }
    }
    
    
    for (NSString *assetKey in linkedAssetsToWriteOut) @autoreleasepool {
        
        id <VPData>item = [doc pageForKey:assetKey];
        
        CFStringRef itemUTI = (CFStringRef)[item uti];
        if (!itemUTI) {
            continue;
        }
        
        if (UTTypeConformsTo(itemUTI, kUTTypeImage) || UTTypeConformsTo(itemUTI, kUTTypeMovie) || UTTypeConformsTo(itemUTI, kUTTypeAudio)) {
            
            NSString *outRelativePath = [self askForArchivePathForItem:item fileName:[item key] document:doc baseOutputURL:baseOutputURL context:exportContext jstalk:jstalk isAsset:YES];
            
            debug(@"outRelativePath '%@'", outRelativePath);
            
            NSURL *outURL = [baseOutputURL URLByAppendingPathComponent:outRelativePath];
            if (![[item data] writeToURL:outURL options:NSDataWritingAtomic error:&writeError]) {
                NSLog(@"Could not write to %@", outURL);
                NSLog(@"%@", writeError);
            }
        }
    }
    
    
    if ([jstalk hasFunctionNamed:@"staticSupportPages"]) {
        NSArray *supportPagesList = [jstalk callFunctionNamed:@"staticSupportPages" withArguments:[NSArray arrayWithObjects:doc, _staticSetup, nil]];
        
        for (NSString *key in supportPagesList) @autoreleasepool {
            key = [key vpkey];
            
            
            debug(@"key '%@'", key);
            
            id <VPData>item = [doc pageForKey:key];
            
            if (!item) {
                NSLog(@"The key support page '%@' does not exist in this document.", key);
                continue;
            }
            
            NSData *outData = nil;
            NSString *fileName = nil;
            
            if (![item isText]) {
                outData = [item data];
                fileName = key;
            }
            else {
                
                NSDictionary *renderOptions = [NSDictionary dictionaryWithObjectsAndKeys:jstalk, @"jstalk", [NSNumber numberWithBool:YES], @"ignoreTemplateWrapping", nil];
                
                NSDictionary *d = [webExportController renderItem:item options:renderOptions];
                NSString *unwrappedOutput = [d objectForKey:@"output"];

                NSString *outPage    = [pageTemplate stringByReplacingOccurrencesOfString:@"$page$" withString:unwrappedOutput];
                NSDictionary *args   = [NSDictionary dictionaryWithObjectsAndKeys:doc, @"document", exportContext, @"pageContext", _staticSetup, @"staticSetup", nil];
                outPage = [(id)doc renderScriptletsInHTMLString:outPage withJSTalk:jstalk usingVariables:args];
                
                outData  = [outPage dataUsingEncoding:NSUTF8StringEncoding];
                fileName = [key stringByAppendingPathExtension:@"html"];
            }
            
            if (outData) {
                NSURL *outURL = [baseOutputURL URLByAppendingPathComponent:fileName];
                if (![outData writeToURL:outURL options:NSDataWritingAtomic error:&writeError]) {
                    NSLog(@"Could not write to %@", outURL);
                    NSLog(@"%@", writeError);
                }
            }
            else {
                debug(@"No outData for %@", key);
            }
            
        }
        
        
        
        
    }
    
    
    if ([jstalk hasFunctionNamed:@"staticExportDidEnd"]) {
        [jstalk callFunctionNamed:@"staticExportDidEnd" withArguments:[NSArray arrayWithObjects:doc, _staticSetup, nil]];
    }
    
    if ([[_staticSetup objectForKey:@"viewLocalWhenFinished"] boolValue]) {
        [[NSWorkspace sharedWorkspace] openURL:[baseOutputURL URLByAppendingPathComponent:@"index.html"]];
    }
    
    [baseOutputURL stopAccessingSecurityScopedResource];
}

- (NSString*)rssDateFromNSDate:(NSDate*)date {
    
    NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
    [formatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss Z"];
    
    return [formatter stringFromDate:date];
}

- (NSString*)escapeForXML:(NSString*)s {
    s = [s stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"];
    s = [s stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"];
    s = [s stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"];
    
    return s;
}

- (void)makeRSSHeader {
    
    NSString *siteName = [self escapeForXML:[_staticSetup objectForKey:@"siteName"]];
    NSString *siteURL  = [self escapeForXML:[_staticSetup objectForKey:@"siteURL"]];
    NSString *siteDesc = [self escapeForXML:[_staticSetup objectForKey:@"rssSiteDescription"]];
    NSString *pubDate  = [self rssDateFromNSDate:[NSDate date]];
    
    
    [_rssFeed appendFormat:@""
            "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
            "<rss version=\"2.0\"\n"
            "  xmlns:content=\"http://purl.org/rss/1.0/modules/content/\"\n"
            "  xmlns:dc=\"http://purl.org/dc/elements/1.1/\">\n"
            "  <channel>\n"
            "    <title>%@</title>\n"
            "    <link>%@</link>\n"
            "    <pubDate>%@</pubDate>\n"
            "    <description>%@</description>\n", siteName, siteURL, pubDate, siteDesc];
}

- (void)appendRSSEntry:(NSString*)entry archiveURL:(NSString*)archiveURL toItem:(id<VPData>)item {
    
    NSString *title = [self escapeForXML:[item displayName]];
    NSString *siteURL  = [self escapeForXML:[_staticSetup objectForKey:@"siteURL"]];
    NSString *link = [siteURL stringByAppendingString:archiveURL];
    
    NSString *pubDate = [self rssDateFromNSDate:[item createdDate]];
    
    entry = [self escapeForXML:entry];
    
    [_rssFeed appendFormat:@""
     "  <item>\n"
     "    <title>%@</title>\n"
     "    <link>%@</link>\n" 
     "    <description>%@</description>\n"
     "    <guid>%@</guid>\n"
     "    <pubDate>%@</pubDate>\n"
     "  </item>\n", title, link, entry, link, pubDate];
}

- (void)appendRSSFooter {
    [_rssFeed appendString:@"  </channel>\n</rss>"];
}


@end
