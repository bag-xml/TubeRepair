// Global variables for Client ID and Secret
extern NSString *globalClientID;
extern NSString *globalClientSecret;

// Function declarations
void extractClientIDAndSecretFromScript(NSString *scriptContent, void(^completion)(BOOL success, NSString *clientID, NSString *clientSecret));
void fetchYouTubeTVPageAndExtractClientID(void(^completion)(BOOL success, NSString *clientID, NSString *clientSecret));
void refreshOAuthTokenIfNeeded(void);
void scheduleTokenRefresh(void);
void addCustomHeaderToRequest(NSMutableURLRequest *request);
void betaSetDefaultUrl(void);
