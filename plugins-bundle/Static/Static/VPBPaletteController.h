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
@property (strong) IBOutlet NSTextField *ibOutputFolderLabel;
@property (strong) IBOutlet NSButton *ibChooseOutputFolderButton;

- (IBAction)togglePublishPageAction:(id)sender;
- (IBAction)chooseOutputFolderAction:(id)sender;
- (IBAction)publishShortAction:(id)sender;
- (IBAction)publishAction:(id)sender;
- (IBAction)insertBlockquoteAction:(id)sender;
- (IBAction)insertImageTagAction:(id)sender;
- (IBAction)insertScriptletTagAction:(id)sender;
- (IBAction)pasteHREFAction:(id)sender;
- (IBAction)initDocumentAction:(id)sender;
- (IBAction)openHelpAction:(id)sender;

- (IBAction)openSiteTemplateAction:(id)sender;
- (IBAction)openEntryTemplateAction:(id)sender;
- (IBAction)openEventScriptAction:(id)sender;



@end
