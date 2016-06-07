#import <Foundation/Foundation.h>

typedef void(^BlockSuccess)(NSArray *responseArray);
typedef void(^BlockError)(NSError *error);

@interface MBDataManager : NSObject

+ (instancetype)sharedManager;
- (void)loadDataWithLatitude:(double)latitude
                   longitude:(double)longitude
                   onSuccess:(BlockSuccess)blockArray
                   onFailure:(BlockError)blockError;

@end
