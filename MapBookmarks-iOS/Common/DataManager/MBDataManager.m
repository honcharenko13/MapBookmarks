#import "AFNetworking.h"
#import "MBDataManager.h"
#import "MBParsedBookmark.h"

NSString *const stringURL = @"https://api.foursquare.com/v2/venues/search?ll=";

@implementation MBDataManager

#pragma mark - Lifecycle

+ (instancetype)sharedManager {
    static id sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

#pragma mark - Loading data from sever

- (void)loadDataWithLatitude:(double)latitude
                   longitude:(double)longitude
                   onSuccess:(BlockSuccess)blockArray
                   onFailure:(BlockError)blockError{
    BlockSuccess copyBlockSuccess = [blockArray copy];
    BlockError copyBlockError = [blockError copy];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    NSString *string = [NSString stringWithFormat:@"%@%f,%f&oauth_token=I0NS5H0S5LHDWZPW0Z5NU31ZVV1IOJLFKJMRFXYT4YGETTRB&v=20160324",
                        stringURL, latitude, longitude];
    [manager GET:string parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
        NSMutableArray *arrayPlaces = [NSMutableArray array];
        NSDictionary *venues = responseObject[@"response"];
        NSArray *arrayVenues = venues[@"venues"];
        for(NSDictionary *dictionary in arrayVenues) {
            MBParsedBookmark *parsedBookmark = [MBParsedBookmark new];
            parsedBookmark.name = dictionary[@"name"];
            NSDictionary *location = dictionary[@"location"];
            parsedBookmark.latitude = [location[@"lat"] doubleValue];
            parsedBookmark.longitude = [location[@"lng"] doubleValue];
            [arrayPlaces addObject:parsedBookmark];
        }
        copyBlockSuccess(arrayPlaces);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        copyBlockError(error);
    }];
}

@end
