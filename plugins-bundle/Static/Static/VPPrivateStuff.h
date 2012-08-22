//
//  JSTalk.h
//  jstalk
//
//  Created by August Mueller on 1/15/09.
//  Copyright 2009 Flying Meat Inc. All rights reserved.
//

#import <VPPlugin/VPPlugin.h>
#import "JSTalk.h"

@interface NSObject (ThingsINeedToOpenUpInVPOrMakeBetter)
- (void)setMetaValue:(NSString*)value forKey:(NSString*)aKey;
- (id)store;
- (void)setAttributesForItem:(id)item;
- (id)webExportController;
- (void)resetCache;
- (void)resetAction:(id)sender;
- (NSDictionary*)renderItem:(id<VPData>)item options:(NSDictionary*)options;

- (JSTalk*)jstalk;
- (BOOL)hasFunction:(NSString*)f;
- (NSString*)renderScriptletsInHTMLString:(NSString*)str withJSTalk:(JSTalk*)jstalk usingVariables:(NSDictionary*)vars;
- (id<VPData>)makeItemWithDefaultValues:(NSDictionary*)defaultItemValues;
- (void)setDefaultNewPageUTI:(NSString*)uti;

@end

@interface NSTextView (ThingsINeedToOpenUpInVPOrMakeBetter) 
- (void)selectNextTextPlaceholder:(id)sender;
@end
