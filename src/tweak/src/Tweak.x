/*
TubeRepair - Main Class
Made by bag.xml
2024--01--06
*/
#import <objc/runtime.h>
#import <Foundation/Foundation.h>

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


//kill yourself iOS 8
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
//yeah kys ios 8


%hook GIPSpeechController

- (id)serverURL {
    //WORK IN PROGRESS
    NSString *settingsPath = @"/var/mobile/Library/Preferences/bag.xml.tuberepairpreference.plist";
    NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:settingsPath];
    return [prefs objectForKey:@"speechURL"];
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

    if ([URLString rangeOfString:@"http://gdata.youtube.com"].location != NSNotFound) {
        modifiedURLString = [URLString stringByReplacingOccurrencesOfString:@"http://gdata.youtube.com" withString:[prefs objectForKey:@"URLEndpoint"]];
    }

    NSURL *modifiedURL = %orig(modifiedURLString);

    return modifiedURL;
}

%end