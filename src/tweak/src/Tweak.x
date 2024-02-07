/*
TubeRepair - Main Class
Made by bag.xml and ObscureMosquito :)
2024--01--06
*/

#import <objc/runtime.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CommonCrypto/CommonCrypto.h>
#import "TubeRepair.h"

NSString *globalClientID = @"Hello";
NSString *globalClientSecret = nil;

void extractClientIDAndSecretFromScript(NSString *scriptUrl, void(^completion)(BOOL, NSString *, NSString *));

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

@implementation EncryptionUtility

+ (NSString *)encryptToken:(NSString *)token {
    // Key and IV should be the same as used in your PHP decryption script
    NSString *key = @"your-32-byte-key"; // Change this to your AES key
    NSString *iv = @"your-16-byte-iv"; // Change this to your AES IV

    NSData *data = [token dataUsingEncoding:NSUTF8StringEncoding];
    NSData *encryptedData = [self AES256EncryptData:data withKey:key iv:iv];

    // For iOS 6, you may need to use an alternative to base64EncodedStringWithOptions:
    return [self base64StringFromData:encryptedData length:[encryptedData length]];
}

+ (NSData *)AES256EncryptData:(NSData *)data withKey:(NSString *)key iv:(NSString *)iv {
    char keyPtr[kCCKeySizeAES256 + 1];
    bzero(keyPtr, sizeof(keyPtr));
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    
    char ivPtr[kCCBlockSizeAES128 + 1];
    bzero(ivPtr, sizeof(ivPtr));
    [iv getCString:ivPtr maxLength:sizeof(ivPtr) encoding:NSUTF8StringEncoding];
    
    NSUInteger dataLength = [data length];
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    
    size_t numBytesEncrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding,
                                          keyPtr, kCCKeySizeAES256,
                                          ivPtr,
                                          [data bytes], dataLength,
                                          buffer, bufferSize,
                                          &numBytesEncrypted);
    if (cryptStatus == kCCSuccess) {
        return [NSData dataWithBytesNoCopy:buffer length:numBytesEncrypted];
    }
    
    free(buffer);
    return nil;
}

+ (NSString *)base64StringFromData:(NSData *)data length:(int)length {
    static const char encodingTable[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    if (length == 0)
        return @"";
    
    char *characters = malloc(((length + 2) / 3) * 4);
    if (characters == NULL)
        return nil;
    
    NSUInteger i = 0;
    NSUInteger j = 0;
    while (i < length) {
        uint32_t buffer = 0;
        short bufferLength = 0;
        while (bufferLength < 3 && i < length) {
            buffer <<= 8;
            buffer |= (uint32_t)(((const uint8_t *)[data bytes])[i++]);
            bufferLength++;
        }
        
        while (bufferLength++ < 3) {
            buffer <<= 8;
        }
        
        while (j < 4) {
            characters[j++] = encodingTable[(buffer >> 18) & 0x3F];
            buffer <<= 6;
        }
    }

    characters[j - 1] = '=';
    NSString *base64String = [[NSString alloc] initWithBytesNoCopy:characters length:j encoding:NSASCIIStringEncoding freeWhenDone:YES];
    
    return base64String;
}

@end

void extractClientIDAndSecretFromScript(NSString *scriptContent, void(^completion)(BOOL success, NSString *clientID, NSString *clientSecret)) {
    NSError *regexError = nil;
    
    // Client ID Regex
    NSRegularExpression *clientIdRegex = [NSRegularExpression regularExpressionWithPattern:@"clientId:\"([^\\\"]+)\"" options:NSRegularExpressionCaseInsensitive error:&regexError];
    if (regexError) {
        NSLog(@"Client ID Regex error: %@", regexError.localizedDescription);
        completion(NO, nil, nil);
        return;
    }
    
    // Client Secret Regex
    NSRegularExpression *clientSecretRegex = [NSRegularExpression regularExpressionWithPattern:@"Kv:\"([^\\\"]+)\"" options:NSRegularExpressionCaseInsensitive error:&regexError];
    if (regexError) {
        NSLog(@"Client Secret Regex error: %@", regexError.localizedDescription);
        completion(NO, nil, nil);
        return;
    }
    
    NSTextCheckingResult *clientIdMatch = [clientIdRegex firstMatchInString:scriptContent options:0 range:NSMakeRange(0, scriptContent.length)];
    NSTextCheckingResult *clientSecretMatch = [clientSecretRegex firstMatchInString:scriptContent options:0 range:NSMakeRange(0, scriptContent.length)];
    
    if (clientIdMatch && clientSecretMatch) {
        NSString *clientId = [scriptContent substringWithRange:[clientIdMatch rangeAtIndex:1]]; // Extracted Client ID
        NSString *clientSecret = [scriptContent substringWithRange:[clientSecretMatch rangeAtIndex:1]]; // Extracted Client Secret
        NSLog(@"Extracted Client ID: %@, Client Secret: %@", clientId, clientSecret);
        globalClientID = clientId;
        globalClientSecret = clientSecret;
        
        completion(YES, clientId, clientSecret);
    } else {
        NSLog(@"Failed to extract client ID and/or secret.");
        completion(NO, nil, nil);
    }
}

void fetchYouTubeTVPageAndExtractClientID(void(^completion)(BOOL, NSString *, NSString *)) {
    NSURL *url = [NSURL URLWithString:@"https://www.youtube.com/tv"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    // Add headers to the request
    [request setValue:@"*/*" forHTTPHeaderField:@"Accept"];
    [request setValue:@"https://www.youtube.com" forHTTPHeaderField:@"Origin"];
    [request setValue:@"Mozilla/5.0 (ChromiumStylePlatform) Cobalt/Version" forHTTPHeaderField:@"User-Agent"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"https://www.youtube.com/tv" forHTTPHeaderField:@"Referer"];
    [request setValue:@"en-US" forHTTPHeaderField:@"Accept-Language"];

    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            NSLog(@"Error fetching YouTube TV page: %@", error.localizedDescription);
            completion(NO, nil, nil);
            return;
        }
        
        NSString *htmlContent = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSError *regexError = nil;
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"<script id=\"base-js\" src=\"(.*?)\" nonce=\".*?\"><\\/script>" options:NSRegularExpressionCaseInsensitive error:&regexError];
        if (regexError) {
            NSLog(@"Regex error: %@", regexError.localizedDescription);
            completion(NO, nil, nil);
            return;
        }
        
        NSTextCheckingResult *match = [regex firstMatchInString:htmlContent options:0 range:NSMakeRange(0, htmlContent.length)];
        if (match) {
            NSString *relativeScriptUrl = [htmlContent substringWithRange:[match rangeAtIndex:1]];
            // Prepend the base URL to form the full URL
            NSURL *fullScriptUrl = [NSURL URLWithString:relativeScriptUrl relativeToURL:[NSURL URLWithString:@"https://www.youtube.com"]];
            NSLog(@"Complete script URL: %@", fullScriptUrl.absoluteString);

            NSMutableURLRequest *scriptRequest = [NSMutableURLRequest requestWithURL:fullScriptUrl];
            // Include headers if necessary
            [scriptRequest setValue:@"Mozilla/5.0 (ChromiumStylePlatform) Cobalt/Version" forHTTPHeaderField:@"User-Agent"];
            [scriptRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
            [scriptRequest setValue:@"*/*" forHTTPHeaderField:@"Accept"];
            [scriptRequest setValue:@"https://www.youtube.com" forHTTPHeaderField:@"Origin"];
            [scriptRequest setValue:@"https://www.youtube.com/tv" forHTTPHeaderField:@"Referer"];
            [scriptRequest setValue:@"en-US" forHTTPHeaderField:@"Accept-Language"];

            [NSURLConnection sendAsynchronousRequest:scriptRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                if (error) {
                    NSLog(@"Error fetching script: %@", error.localizedDescription);
                    return;
                }

                NSString *scriptContent = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                
                // Extract client ID and secret from the script content
                extractClientIDAndSecretFromScript(scriptContent, ^(BOOL success, NSString *clientID, NSString *clientSecret) {
                    if (success) {
                        NSLog(@"Successfully extracted Client ID: %@, Client Secret: %@", clientID, clientSecret);
                        // Handle the extracted credentials as needed
                    } else {
                        NSLog(@"Failed to extract credentials from script.");
                    }
                });
            }];
        } else {
            NSLog(@"Script URL not found.");
        }
    }];
}

void betaSetDefaultUrl(void) {
    NSString *defaultApiKey = @"http://ax.init.mali357.gay/TubeRepair/";
    NSString *settingsPath = @"/var/mobile/Library/Preferences/bag.xml.tuberepairpreference.plist";
    NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:settingsPath];

    NSString *existingValue = [prefs objectForKey:@"URLEndpoint"];
    if (existingValue == nil || [existingValue isEqualToString:@""]) {
        [prefs setObject:defaultApiKey forKey:@"URLEndpoint"];
        [prefs writeToFile:settingsPath atomically:YES];
    }
}

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
        // Fetch the base URL from the .plist file
        NSString *baseURL = [prefs objectForKey:@"URLEndpoint"];
        if (!baseURL) {
            // Fallback to a default URL if the base URL is not set
            baseURL = @"http://ax.init.mali357.gay/";
        }

        // Append the specific endpoint to the base URL
        NSString *fullURL = [baseURL stringByAppendingString:@"feeds/api/standardfeeds/ES/most_popular?max-results=20&time=today&start-index=1"];
        NSURL *url = [NSURL URLWithString:fullURL];
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


void refreshOAuthTokenIfNeeded(void) {
    NSString *settingsPath = @"/var/mobile/Library/Preferences/bag.xml.tuberepairpreference.plist";
    NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:settingsPath];

    // Check if the OAuth access token is present
    NSString *accessToken = [prefs objectForKey:@"OAuthAccessToken"];
    if (!accessToken) {
        // Access token not present, likely user has not logged in
        return; // Stop the function
    }

    NSDate *tokenExpirationDate = [prefs objectForKey:@"OAuthTokenExpirationDate"];
    NSString *refreshToken = [prefs objectForKey:@"OAuthRefreshToken"];
    NSString *clientID = globalClientID;
    NSString *clientSecret = globalClientSecret;

    // Check if the token is about to expire (say, within the next 5 minutes)
    if (tokenExpirationDate && ([[NSDate date] timeIntervalSinceDate:tokenExpirationDate] > -300 || [[NSDate date] timeIntervalSinceDate:tokenExpirationDate] > 0) && refreshToken) {
        // Token is about to expire, use the refresh token to get a new access token
        NSString *tokenRequestBodyString = [NSString stringWithFormat:@"client_id=%@&client_secret=%@&refresh_token=%@&grant_type=refresh_token", clientID, clientSecret, refreshToken];
        NSData *tokenRequestBodyData = [tokenRequestBodyString dataUsingEncoding:NSUTF8StringEncoding];

        NSMutableURLRequest *tokenRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://oauth2.googleapis.com/token"]];
        [tokenRequest setHTTPMethod:@"POST"];
        [tokenRequest setHTTPBody:tokenRequestBodyData];
        [tokenRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];

        NSError *error;
        NSURLResponse *response;
        NSData *tokenResponseData = [NSURLConnection sendSynchronousRequest:tokenRequest returningResponse:&response error:&error];

        if (!error && tokenResponseData) {
            NSDictionary *tokenResponse = [NSJSONSerialization JSONObjectWithData:tokenResponseData options:0 error:&error];
            if (!error && tokenResponse) {
                NSString *newAccessToken = tokenResponse[@"access_token"];
                NSNumber *expiresIn = tokenResponse[@"expires_in"];

                if (newAccessToken && expiresIn) {
                    // Save the new access token and update the expiration date
                    NSDate *newExpirationDate = [[NSDate date] dateByAddingTimeInterval:[expiresIn doubleValue]];
                    [prefs setObject:newAccessToken forKey:@"OAuthAccessToken"];
                    [prefs setObject:newExpirationDate forKey:@"OAuthTokenExpirationDate"];
                    [prefs writeToFile:settingsPath atomically:YES];
                    scheduleTokenRefresh();
                }
            }
        }
    }
}


void scheduleTokenRefresh(void) {
    NSString *settingsPath = @"/var/mobile/Library/Preferences/bag.xml.tuberepairpreference.plist";
    NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:settingsPath];
    NSDate *tokenExpirationDate = [prefs objectForKey:@"OAuthTokenExpirationDate"];

    if (tokenExpirationDate) {
        NSTimeInterval timeUntilExpiration = [tokenExpirationDate timeIntervalSinceNow];
        dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, (int64_t)((timeUntilExpiration - 60) * NSEC_PER_SEC));

        dispatch_after(delay, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            refreshOAuthTokenIfNeeded();
        });

        if (timeUntilExpiration <= 0) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                refreshOAuthTokenIfNeeded();
            });
        }
    }
}


//RequestHeader Setter

void addCustomHeaderToRequest(NSMutableURLRequest *request) {
    NSString *settingsPath = @"/var/mobile/Library/Preferences/bag.xml.tuberepairpreference.plist";
    NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:settingsPath];

    // Fetch the custom header name and API key
    NSString *headerName = [prefs objectForKey:@"apiKeyRHeader"];
    NSString *apiKey = [prefs objectForKey:@"apiKey"];

    if (headerName && [headerName length] > 0 && apiKey && [apiKey length] > 0) {
        [request setValue:apiKey forHTTPHeaderField:headerName];
    }

    // Check for OAuth token and add it to the request header if available
    NSString *oAuthToken = [prefs objectForKey:@"OAuthAccessToken"];
    if (oAuthToken && [oAuthToken length] > 0) {
        // No encryption ATM
        [request setValue:oAuthToken forHTTPHeaderField:@"OAuth-Token"];
    }
}


//URL Endpoints

%group Baseplate

%hook YTSignInPopoverController_iPhone

- (void)presentInPopoverFromRect:(CGRect)a3 inView:(id)a4 permittedArrowDirections:(unsigned int)a5 resourceLoader:(id)a6 {
    // Step 1: Request Device Code
    NSURL *deviceCodeRequestURL = [NSURL URLWithString:@"https://oauth2.googleapis.com/device/code"];
    CFUUIDRef uuidRef = CFUUIDCreate(kCFAllocatorDefault);
    NSString *uuidString = (__bridge_transfer NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuidRef);
    CFRelease(uuidRef);
    
    // Prepare the dictionary with request parameters
    NSDictionary *requestParams = @{
        @"client_id": globalClientID,
        @"client_secret": globalClientSecret,
        @"scope": @"http://gdata.youtube.com https://www.googleapis.com/auth/youtube-paid-content",
        @"device_id": uuidString, // Use the generated UUID
        @"device_model": @"ytlr::", // Assuming this value is static; replace as needed
        @"grant_type": @"urn:ietf:params:oauth:grant-type:device_code"
    };

    NSError *error;
    NSData *deviceCodeRequestBodyData = [NSJSONSerialization dataWithJSONObject:requestParams options:0 error:&error];
    if (error) {
        NSLog(@"Error serializing request body: %@", error.localizedDescription);
        return;
    }

    NSMutableURLRequest *deviceCodeRequest = [NSMutableURLRequest requestWithURL:deviceCodeRequestURL];
    [deviceCodeRequest setHTTPMethod:@"POST"];
    [deviceCodeRequest setHTTPBody:deviceCodeRequestBodyData];
    [deviceCodeRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    NSError *deviceCodeError;
    NSURLResponse *deviceCodeResponse;
    NSData *deviceCodeResponseData = [NSURLConnection sendSynchronousRequest:deviceCodeRequest returningResponse:&deviceCodeResponse error:&deviceCodeError];

    __block NSString *deviceCode = nil;
    __block UIAlertView *deviceCodeAlert = nil;
    
    if (!deviceCodeError && deviceCodeResponseData) {
        NSDictionary *deviceCodeResponseDict = [NSJSONSerialization JSONObjectWithData:deviceCodeResponseData options:0 error:&deviceCodeError];
        if (!deviceCodeError && deviceCodeResponseDict) {
            deviceCode = deviceCodeResponseDict[@"device_code"];
            NSString *userCode = deviceCodeResponseDict[@"user_code"];
            NSString *verificationURL = deviceCodeResponseDict[@"verification_url"];

            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *message = [NSString stringWithFormat:@"Please visit %@ and enter the code: %@, this is required In order to sign into TubeRepair securely, you only need to do this once, this message will close when verification completes or after one minute.", verificationURL, userCode];
                deviceCodeAlert = [[UIAlertView alloc] initWithTitle:@"Sign In Required" message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
                [deviceCodeAlert show];

                // Schedule the alert to be dismissed after 1 minute
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(60 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    if (deviceCodeAlert.visible) {
                        [deviceCodeAlert dismissWithClickedButtonIndex:0 animated:YES];
                    }
                });
            });

            // Move to background thread for polling
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                // Step 2: Polling for the OAuth token
                BOOL shouldContinuePolling = YES;
                NSDate *pollingEndTime = [[NSDate date] dateByAddingTimeInterval:60];

                while (shouldContinuePolling && [[NSDate date] compare:pollingEndTime] == NSOrderedAscending) {
                    [NSThread sleepForTimeInterval:5]; // Poll every 5 seconds

                    NSString *tokenRequestBodyString = [NSString stringWithFormat:@"client_id=%@&client_secret=%@&device_code=%@&grant_type=urn:ietf:params:oauth:grant-type:device_code", globalClientID, globalClientSecret, deviceCode];
                    NSData *tokenRequestBodyData = [tokenRequestBodyString dataUsingEncoding:NSUTF8StringEncoding];

                    NSMutableURLRequest *tokenRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://oauth2.googleapis.com/token"]];
                    [tokenRequest setHTTPMethod:@"POST"];
                    [tokenRequest setHTTPBody:tokenRequestBodyData];
                    [tokenRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];

                    NSError *error;
                    NSURLResponse *response;
                    NSData *tokenResponseData = [NSURLConnection sendSynchronousRequest:tokenRequest returningResponse:&response error:&error];

                    if (!error && tokenResponseData) {
                        NSDictionary *tokenResponse = [NSJSONSerialization JSONObjectWithData:tokenResponseData options:0 error:&error];
                        if (!error && tokenResponse) {
                            NSString *accessToken = tokenResponse[@"access_token"];
                            NSString *refreshToken = tokenResponse[@"refresh_token"];
                            NSNumber *expiresIn = tokenResponse[@"expires_in"];

                            if (accessToken && expiresIn) {
                                // Calculate and save the expiration date
                                NSDate *expirationDate = [[NSDate date] dateByAddingTimeInterval:[expiresIn doubleValue]];
                                NSString *settingsPath = @"/var/mobile/Library/Preferences/bag.xml.tuberepairpreference.plist";
                                NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:settingsPath];

                                [prefs setObject:accessToken forKey:@"OAuthAccessToken"];
                                [prefs setObject:expirationDate forKey:@"OAuthTokenExpirationDate"];
                                [prefs setObject:refreshToken forKey:@"OAuthRefreshToken"];
                                [prefs writeToFile:settingsPath atomically:YES];

                                // Notify the user of successful authentication and dismiss alert
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    if (deviceCodeAlert.visible) {
                                        [deviceCodeAlert dismissWithClickedButtonIndex:0 animated:YES];
                                    }
                                    UIAlertView *successAlert = [[UIAlertView alloc] initWithTitle:@"Authentication Successful" message:@"You have been successfully authenticated." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                                    [successAlert show];
                                });
                                shouldContinuePolling = NO;
                            } else if ([tokenResponse[@"error"] isEqualToString:@"authorization_pending"]) {
                                // Continue polling
                            } else {
                                // Stop polling and handle error
                                shouldContinuePolling = NO;
                                NSLog(@"Error during token polling: %@", tokenResponse[@"error"]);
                            }
                        }
                    } else {
                        // Stop polling and handle error
                        shouldContinuePolling = NO;
                        NSLog(@"Error requesting token: %@", error);
                    }
                }
            });
        }
    }
}

%end

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
    NSString *newURL = [prefs objectForKey:@"URLEndpoint"];
    
    if ([URLString rangeOfString:@"https://www.google.com"].location != NSNotFound) {
        modifiedURLString = [URLString stringByReplacingOccurrencesOfString:@"https://www.google.com" withString:[prefs objectForKey:@"URLEndpoint"]];
    }
    
    if ([URLString rangeOfString:@"https://gdata.youtube.com/feeds/api/playlists"].location != NSNotFound) {
        modifiedURLString = [URLString stringByReplacingOccurrencesOfString:@"https://gdata.youtube.com/feeds/api/playlists" withString:[NSString stringWithFormat:@"%@/feeds/api/playlists", newURL]];
    }
    /*overhaul sometime later, my vision is that this should be divided into %group's, and depending on which app is open, the respective group is being run. So that'd be www.google.com and http://gdata.youtube.com for com.apple.youtube, and https://gdata.youtube.com/feeds/api/playlists for com.google.ios.youtube. this would essentially make our tweak super efficient.*/
    if ([URLString rangeOfString:@"http://gdata.youtube.com"].location != NSNotFound) {
        modifiedURLString = [URLString stringByReplacingOccurrencesOfString:@"http://gdata.youtube.com" withString:[prefs objectForKey:@"URLEndpoint"]];
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

%hook YTSignInPopoverController_iPhone

- (void)presentInPopoverFromRect:(CGRect)a3 inView:(id)a4 permittedArrowDirections:(unsigned int)a5 resourceLoader:(id)a6 {
    // Step 1: Request Device Code
    NSURL *deviceCodeRequestURL = [NSURL URLWithString:@"https://oauth2.googleapis.com/device/code"];
    CFUUIDRef uuidRef = CFUUIDCreate(kCFAllocatorDefault);
    NSString *uuidString = (__bridge_transfer NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuidRef);
    CFRelease(uuidRef);
    
    // Prepare the dictionary with request parameters
    NSDictionary *requestParams = @{
        @"client_id": globalClientID,
        @"client_secret": globalClientSecret,
        @"scope": @"http://gdata.youtube.com https://www.googleapis.com/auth/youtube-paid-content",
        @"device_id": uuidString, // Use the generated UUID
        @"device_model": @"ytlr::", // Assuming this value is static; replace as needed
        @"grant_type": @"urn:ietf:params:oauth:grant-type:device_code"
    };

    NSError *error;
    NSData *deviceCodeRequestBodyData = [NSJSONSerialization dataWithJSONObject:requestParams options:0 error:&error];
    if (error) {
        NSLog(@"Error serializing request body: %@", error.localizedDescription);
        return;
    }

    NSMutableURLRequest *deviceCodeRequest = [NSMutableURLRequest requestWithURL:deviceCodeRequestURL];
    [deviceCodeRequest setHTTPMethod:@"POST"];
    [deviceCodeRequest setHTTPBody:deviceCodeRequestBodyData];
    [deviceCodeRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    NSError *deviceCodeError;
    NSURLResponse *deviceCodeResponse;
    NSData *deviceCodeResponseData = [NSURLConnection sendSynchronousRequest:deviceCodeRequest returningResponse:&deviceCodeResponse error:&deviceCodeError];

    __block NSString *deviceCode = nil;
    __block UIAlertView *deviceCodeAlert = nil;
    
    if (!deviceCodeError && deviceCodeResponseData) {
        NSDictionary *deviceCodeResponseDict = [NSJSONSerialization JSONObjectWithData:deviceCodeResponseData options:0 error:&deviceCodeError];
        if (!deviceCodeError && deviceCodeResponseDict) {
            deviceCode = deviceCodeResponseDict[@"device_code"];
            NSString *userCode = deviceCodeResponseDict[@"user_code"];
            NSString *verificationURL = deviceCodeResponseDict[@"verification_url"];

            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *message = [NSString stringWithFormat:@"Please visit %@ and enter the code: %@, this is required In order to sign into TubeRepair securely, you only need to do this once, this message will close when verification completes or after one minute.", verificationURL, userCode];
                deviceCodeAlert = [[UIAlertView alloc] initWithTitle:@"Sign In Required" message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
                [deviceCodeAlert show];

                // Schedule the alert to be dismissed after 1 minute
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(60 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    if (deviceCodeAlert.visible) {
                        [deviceCodeAlert dismissWithClickedButtonIndex:0 animated:YES];
                    }
                });
            });

            // Move to background thread for polling
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                // Step 2: Polling for the OAuth token
                BOOL shouldContinuePolling = YES;
                NSDate *pollingEndTime = [[NSDate date] dateByAddingTimeInterval:60];

                while (shouldContinuePolling && [[NSDate date] compare:pollingEndTime] == NSOrderedAscending) {
                    [NSThread sleepForTimeInterval:5]; // Poll every 5 seconds

                    NSString *tokenRequestBodyString = [NSString stringWithFormat:@"client_id=%@&client_secret=%@&device_code=%@&grant_type=urn:ietf:params:oauth:grant-type:device_code", globalClientID, globalClientSecret, deviceCode];
                    NSData *tokenRequestBodyData = [tokenRequestBodyString dataUsingEncoding:NSUTF8StringEncoding];

                    NSMutableURLRequest *tokenRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://oauth2.googleapis.com/token"]];
                    [tokenRequest setHTTPMethod:@"POST"];
                    [tokenRequest setHTTPBody:tokenRequestBodyData];
                    [tokenRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];

                    NSError *error;
                    NSURLResponse *response;
                    NSData *tokenResponseData = [NSURLConnection sendSynchronousRequest:tokenRequest returningResponse:&response error:&error];

                    if (!error && tokenResponseData) {
                        NSDictionary *tokenResponse = [NSJSONSerialization JSONObjectWithData:tokenResponseData options:0 error:&error];
                        if (!error && tokenResponse) {
                            NSString *accessToken = tokenResponse[@"access_token"];
                            NSString *refreshToken = tokenResponse[@"refresh_token"];
                            NSNumber *expiresIn = tokenResponse[@"expires_in"];

                            if (accessToken && expiresIn) {
                                // Calculate and save the expiration date
                                NSDate *expirationDate = [[NSDate date] dateByAddingTimeInterval:[expiresIn doubleValue]];
                                NSString *settingsPath = @"/var/mobile/Library/Preferences/bag.xml.tuberepairpreference.plist";
                                NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:settingsPath];

                                [prefs setObject:accessToken forKey:@"OAuthAccessToken"];
                                [prefs setObject:expirationDate forKey:@"OAuthTokenExpirationDate"];
                                [prefs setObject:refreshToken forKey:@"OAuthRefreshToken"];
                                [prefs writeToFile:settingsPath atomically:YES];

                                // Notify the user of successful authentication and dismiss alert
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    if (deviceCodeAlert.visible) {
                                        [deviceCodeAlert dismissWithClickedButtonIndex:0 animated:YES];
                                    }
                                    UIAlertView *successAlert = [[UIAlertView alloc] initWithTitle:@"Authentication Successful" message:@"You have been successfully authenticated." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                                    [successAlert show];
                                });
                                shouldContinuePolling = NO;
                            } else if ([tokenResponse[@"error"] isEqualToString:@"authorization_pending"]) {
                                // Continue polling
                            } else {
                                // Stop polling and handle error
                                shouldContinuePolling = NO;
                                NSLog(@"Error during token polling: %@", tokenResponse[@"error"]);
                            }
                        }
                    } else {
                        // Stop polling and handle error
                        shouldContinuePolling = NO;
                        NSLog(@"Error requesting token: %@", error);
                    }
                }
            });
        }
    }
}

%end

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
        betaSetDefaultUrl();
        refreshOAuthTokenIfNeeded();
    } else if (version >= 5.0 && version < 11.0) {
        %init(Baseplate); // Baseplate is common for iOS 5.0 to 10.9
        warnAboutMissingKey();
        checkAPIKeyValidity();
        warnAboutMissingHeader();
        betaSetDefaultUrl();
        fetchYouTubeTVPageAndExtractClientID(^(BOOL success, NSString *clientID, NSString *clientSecret) {
            if (success) {
                NSLog(@"Successfully extracted client ID: %@ and secret: %@", clientID, clientSecret);
            } else {
                NSLog(@"Failed to extract client ID and secret.");
            }
        });
        if (version >= 8.0) {
            %init(iOS8); // Additional initialization for iOS 8 to 10
        }
    }
}
