/*
TubeRepair - Main Class
Made by bag.xml
2024--01--06
*/
#import <objc/runtime.h>
#import <Foundation/Foundation.h>

%hook YTSettings

- (id)GDataURLHost {
    return @"http://ax.init.mali357.gay/TubeRepair";
}

- (id)apiaryURLHost {
    return @"http://ax.init.mali357.gay/TubeRepair";
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

    // Check if the URL starts with www.google.com
    if ([URLString hasPrefix:@"http://www.google.com"] || [URLString hasPrefix:@"https://www.google.com"]) {
        // Replace www.google.com with ax.init.mali357.gay
        modifiedURLString = [URLString stringByReplacingOccurrencesOfString:@"www.google.com" withString:@"ax.init.mali357.gay"];
    }

    // Call the original method with the modified URL
    NSURL *modifiedURL = %orig(modifiedURLString);
    
    return modifiedURL;
}

%end
