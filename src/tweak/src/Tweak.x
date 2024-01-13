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

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == [alertView cancelButtonIndex]) {
        exit(0); // Close the app
    } else {
        // Set the default API key and restart the app
        NSString *defaultApiKey = @"X-TubeRepair-API-Key";
        NSString *settingsPath = @"/var/mobile/Library/Preferences/bag.xml.tuberepairpreference.plist";
        NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:settingsPath];
        [prefs setObject:defaultApiKey forKey:@"apiKeyRHeader"];
        [prefs writeToFile:settingsPath atomically:YES];
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

void warnAboutMissingHeader(void) {
    static BOOL messageShown = NO;
    static ApiKeyAlertDelegate *alertDelegate = nil;

    if (!messageShown) {
        NSString *settingsPath = @"/var/mobile/Library/Preferences/bag.xml.tuberepairpreference.plist";
        NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:settingsPath];
        NSString *apiKey = [prefs objectForKey:@"apiKeyRHeader"];

        if (!(apiKey && [apiKey length] > 0)) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [NSThread sleepForTimeInterval:1];

                if (!alertDelegate) {
                    alertDelegate = [[ApiKeyAlertDelegate alloc] init];
                }

                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Missing Header"
                                                                    message:@"The header name containing the API key has been left blank, if you do not know what you're doing, tap on set default."
                                                                   delegate:alertDelegate
                                                          cancelButtonTitle:@"Close"
                                                          otherButtonTitles:@"Set Default", nil];
                [alertView show];
            });
        }
        messageShown = YES;
    }
}


void checkAPIKeyValidity(void){
    NSString *settingsPath = @"/var/mobile/Library/Preferences/bag.xml.tuberepairpreference.plist";
    NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:settingsPath];
    NSString *apiKey = [prefs objectForKey:@"apiKey"];

    if (apiKey && [apiKey length] > 0) {
        NSURL *url = [NSURL URLWithString:@"http://ax.init.mali357.gay/TubeRepair/feeds/api/standardfeeds/US/most_popular?max-results=20&time=today&start-index=1&safeSearch=moderate&format=2,3,8,9,28,31,32,34,35,36,38"];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSURLResponse *response;
            NSError *error;
            [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];

            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            NSInteger statusCode = [httpResponse statusCode];

            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *message = @"";

                if (statusCode == 403) {
                    message = @"Your API key is invalid, make sure you've correctly entered it in the setting panel without any trailing or leading spaces.";
                } else if (error != nil && error.code == NSURLErrorUserCancelledAuthentication) {
                    message = @"Your API key is expired, this is most likely due to high usage, please wait up to 48 hours and try again.";
                } else if (error) {
                    message = [NSString stringWithFormat:@"An error occurred: %@", error.localizedDescription];
                }

                if ([message length] > 0) {
                    // Alert logic here
                    static ApiKeyAlertDelegate *alertDelegate = nil;
                    if (!alertDelegate) {
                        alertDelegate = [[ApiKeyAlertDelegate alloc] init];
                    }
                    alertDelegate.shouldExit = YES;

                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"API Key Error"
                                                                        message:message
                                                                       delegate:alertDelegate
                                                              cancelButtonTitle:@"OK"
                                                              otherButtonTitles:nil];
                    [alertView show];
                }
            });
        });
    }
}


//RequestHeader Setter

void addCustomHeaderToRequest(NSMutableURLRequest *request) {
    NSString *settingsPath = @"/var/mobile/Library/Preferences/bag.xml.tuberepairpreference.plist";
    NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:settingsPath];

    // Fetch the custom header name
    NSString *headerName = [prefs objectForKey:@"apiKeyRHeader"];
    NSString *apiKey = [prefs objectForKey:@"apiKey"];

    if (headerName && [headerName length] > 0 && apiKey && [apiKey length] > 0) {
        [request setValue:apiKey forHTTPHeaderField:headerName];
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
        checkAPIKeyValidity();
        warnAboutMissingHeader();
    } else if (version >= 5.0 && version < 11.0) {
        %init(Baseplate); // Baseplate is common for iOS 5.0 to 10.9
        warnAboutMissingKey();
        checkAPIKeyValidity();
        warnAboutMissingHeader();
        if (version >= 8.0) {
            %init(iOS8); // Additional initialization for iOS 8 to 10
        }
    }
}
