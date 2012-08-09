//
//  VPBlogPlugin.h
//  VPBlog
//
//  Created by August Mueller on 4/2/12.
//  Copyright (c) 2012 Flying Meat. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <VPPlugin/VPPlugin.h>

@interface VPBlogPlugin : VPPlugin {
    NSMutableArray *_observers;
}

+ (id <VPPluginDocument>)currentDocument;

@end

