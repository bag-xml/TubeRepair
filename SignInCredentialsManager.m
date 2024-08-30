#import "TubeRepair.h"

NSString *globalClientID = @"Hello";
NSString *globalClientSecret = @"Hello";

// Add custom headers to requests, this is used to add the auth token to allow for custom feeds and such.
void addCustomHeaderToRequest(NSMutableURLRequest *request) {
    NSString *settingsPath = @"/var/mobile/Library/Preferences/bag.xml.tuberepairpreference.plist";
    NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:settingsPath];
    NSString *headerName = [prefs objectForKey:@"apiKeyRHeader"];
    NSString *apiKey = [prefs objectForKey:@"apiKey"];
    NSString *oAuthToken = [prefs objectForKey:@"OAuthAccessToken"];
    
    if (headerName && [headerName length] > 0 && apiKey && [apiKey length] > 0) {
        [request setValue:apiKey forHTTPHeaderField:headerName];
    }
    
    if (oAuthToken && [oAuthToken length] > 0) {
        [request setValue:oAuthToken forHTTPHeaderField:@"OAuth-Token"];
    }
}

// Extract Client ID and Secret from script content using regex
void extractClientIDAndSecretFromScript(NSString *scriptContent, void(^completion)(BOOL success, NSString *clientID, NSString *clientSecret)) {
    NSError *regexError = nil;

    // Regex to capture client_id:"value"
    NSRegularExpression *clientIdRegex = [NSRegularExpression regularExpressionWithPattern:@"client_id:\"([^\"]+)\"" options:NSRegularExpressionCaseInsensitive error:&regexError];
    // Regex to capture client_secret:"value"
    NSRegularExpression *clientSecretRegex = [NSRegularExpression regularExpressionWithPattern:@"client_secret:\"([^\"]+)\"" options:NSRegularExpressionCaseInsensitive error:&regexError];
    
    // Check for regex creation errors
    if (regexError) {
        NSLog(@"Regex error: %@", regexError.localizedDescription);
        completion(NO, nil, nil);
        return;
    }

    // Match client_id
    NSTextCheckingResult *clientIdMatch = [clientIdRegex firstMatchInString:scriptContent options:0 range:NSMakeRange(0, scriptContent.length)];
    // Match client_secret
    NSTextCheckingResult *clientSecretMatch = [clientSecretRegex firstMatchInString:scriptContent options:0 range:NSMakeRange(0, scriptContent.length)];

    // Check if both matches were found
    if (clientIdMatch && clientSecretMatch) {
        NSString *clientId = [scriptContent substringWithRange:[clientIdMatch rangeAtIndex:1]];
        NSString *clientSecret = [scriptContent substringWithRange:[clientSecretMatch rangeAtIndex:1]];
        globalClientID = clientId;
        globalClientSecret = clientSecret;
        completion(YES, clientId, clientSecret);
    } else {
        NSLog(@"Failed to extract client ID and/or secret.");
        completion(NO, nil, nil);
    }
}

// Fetch YouTube TV page and extract the Client ID and Secret
void fetchYouTubeTVPageAndExtractClientID(void(^completion)(BOOL success, NSString *clientID, NSString *clientSecret)) {
    NSURL *url = [NSURL URLWithString:@"https://www.youtube.com/tv"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    [request setValue:@"*/*" forHTTPHeaderField:@"Accept"];
    [request setValue:@"https://www.youtube.com" forHTTPHeaderField:@"Origin"];
    [request setValue:@"SMART-TV; Tizen 4.0" forHTTPHeaderField:@"User-Agent"];
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
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"<script id=\"base-js\" src=\"(.*?)\" nonce=\".*?\"><\\/script>" options:NSRegularExpressionCaseInsensitive error:nil];
        NSTextCheckingResult *match = [regex firstMatchInString:htmlContent options:0 range:NSMakeRange(0, htmlContent.length)];
        
        if (match) {
            NSString *relativeScriptUrl = [htmlContent substringWithRange:[match rangeAtIndex:1]];
            NSURL *fullScriptUrl = [NSURL URLWithString:relativeScriptUrl relativeToURL:[NSURL URLWithString:@"https://www.youtube.com"]];
            
            NSMutableURLRequest *scriptRequest = [NSMutableURLRequest requestWithURL:fullScriptUrl];
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
                extractClientIDAndSecretFromScript(scriptContent, completion);
            }];
        } else {
            NSLog(@"Failed to find script URL in YouTube TV page.");
            completion(NO, nil, nil);
        }
    }];
}

// Refresh OAuth token if needed
// Refresh OAuth token if needed
void refreshOAuthTokenIfNeeded(void) {
    NSString *settingsPath = @"/var/mobile/Library/Preferences/bag.xml.tuberepairpreference.plist";
    NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:settingsPath];
    NSString *accessToken = [prefs objectForKey:@"OAuthAccessToken"];
    NSDate *tokenExpirationDate = [prefs objectForKey:@"OAuthTokenExpirationDate"];
    NSString *refreshToken = [prefs objectForKey:@"OAuthRefreshToken"];
    
    // Check if token needs to be refreshed
    if (accessToken && refreshToken && (!tokenExpirationDate || [tokenExpirationDate compare:[NSDate date]] != NSOrderedDescending)) {
        NSString *tokenRequestBodyString = [NSString stringWithFormat:@"client_id=%@&client_secret=%@&refresh_token=%@&grant_type=refresh_token", globalClientID, globalClientSecret, refreshToken];
        NSData *tokenRequestBodyData = [tokenRequestBodyString dataUsingEncoding:NSUTF8StringEncoding];
        
        NSMutableURLRequest *tokenRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://oauth2.googleapis.com/token"]];
        [tokenRequest setHTTPMethod:@"POST"];
        [tokenRequest setHTTPBody:tokenRequestBodyData];
        [tokenRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        
        NSURLResponse *response;
        NSError *error;
        NSData *tokenResponseData = [NSURLConnection sendSynchronousRequest:tokenRequest returningResponse:&response error:&error];
        
        if (!error && tokenResponseData) {
            NSDictionary *tokenResponse = [NSJSONSerialization JSONObjectWithData:tokenResponseData options:0 error:&error];
            if (!error && tokenResponse) {
                NSString *newAccessToken = tokenResponse[@"access_token"];
                NSNumber *expiresIn = tokenResponse[@"expires_in"];
                NSString *newRefreshToken = tokenResponse[@"refresh_token"]; // Some servers might return a new refresh token
                
                if (newAccessToken && expiresIn) {
                    NSDate *newExpirationDate = [[NSDate date] dateByAddingTimeInterval:[expiresIn doubleValue]];
                    [prefs setObject:newAccessToken forKey:@"OAuthAccessToken"];
                    [prefs setObject:newExpirationDate forKey:@"OAuthTokenExpirationDate"];
                    
                    // Only update the refresh token if a new one is provided
                    if (newRefreshToken) {
                        [prefs setObject:newRefreshToken forKey:@"OAuthRefreshToken"];
                        NSLog(@"Updated refresh token: %@", newRefreshToken);
                    } else {
                        NSLog(@"No new refresh token provided, retaining the existing one.");
                    }
                    
                    [prefs writeToFile:settingsPath atomically:YES];
                    NSLog(@"Successfully refreshed access token.");
                } else {
                    NSLog(@"Failed to parse access token or expiration time from response.");
                }
            } else {
                NSLog(@"Failed to refresh token: %@", error.localizedDescription);
            }
        } else {
            NSLog(@"Error making refresh token request: %@", error.localizedDescription);
        }
    } else {
        NSLog(@"No need to refresh the token yet.");
    }
}

// Schedule token refresh before expiration
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