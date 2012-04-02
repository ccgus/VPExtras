//
//  VPBlogPlugin.m
//  VPBlog
//
//  Created by August Mueller on 4/2/12.
//  Copyright (c) 2012 Flying Meat. All rights reserved.
//

#import "VPBlogPlugin.h"
#import "VPBPaletteController.h"

@implementation VPBlogPlugin

+ (void)load {
    id class = NSClassFromString(@"VPUPaletteController");
    [class registerContentViewControllerClass:[VPBPaletteController class]];
}

@end
