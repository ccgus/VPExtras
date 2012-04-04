//
//  VPBPaletteController.h
//  VPBlog
//
//  Created by August Mueller on 4/2/12.
//  Copyright (c) 2012 Flying Meat. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <VPPlugin/VPPlugin.h>

@interface VPBPaletteController : NSViewController {

}

@property (strong) IBOutlet NSButton *ibPagePublishCheckbox;
@property (strong) IBOutlet NSTextField *ibFrontPageCountField;
@property (strong) IBOutlet NSTextField *ibWeblogBaseURL;
@property (strong) IBOutlet NSPathControl *ibOutputFolder;

- (IBAction)togglePublishPageAction:(id)sender;
- (IBAction)chooseOutputFolderAction:(id)sender;
- (IBAction)publishShortAction:(id)sender;
- (IBAction)publishAction:(id)sender;

@end
