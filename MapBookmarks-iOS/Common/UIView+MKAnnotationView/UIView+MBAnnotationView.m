#import "UIView+MBAnnotationView.h"
#import <MapKit/MKAnnotationView.h>

@implementation UIView (MBAnnotationView)

- (MKAnnotationView*)superAnnotationView {
    
    if ([self isKindOfClass:[MKAnnotationView class]]) {
        return (MKAnnotationView*)self;
    }
    
    if (!self.superview) {
        return nil;
    }
    
    return [self.superview superAnnotationView];
}

@end
