//
//  ToggleWiFiAction.m
//  MarcoPolo
//
//  Created by David Symonds on 2/05/07.
//

//#import "Apple80211.h"
#import "ToggleWiFiAction.h"
#import <CoreWLAN/CoreWLAN.h>


@implementation ToggleWiFiAction

// Begin New CoreWLAN Changes
@synthesize currentInterface;
//End New CoreWLAN Changes

- (NSString *)description
{
	if (turnOn)
		return NSLocalizedString(@"Turning WiFi on.", @"");
	else
		return NSLocalizedString(@"Turning WiFi off.", @"");
}

- (BOOL)execute:(NSString **)errorString
{
	//Begin New CoreWLAN Changes
	/*
	WirelessContextPtr wctxt;

	if (!WirelessIsAvailable())
		goto failure;
	if (WirelessAttach(&wctxt, 0) != noErr)
		goto failure;
	if (WirelessSetPower(wctxt, turnOn ? 1 : 0) != noErr) {
		WirelessDetach(wctxt);
		goto failure;
	}
	WirelessDetach(wctxt);
	*/
	self.currentInterface = [[CWInterface alloc] init];
	
	NSError *err = nil;
	BOOL result = [self.currentInterface setPower:(turnOn ? 1 : 0) error:&err];
	if( !result )
		goto failure;
	return YES;
	//End New CoreWLAN Changes

failure:
	if (turnOn)
		*errorString = NSLocalizedString(@"Failed turning WiFi on.", @"");
	else
		*errorString = NSLocalizedString(@"Failed turning WiFi off.", @"");
	return NO;
}

+ (NSString *)helpText
{
	return NSLocalizedString(@"The parameter for ToggleWiFi actions is either \"1\" "
				 "or \"0\", depending on whether you want your WiFi "
				 "turned on or off.", @"");
}

+ (NSString *)creationHelpText
{
	return NSLocalizedString(@"Turn WiFi", @"Will be followed by 'on' or 'off'");
}

@end
