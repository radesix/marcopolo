//
//  WiFiEvidenceSource.h
//  MarcoPolo
//
//  Created by David Symonds on 29/03/07.
//

#import <Cocoa/Cocoa.h>
#import "GenericLoopingEvidenceSource.h"


@class CWInterface;
@class CWNetwork;


@interface WiFiEvidenceSource : GenericLoopingEvidenceSource {
	NSLock *lock;
	NSMutableArray *apList;
	int wakeUpCounter;
	
	CWInterface *currentInterface;
	NSMutableArray *scanResults;
}

@property(readwrite, retain) CWInterface *currentInterface;
@property(readwrite, retain) NSMutableArray *scanResults;

- (id)init;
- (void)dealloc;

- (void)wakeFromSleep:(id)arg;

- (void)doUpdate;
- (void)clearCollectedData;

- (NSString *)name;
- (NSArray *)typesOfRulesMatched;
- (BOOL)doesRuleMatch:(NSDictionary *)rule;
- (NSString *)getSuggestionLeadText:(NSString *)type;
- (NSArray *)getSuggestions;

@end
