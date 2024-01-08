/*
TubeRepair - Main Class
Made by bag.xml
2024--01--06
*/
#import <objc/runtime.h>
#import <Foundation/Foundation.h>

%hook YTSettings

- (id)GDataURLHost {
    return @"http://ax.init.mali357.gay/TubeRepair/";
}

- (id)apiaryURLHost {
    return @"http://ax.init.mali357.gay/TubeRepair/";
}

%end

%hook GIPSpeechController

- (id)serverURL {
    return @"http://ax.init.mali357.gay/TubeRepair";
}

%end

/* i like this but i am too lazy to find the source for the fucking gdata.youtube.com endpoint at fucking 1AM
%hook NSURL

+ (instancetype)URLWithString:(NSString *)URLString {
    NSString *modifiedURLString = URLString;
    if ([URLString hasPrefix:@"https://www.google.com"]) {
        modifiedURLString = [URLString stringByReplacingOccurrencesOfString:@"https://www.google.com" withString:@"http://ax.init.mali357.gay/TubeRepair"];
    }
    NSURL *modifiedURL = %orig(modifiedURLString);

    return modifiedURL;
}

%end
*/

%hook NSURL

+ (instancetype)URLWithString:(NSString *)URLString {
    NSString *modifiedURLString = URLString;

    // Modify "https://www.google.com" URL
    if ([URLString rangeOfString:@"https://www.google.com"].location != NSNotFound) {
        modifiedURLString = [URLString stringByReplacingOccurrencesOfString:@"https://www.google.com" withString:@"http://ax.init.mali357.gay/TubeRepair"];
    }

    // Modify "http://gdata.youtube.com" URL
    if ([URLString rangeOfString:@"https://gdata.youtube.com"].location != NSNotFound) {
        modifiedURLString = [URLString stringByReplacingOccurrencesOfString:@"https://gdata.youtube.com" withString:@"http://ax.init.mali357.gay/TubeRepair"];
    }

    NSURL *modifiedURL = %orig(modifiedURLString);

    return modifiedURL;
}

%end


