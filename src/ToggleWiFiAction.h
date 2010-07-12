//
//  ToggleWiFiAction.h
//  MarcoPolo
//
//  Created by David Symonds on 3/04/07.
//

#import <Cocoa/Cocoa.h>
#import "ToggleableAction.h"

@class CWInterface;

@interface ToggleWiFiAction : ToggleableAction {
		CWInterface *currentInterface;
}

@property(readwrite, retain) CWInterface *currentInterface;

- (NSString *)description;
- (BOOL)execute:(NSString **)errorString;
+ (NSString *)helpText;
+ (NSString *)creationHelpText;

@end
