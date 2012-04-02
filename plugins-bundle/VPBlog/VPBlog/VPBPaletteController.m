//
//  VPBPaletteController.m
//  VPBlog
//
//  Created by August Mueller on 4/2/12.
//  Copyright (c) 2012 Flying Meat. All rights reserved.
//

#import "VPBPaletteController.h"

@interface VPBPaletteController ()

@end

@implementation VPBPaletteController


+ (void)addContentViewControllersToPaletteController:(VPUPaletteController*)paletteController {
    debug(@"%s:%d", __FUNCTION__, __LINE__);
    VPBPaletteController *meme = [[[self alloc] initWithNibName:@"VPBPaletteController" bundle:nil] autorelease];
    [paletteController addPaletteViewController:(id)meme];

}

+ (NSString*)displayName {
    return @"VPBlog";
}

- (NSImage*)pickerImage {
    return nil;
}

- (id<VPPluginDocument>)currentDocument {
    return nil;
}

- (id<VPPluginWindowController>)currentWindowController {
    return nil;
}

- (id<VPData>)currentItem {
    return nil;
}

- (void)documentDidChange {
    
}

- (void)itemDidChange {
    
}

- (float)minimumWidth {
    return 320;
}


+ (NSString*)menuKeyEquivalent {
    return @"";
}

+ (int)menuKeyEquivalentModifierMask {
    return 0;
}


@end
