/*
TubeRepair - Main Class
Made by bag.xml
2024--01--06
*/
#import <objc/runtime.h>
#import <Foundation/Foundation.h>

/*
- (id)GDataURLHost {
    return @"http://ax.init.mali357.gay/TubeRepair/";
}
*/

%hook YTSettings

- (id)GDataURLHost {
    NSDictionary *bundleDefaults = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"/var/mobile/Library/Preferences/bag.xml.tuberepairpreference.plist"];

    return [bundleDefaults valueForKey:@"GDataURLEndpoint"];
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

%hook NSURL

+ (instancetype)URLWithString:(NSString *)URLString {
    NSString *modifiedURLString = URLString;

    if ([URLString rangeOfString:@"https://www.google.com"].location != NSNotFound) {
        modifiedURLString = [URLString stringByReplacingOccurrencesOfString:@"https://www.google.com" withString:@"http://ax.init.mali357.gay/TubeRepair"];
    }

    if ([URLString rangeOfString:@"https://gdata.youtube.com"].location != NSNotFound) {
        modifiedURLString = [URLString stringByReplacingOccurrencesOfString:@"https://gdata.youtube.com" withString:@"http://ax.init.mali357.gay/TubeRepair"];
    }

    NSURL *modifiedURL = %orig(modifiedURLString);

    return modifiedURL;
}

%end
/*
%ctor {
    float versions = [[[UIDevice currentDevice] systemVersion] floatValue];
    if(versions >= 8) {
        %init(iOS8);
    } else {
        %init(regular);
    }
}
*/
