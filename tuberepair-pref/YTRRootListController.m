#import <Foundation/Foundation.h>
#import "YTRRootListController.h"

@implementation YTRRootListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
	}

	return _specifiers;
}

-(void)save
{
    [self.view endEditing:YES];
}

- (void)guide {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://tuberepair.bag-xml.com/guide/"]];
}

@end
