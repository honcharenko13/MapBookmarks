#import <UIKit/UIKit.h>

@class Bookmark;

@protocol MBBuildRouteDelegate <NSObject>

- (void)actionDirection:(Bookmark *)bookmark;

@end

@interface MBTableOfBookmarksViewController : UIViewController

@property (nonatomic, weak) id <MBBuildRouteDelegate> delegate;

@end
