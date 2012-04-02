/*
Copyright (c) 2004, Flying Meat Inc.
All rights reserved. 
*/

#import <Foundation/Foundation.h>
#import <VPPlugin/VPPlugin.h>

@interface VPExporter : VPPlugin <VPPluginActivity> {
    BOOL _shouldCancel;
}

@property (assign) BOOL shouldCancel;

- (void)selectDirectoryToExport:(id<VPPluginWindowController>)windowController;
- (void)doExportWithInfo:(NSDictionary*)d;

@end
