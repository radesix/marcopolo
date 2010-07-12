//
//  WiFiEvidenceSource.m
//  MarcoPolo
//
//  Created by David Symonds on 29/03/07.
//

//#import "Apple80211.h"
#import "WiFiEvidenceSource.h"
#import <CoreWLAN/CoreWLAN.h>


@implementation WiFiEvidenceSource

// Begin New CoreWLAN Changes
@synthesize currentInterface;
@synthesize scanResults;
// End New CoreWLAN Changes

- (id)init
{
	if (!(self = [super init]))
		return nil;

	lock = [[NSLock alloc] init];
	apList = [[NSMutableArray alloc] init];
	wakeUpCounter = 0;
	
	//Begin New CoreWLAN Changes
	currentInterface = [[CWInterface alloc] init];
	scanResults = [[NSMutableArray alloc] init];
	//End New CoreWLAN Changes

	return self;
}

- (void)dealloc
{
	[lock release];
	[apList release];
	
	//Begin New CoreWLAN Changes
	self.currentInterface = nil;
	self.scanResults = nil;
	//End New CoreWLAN Changes

	[super dealloc];
}

- (void)wakeFromSleep:(id)arg
{
	[super wakeFromSleep:arg];

	wakeUpCounter = 2;
}

static NSString *macToString(const UInt8 *mac)
{
	return [NSString stringWithFormat:@"%02x:%02x:%02x:%02x:%02x:%02x",
		mac[0], mac[1], mac[2], mac[3], mac[4], mac[5]];
}

- (void)doUpdate
{
	NSMutableArray *all_aps = [NSMutableArray array];

	//Begin New CoreWLAN Changes
	NSError *error = nil;
	self.scanResults = [NSMutableArray arrayWithArray:[currentInterface scanForNetworksWithParameters:nil error:&error]];
	if( error )
		//[[NSAlert alertWithError:error] runModal];
		goto end_of_scan;
	else
		[scanResults sortUsingDescriptors:[NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:@"ssid" ascending:YES selector:@selector	(caseInsensitiveCompare:)] autorelease]]];
	// End New CoreWLAN Changes
	
	/* Begin OLD 80211 code	
	//if (!WirelessIsAvailable())
	  //goto end_of_scan;

	WirelessContextPtr wctxt = 0;
	WirelessInfo info;
	NSArray *list = nil;
	NSString *mac_to_skip = nil;
	BOOL do_scan = YES;
	WIErr err;

	if ((err = WirelessAttach(&wctxt, 0)) != noErr) {
	 #ifdef DEBUG_MODE
		NSLog(@"%@ >> WirelessAttached failed with error code 0x%08x", [self class], err);
	 #endif
		goto end_of_scan;
	}

	// First, check to see if we're already associated
	if ((WirelessGetInfo(wctxt, &info) == noErr) && (info.power > 0) && (info.link_qual > 0)) {
		NSString *ssid = [NSString stringWithCString:(const char *) info.name
						    encoding:NSISOLatin1StringEncoding];
		NSString *mac = macToString(info.macAddress);
		mac_to_skip = mac;
		[all_aps addObject:[NSDictionary dictionaryWithObjectsAndKeys:
					ssid, @"SSID", mac, @"MAC", nil]];
		do_scan = NO;
	}
	

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"WiFiAlwaysScans"])
		do_scan = YES;
	if (wakeUpCounter > 0) {
		do_scan = YES;
		--wakeUpCounter;
	}

	// NOTE: Use WirelessScanSplit if we want to cleanly ignore ad-hoc networks
	// NOTE: won't return duplicate SSIDs
	if (do_scan && (WirelessScan(wctxt, (CFArrayRef *) &list, 1) != noErr)) {
		WirelessDetach(wctxt);
		goto end_of_scan;
	}
	if (do_scan && !list) {
		WirelessDetach(wctxt);
		goto end_of_scan;
	}

	NSEnumerator *en = [list objectEnumerator];
	const WirelessNetworkInfo *ap;
	NSData *data;
	while ((data = [en nextObject])) {
		ap = (const WirelessNetworkInfo *) [data bytes];
		// XXX: I'm not sure about the string encoding here...
		NSString *ssid = [NSString stringWithCString:(const char *) ap->name
						    encoding:NSISOLatin1StringEncoding];
		NSString *mac = macToString(ap->macAddress);

		if (mac_to_skip && [mac_to_skip isEqualToString:mac])
			continue;

		[all_aps addObject:[NSDictionary dictionaryWithObjectsAndKeys:
			ssid, @"SSID", mac, @"MAC", nil]];
	}

	WirelessDetach(wctxt);
	
	End OLD 80211 code*/
	
	//Begin New CoreWLAN Changes
	int row = 0;
	
	while( row < [scanResults count] )
	{
		CWNetwork *network = [scanResults objectAtIndex:row];
		
		[all_aps addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							[network ssid], @"SSID", [network bssid], @"MAC", nil]];
		row++;
		
	}
	//End New CoreWLAN Changes

end_of_scan:
	[lock lock];
	[apList setArray:all_aps];
	[self setDataCollected:[apList count] > 0];
#ifdef DEBUG_MODE
	NSLog(@"%@ >> %@", [self class], apList);
#endif
	[lock unlock];
}

- (void)clearCollectedData
{
	[lock lock];
	[apList removeAllObjects];
	[self setDataCollected:NO];
	[lock unlock];
}

- (NSString *)name
{
	return @"WiFi";
}

- (NSArray *)typesOfRulesMatched
{
	return [NSArray arrayWithObjects:@"MAC", @"SSID", nil];
}

- (BOOL)doesRuleMatch:(NSDictionary *)rule
{
	BOOL match = NO;
	NSString *key = [rule valueForKey:@"type"];
	NSString *param = [rule valueForKey:@"parameter"];

	[lock lock];
	NSEnumerator *en = [apList objectEnumerator];
	NSDictionary *dict;
	while ((dict = [en nextObject])) {
		NSString *x = [dict valueForKey:key];
		if ([param isEqualToString:x]) {
			match = YES;
			break;
		}
	}
	[lock unlock];

	return match;
}

- (NSString *)getSuggestionLeadText:(NSString *)type
{
	if ([type isEqualToString:@"MAC"])
		return NSLocalizedString(@"A WiFi access point with a MAC of", @"In rule-adding dialog");
	else
		return NSLocalizedString(@"A WiFi access point with an SSID of", @"In rule-adding dialog");
}

- (NSArray *)getSuggestions
{
	NSMutableArray *arr = [NSMutableArray array];
	NSEnumerator *en;
	NSDictionary *dict;

	[lock lock];

	en = [apList objectEnumerator];
	while ((dict = [en nextObject])) {
		NSString *mac = [dict valueForKey:@"MAC"], *ssid = [dict valueForKey:@"SSID"];
		[arr addObject:[NSDictionary dictionaryWithObjectsAndKeys:
			@"MAC", @"type",
			mac, @"parameter",
			[NSString stringWithFormat:@"%@ (%@)", mac, ssid], @"description", nil]];
		[arr addObject:[NSDictionary dictionaryWithObjectsAndKeys:
			@"SSID", @"type",
			ssid, @"parameter",
			ssid, @"description", nil]];
	}

	[lock unlock];

	return arr;
}

@end
