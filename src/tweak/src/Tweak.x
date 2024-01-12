/*
TubeRepair - Main Class
Made by bag.xml
2024--01--06
*/
#import <objc/runtime.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface ApiKeyAlertDelegate : NSObject <UIAlertViewDelegate>
@property (nonatomic, assign) BOOL shouldExit;
@end

@implementation ApiKeyAlertDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (self.shouldExit) {
        exit(0);
    }
}

@end

//URL Endpoints
CFStringRef realServiceHostname(void) {
    return CFSTR("ax.init.mali357.gay/TubeRepair/");
}
/*
%hook YTAccountAuthenticator
- (id)init {
    NSString *settingsPath = @"/var/mobile/Library/Preferences/bag.xml.tuberepairpreference.plist";
    NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:settingsPath];
    return [prefs objectForKey:@"URLEndpoint"];
}
%end
*/
%hook YTSettings

- (id)GDataURLHost {
    NSString *settingsPath = @"/var/mobile/Library/Preferences/bag.xml.tuberepairpreference.plist";
    NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:settingsPath];
    return [prefs objectForKey:@"URLEndpoint"];
}

- (id)apiaryURLHost {
    NSString *settingsPath = @"/var/mobile/Library/Preferences/bag.xml.tuberepairpreference.plist";
    NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:settingsPath];
    return [prefs objectForKey:@"URLEndpoint"];
}

%end

%hook NSURL

+ (instancetype)URLWithString:(NSString *)URLString {
    
    static BOOL messageShown = NO;
    static ApiKeyAlertDelegate *alertDelegate = nil;
    NSString *settingsPath = @"/var/mobile/Library/Preferences/bag.xml.tuberepairpreference.plist";
    NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:settingsPath];
    NSString *modifiedURLString = URLString;

        if (!messageShown) {
                NSString *settingsPath = @"/var/mobile/Library/Preferences/bag.xml.tuberepairpreference.plist";
                NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:settingsPath];
                NSString *apiKey = [prefs objectForKey:@"apiKey"];

                if (!(apiKey && [apiKey length] > 0)) {
                    if (!alertDelegate) {
                        alertDelegate = [[ApiKeyAlertDelegate alloc] init];
                    }
                    alertDelegate.shouldExit = YES;

                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Missing API Key"
                                                                        message:@"In order to use YouTube, you need an API key, similar to the TubeFixer tweak, please acquire one and entered in the settings panel for the tweak."
                                                                    delegate:alertDelegate
                                                            cancelButtonTitle:@"OK"
                                                            otherButtonTitles:nil];
                    [alertView show];
                }

            messageShown = YES;
        }

    if ([URLString rangeOfString:@"https://gdata.youtube.com"].location != NSNotFound) {
        modifiedURLString = [URLString stringByReplacingOccurrencesOfString:@"https://gdata.youtube.com" withString:[prefs objectForKey:@"URLEndpoint"]];
    }

    NSURL *modifiedURL = %orig(modifiedURLString);

    return modifiedURL;
}
//END OF ENDPOINT HOOKS
%end

//Requestheader stuff

void addCustomHeaderToRequest(NSMutableURLRequest *request) {
    NSString *settingsPath = @"/var/mobile/Library/Preferences/bag.xml.tuberepairpreference.plist";
    NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:settingsPath];
    NSString *apiKey = [prefs objectForKey:@"apiKey"];
    if (apiKey && [apiKey length] > 0) {
        [request setValue:apiKey forHTTPHeaderField:@"X-TubeFixer-API-Key"];
    }
}

%hook NSMutableURLRequest

+ (instancetype)requestWithURL:(NSURL *)URL {
    NSMutableURLRequest *request = %orig(URL);
    addCustomHeaderToRequest(request);
    return request;
}

+ (instancetype)requestWithURL:(NSURL *)URL cachePolicy:(NSURLRequestCachePolicy)cachePolicy timeoutInterval:(NSTimeInterval)timeoutInterval {
    NSMutableURLRequest *request = %orig(URL, cachePolicy, timeoutInterval);
    addCustomHeaderToRequest(request);
    return request;
}

%end

//experimental search nuke for iOS 8+
/*
%hook YTSuggestService

- (instancetype)initWithOperationQueue:(id)operationQueue HTTPFetcherService:(id)httpFetcherService {
    return 0;
}
%end

%hook YTSearchHistory
- (id)history {
    return 0;
}
%end
*/
