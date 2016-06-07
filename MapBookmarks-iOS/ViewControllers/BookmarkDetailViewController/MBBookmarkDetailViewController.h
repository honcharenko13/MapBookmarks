#import <UIKit/UIKit.h>
#import "Bookmark.h"
#import <MapKit/MapKit.h>

typedef void(^MBBlockForCenterAtMap)(Bookmark *bookmark);
typedef void(^MBBlockForBuildRoute)(Bookmark *bookmark);

@interface MBBookmarkDetailViewController : UIViewController

@property (strong, nonatomic) Bookmark* currentBookmark;
@property (copy, nonatomic) MBBlockForCenterAtMap centering;
@property (copy, nonatomic) MBBlockForCenterAtMap building;
@property (assign, nonatomic) BOOL isRouteMode;

@end
