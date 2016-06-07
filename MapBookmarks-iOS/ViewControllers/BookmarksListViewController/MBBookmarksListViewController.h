#import <CoreData/CoreData.h>
#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

typedef void(^MBBlockForCenterAtMap)(Bookmark *bookmark);
typedef void(^MBBlockForBuildRoute)(Bookmark *bookmark);

@interface MBBookmarksListViewController : UIViewController

@property (copy, nonatomic) MBBlockForCenterAtMap centering;
@property (copy, nonatomic) MBBlockForCenterAtMap building;

@end