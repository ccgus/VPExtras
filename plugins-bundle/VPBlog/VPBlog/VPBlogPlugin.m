//
//  VPBlogPlugin.m
//  VPBlog
//
//  Created by August Mueller on 4/2/12.
//  Copyright (c) 2012 Flying Meat. All rights reserved.
//

#import "VPBlogPlugin.h"
#import "VPBPaletteController.h"

@interface NSObject (VPPluginManagerCurrentlyPrivate)

- (void)registerPaletteViewController:(Class)pvc;

@end

@implementation VPBlogPlugin

- (void)didRegister {
    [(id)[self pluginManager] registerPaletteViewController:[VPBPaletteController class]];
}

@end
