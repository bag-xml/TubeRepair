@interface ApiKeyAlertDelegate : NSObject <UIAlertViewDelegate>
@property (nonatomic, assign) BOOL shouldExit;
@end

@interface EncryptionUtility : NSObject

+ (NSString *)encryptToken:(NSString *)token;
+ (NSData *)AES256EncryptData:(NSData *)data withKey:(NSString *)key iv:(NSString *)iv;

@end

void scheduleTokenRefresh(void);