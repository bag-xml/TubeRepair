#import <Foundation/Foundation.h>
#import "YTRRootListController.h"

@implementation YTRRootListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
	}

	return _specifiers;
}

@end
