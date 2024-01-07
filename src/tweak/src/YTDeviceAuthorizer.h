@interface YTDeviceAuthorizer : NSObject

@property (nonatomic, strong) NSString *_developerKey;
@property (nonatomic, strong) NSString *_serialNumber;

- (id)fetcherWithRequest:(NSURLRequest *)request;
- (void)performRequestQueueWithError:(NSError *)error;

@end
