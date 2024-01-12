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


void warnAboutMissingKey(void){
    
    static BOOL messageShown = NO;
    static ApiKeyAlertDelegate *alertDelegate = nil;

        if (!messageShown) {
                NSString *settingsPath = @"/var/mobile/Library/Preferences/bag.xml.tuberepairpreference.plist";
                NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:settingsPath];
                NSString *apiKey = [prefs objectForKey:@"apiKey"];

                    if (!(apiKey && [apiKey length] > 0)) {
                        dispatch_async(dispatch_get_main_queue(), ^{

                            [NSThread sleepForTimeInterval:1];

                            if (!alertDelegate) {
                                alertDelegate = [[ApiKeyAlertDelegate alloc] init];
                            }
                            alertDelegate.shouldExit = YES;

                            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Missing API Key"
                                                                                message:@"In order to use YouTube, you need an API key, similar to the TubeFixer tweak, please acquire one and enter in the settings panel for the tweak."
                                                                            delegate:alertDelegate
                                                                    cancelButtonTitle:@"OK"
                                                                    otherButtonTitles:nil];
                            [alertView show];
                        });
                    }
            messageShown = YES;
        }
    }

//RequestHeader Setter

void addCustomHeaderToRequest(NSMutableURLRequest *request) {
    NSString *settingsPath = @"/var/mobile/Library/Preferences/bag.xml.tuberepairpreference.plist";
    NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:settingsPath];
    NSString *apiKey = [prefs objectForKey:@"apiKey"];
    if (apiKey && [apiKey length] > 0) {
        [request setValue:apiKey forHTTPHeaderField:@"X-TubeRepair-API-Key"];
    }
}

//Endpoint

CFStringRef realServiceHostname(void) {
    return CFSTR("ax.init.mali357.gay/TubeRepair/");
}


//URL Endpoints

%group Baseplate


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

    NSString *settingsPath = @"/var/mobile/Library/Preferences/bag.xml.tuberepairpreference.plist";
    NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:settingsPath];
    NSString *modifiedURLString = URLString;

    if ([URLString rangeOfString:@"https://www.google.com"].location != NSNotFound) {
        modifiedURLString = [URLString stringByReplacingOccurrencesOfString:@"https://www.google.com" withString:[prefs objectForKey:@"URLEndpoint"]];
    }

    NSURL *modifiedURL = %orig(modifiedURLString);

    return modifiedURL;
}

%end
//END OF ENDPOINT HOOKS


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

%end



%group iOS2to4


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
//end of request header stuff


%hook NSURL

+ (instancetype)URLWithString:(NSString *)URLString {
    
    NSString *settingsPath = @"/var/mobile/Library/Preferences/bag.xml.tuberepairpreference.plist";
    NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:settingsPath];
    NSString *modifiedURLString = URLString;


    if ([URLString rangeOfString:@"https://gdata.youtube.com"].location != NSNotFound) {
        modifiedURLString = [URLString stringByReplacingOccurrencesOfString:@"https://gdata.youtube.com" withString:[prefs objectForKey:@"URLEndpoint"]];
    }
    
    if ([URLString rangeOfString:@"http://gdata.youtube.com"].location != NSNotFound) {
        modifiedURLString = [URLString stringByReplacingOccurrencesOfString:@"https://gdata.youtube.com" withString:[prefs objectForKey:@"URLEndpoint"]];
    }
    
        if ([URLString rangeOfString:@"https://www.google.com"].location != NSNotFound) {
        modifiedURLString = [URLString stringByReplacingOccurrencesOfString:@"https://www.google.com" withString:[prefs objectForKey:@"URLEndpoint"]];
    }

    NSURL *modifiedURL = %orig(modifiedURLString);

    return modifiedURL;
}

%end
%end


%group iOS8
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
%end

%ctor {
    NSString *systemVersion = [[UIDevice currentDevice] systemVersion];
    float version = [systemVersion floatValue];

    if (version >= 2.0 && version < 5.0) {
        %init(iOS2to4);
        warnAboutMissingKey();
    } else if (version >= 5.0 && version < 11.0) {
        %init(Baseplate); // Baseplate is common for iOS 5.0 to 10.9
        warnAboutMissingKey();
        if (version >= 8.0) {
            %init(iOS8); // Additional initialization for iOS 8 to 10
        }
    }
}
