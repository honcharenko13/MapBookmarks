#import "MBMainViewController.h"
#import <MapKit/MapKit.h>
#import "Bookmark.h"
#import "AppDelegate.h"
#import "UIView+MBAnnotationView.h"
#import "WYPopoverController.h"
#import "MBTableOfBookmarksViewController.h"
#import "MBBookmarksListViewController.h"
#import "MBBookmarkDetailViewController.h"

@interface MBMainViewController () <MKMapViewDelegate, WYPopoverControllerDelegate, MBBuildRouteDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *routeButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *bookmarksButton;

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) CLLocationManager  *locationManager;
@property (strong, nonatomic) MKDirections *directions;
@property (strong, nonatomic) WYPopoverController *bookmarksPopoverController;
@property (assign, nonatomic) BOOL isShowingRoute;
@property (assign, nonatomic) BOOL isShowingCurrentLocation;
@property (assign, nonatomic) BOOL isRiding;
@property (strong, nonatomic) Bookmark *currentBookmark;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

@end

@implementation MBMainViewController

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.isShowingRoute = NO;
    self.isShowingCurrentLocation = YES;
    self.isRiding = NO;
    self.managedObjectContext = [(AppDelegate *)[[UIApplication sharedApplication]
                                                 delegate] managedObjectContext];
    self.fetchedResultsController = [Bookmark fetchwithDelegate:self andContext:self.managedObjectContext];
    self.mapView.showsUserLocation = YES;
    self.mapView.showsBuildings = YES;
    self.mapView.delegate = self;
    self.locationManager = [CLLocationManager new];
    if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    [self loadAllBookmarksToMap];
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                                   action:@selector(handleLongPressGesture:)];
    [self.mapView addGestureRecognizer:longPressGesture];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    
    if (self.fetchedResultsController.fetchedObjects.count == 0) {
        self.routeButton.enabled = NO;
    }
}

#pragma mark - MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
    }
    static NSString* identifier = @"Annotation";
    MKPinAnnotationView* pin = (MKPinAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
    if (!pin) {
        pin = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
        pin.pinTintColor = [MKPinAnnotationView purplePinColor];
        pin.animatesDrop = YES;
        pin.canShowCallout = YES;
        pin.canShowCallout = YES;
        UIButton* detailButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        pin.leftCalloutAccessoryView = detailButton;
    } else {
        pin.annotation = annotation;
        if (self.isShowingRoute && annotation.coordinate.latitude !=
            self.currentBookmark.latitude.doubleValue) {
            pin.hidden = YES;
        }
    }
    return pin;
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view
calloutAccessoryControlTapped:(UIControl *)control {
    if ([view.annotation isKindOfClass:[MKUserLocation class]]) {
        return;
    }
    Bookmark *bookmarkAnnotation = (Bookmark *)view.annotation;
    NSNumber *latitude = [NSNumber numberWithDouble:bookmarkAnnotation.coordinate.latitude];
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Bookmark"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"latitude == %@", latitude];
    [fetchRequest setPredicate:predicate];
    NSError *error = nil;
    NSArray *results = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (!results) {
        NSLog(@"Error fetching Employee objects: %@\n%@", [error localizedDescription], [error userInfo]);
        abort();
    }
    Bookmark *selectedBookmark = results[0];
    [self performSegueWithIdentifier:@"DetailIdentifier" sender:selectedBookmark];
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
    if (self.isShowingRoute) {
        self.isRiding = YES;
        [self actionDirection:self.currentBookmark];
        return;
    }
    if (self.isShowingCurrentLocation) {
        MKMapCamera *camera = [MKMapCamera cameraLookingAtCenterCoordinate:userLocation.coordinate
                                                         fromEyeCoordinate:CLLocationCoordinate2DMake(userLocation.coordinate.latitude,
                                                                                                      userLocation.coordinate.longitude)
                                                               eyeAltitude:10000];
        [self.mapView setCamera:camera animated:YES];
        self.isShowingCurrentLocation = NO;
    }
}

#pragma mark - Creating annotation

- (void)handleLongPressGesture:(UIGestureRecognizer *)gestureRecognizer {
    self.routeButton.enabled = YES;
    if (gestureRecognizer.state != UIGestureRecognizerStateBegan)
        return;
    CGPoint touchPoint = [gestureRecognizer locationInView:self.mapView];
    CLLocationCoordinate2D touchMapCoordinate =
    [self.mapView convertPoint:touchPoint toCoordinateFromView:self.mapView];
    Bookmark *tappedBookmark = [NSEntityDescription insertNewObjectForEntityForName:@"Bookmark"
                                                             inManagedObjectContext:self.managedObjectContext];
    
    tappedBookmark.title = @"Unnamed bookmark";
    tappedBookmark.coordinate = touchMapCoordinate;
    [self.mapView addAnnotation:tappedBookmark];
    NSError *error = nil;
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"%@", error.localizedDescription);
    }
}

#pragma mark - Load all bookmarks to map

- (void)loadAllBookmarksToMap {
    NSError *error = nil;
    NSArray *results = self.fetchedResultsController.fetchedObjects;
    if (!results) {
        NSLog(@"Error fetching Employee objects: %@\n%@", error.localizedDescription, error.userInfo);
        abort();
    }
    for (Bookmark *bookmark in results) {
        [self.mapView addAnnotation:bookmark];
    }
}

#pragma mark - Building route action

- (IBAction)buildRouteAction:(UIBarButtonItem *)sender {
    if (self.isShowingRoute) {
        self.routeButton.title = @"Route";
        self.isShowingRoute = NO;
        self.isRiding = NO;
        for (id<MKAnnotation> annotation in self.mapView.annotations) {
            if ([annotation isKindOfClass:[Bookmark class]]) {
                MKAnnotationView* anView = [self.mapView viewForAnnotation:annotation];
                anView.hidden = NO;
            }
        }
        [self.mapView removeOverlays:self.mapView.overlays];
        self.bookmarksButton.enabled = YES;
    } else {
        UIBarButtonItem *button = sender;
        MBTableOfBookmarksViewController  *tableBookmarksViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"MBTableOfBookmarksViewController"];
        tableBookmarksViewController.preferredContentSize = CGSizeMake(320, 280);
        tableBookmarksViewController.title = @"Bookmarks";
        tableBookmarksViewController.modalInPopover = NO;
        tableBookmarksViewController.delegate = self;
        UINavigationController *contentViewController = [[UINavigationController alloc] initWithRootViewController:tableBookmarksViewController];
        self.bookmarksPopoverController = [[WYPopoverController alloc] initWithContentViewController:contentViewController];
        self.bookmarksPopoverController.delegate = self;
        self.bookmarksPopoverController.passthroughViews = @[button];
        self.bookmarksPopoverController.popoverLayoutMargins = UIEdgeInsetsMake(10, 10, 10, 10);
        self.bookmarksPopoverController.wantsDefaultContentAppearance = NO;
        [self.bookmarksPopoverController presentPopoverFromBarButtonItem:button
                                                permittedArrowDirections:WYPopoverArrowDirectionDown
                                                                animated:YES
                                                                 options:WYPopoverAnimationOptionFadeWithScale];
    }
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id <MKOverlay>)overlay {
    self.bookmarksButton.enabled = NO;
    self.isShowingRoute = YES;
    self.routeButton.title = @"Clear route";
    if ([overlay isKindOfClass:[MKPolyline class]]) {
        MKPolylineRenderer* renderer = [[MKPolylineRenderer alloc] initWithOverlay:overlay];
        renderer.lineWidth = 2.f;
        renderer.strokeColor = [UIColor colorWithRed:0.f green:0.5f blue:1.f alpha:0.9f];
        [self.bookmarksPopoverController dismissPopoverAnimated:YES];
        return renderer;
    }
    return nil;
}

#pragma mark - WYPopoverControllerDelegate

- (void)popoverControllerDidPresentPopover:(WYPopoverController *)controller {
    NSLog(@"popoverControllerDidPresentPopover");
}

- (BOOL)popoverControllerShouldDismissPopover:(WYPopoverController *)controller {
    return YES;
}

- (void)popoverControllerDidDismissPopover:(WYPopoverController *)controller {
    if (controller == self.bookmarksPopoverController) {
        self.bookmarksPopoverController.delegate = nil;
        self.bookmarksPopoverController = nil;
    }
}

- (BOOL)popoverControllerShouldIgnoreKeyboardBounds:(WYPopoverController *)popoverController {
    return YES;
}

- (void)popoverController:(WYPopoverController *)popoverController willTranslatePopoverWithYOffset:(float *)value {
    *value = 0;
}

- (void)close:(id)sender {
    [self.bookmarksPopoverController dismissPopoverAnimated:YES completion:^{
        [self popoverControllerDidDismissPopover:self.bookmarksPopoverController];
    }];
}

#pragma mark - MBBuildRouteDelegate

- (void)actionDirection:(Bookmark*)bookmark {
    self.currentBookmark = bookmark;
    if (!bookmark) {
        return;
    }
    if ([self.directions isCalculating]) {
        [self.directions cancel];
    }
    CLLocationDegrees latitude = bookmark.latitude.doubleValue;
    CLLocationDegrees longitude = bookmark.longitude.doubleValue;
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(latitude, longitude);
    for (id<MKAnnotation> annotation in self.mapView.annotations) {
        if ([annotation isKindOfClass:[Bookmark class]] &&
            annotation.coordinate.latitude != coordinate.latitude) {
            MKAnnotationView* anView = [self.mapView viewForAnnotation:annotation];
            anView.hidden = YES;
        }
    }
    MKDirectionsRequest* request = [[MKDirectionsRequest alloc] init];
    request.source = [MKMapItem mapItemForCurrentLocation];
    MKPlacemark* placemark = [[MKPlacemark alloc] initWithCoordinate:coordinate
                                                   addressDictionary:nil];
    MKMapItem* destination = [[MKMapItem alloc] initWithPlacemark:placemark];
    request.destination = destination;
    request.transportType = MKDirectionsTransportTypeAutomobile;
    request.requestsAlternateRoutes = NO;
    self.directions = [[MKDirections alloc] initWithRequest:request];
    [self.directions calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {
        if (error) {
            [self showAlertWithMessage:[error localizedDescription]];
        } else if ([response.routes count] == 0) {
            [self showAlertWithMessage:@"No routes found"];
        } else {
            [self.mapView removeOverlays:[self.mapView overlays]];
            NSMutableArray* array = [NSMutableArray array];
            for (MKRoute* route in response.routes) {
                [array addObject:route.polyline];
                if (!self.isRiding) {
                    [self showAllRoute:self.mapView polyline:route.polyline animated:YES];
                }
            }
            [self.mapView addOverlays:array level:MKOverlayLevelAboveRoads];
        }
    }];
}

- (void)showAllRoute:(MKMapView *)map polyline:(MKPolyline*)polyline animated: (BOOL)animated {
    [map setVisibleMapRect:[polyline boundingMapRect] edgePadding:UIEdgeInsetsMake(30, 30, 30, 30) animated:animated];
}

- (void)showAlertWithMessage:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *OkAction = [UIAlertAction
                               actionWithTitle:@"OK"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction *action) {}];
    [alert addAction:OkAction];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Show pin at center of map

- (void)centerAtMapWithLatitude:(double)latitude withLongitude:(double)longitude {
    MKMapCamera* camera = [MKMapCamera cameraLookingAtCenterCoordinate:CLLocationCoordinate2DMake(latitude, longitude)
                                                     fromEyeCoordinate:CLLocationCoordinate2DMake(latitude,
                                                                                                  longitude)
                                                           eyeAltitude:kCLLocationAccuracyThreeKilometers];
    [self.mapView setCamera:camera animated:YES];
}

#pragma mark - NSFetchedResultsController

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [self.mapView reloadInputViews];
}


- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(Bookmark *)bookmark
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [self fetchedResultsChangeInsert:bookmark];
            break;
        case NSFetchedResultsChangeDelete:
            [self fetchedResultsChangeDelete:bookmark];
            break;
        case NSFetchedResultsChangeUpdate:
            break;
        case NSFetchedResultsChangeMove:
            break;
        default:
            break;
    }
}

- (void)fetchedResultsChangeInsert:(Bookmark *)bookmark {
    [self.mapView addAnnotation:bookmark];
}

- (void)fetchedResultsChangeDelete:(Bookmark *)bookmark {
    [self.mapView removeAnnotation:bookmark];
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(Bookmark *)sender {
    if ([segue.identifier isEqualToString:@"listIdentifier"]) {
        MBBookmarksListViewController *controller = segue.destinationViewController;
        controller.centering = ^(Bookmark *currentBookmark) {
            [self centerAtMapWithLatitude:currentBookmark.coordinate.latitude
                            withLongitude:currentBookmark.coordinate.longitude];
            [self.bookmarksPopoverController dismissPopoverAnimated:YES];
        };
        controller.building = ^(Bookmark *currentBookmark) {
            [self actionDirection:currentBookmark];
            self.currentBookmark = currentBookmark;
        };
    }
    if ([segue.identifier isEqualToString:@"DetailIdentifier"]) {
        MBBookmarkDetailViewController *controller = segue.destinationViewController;
        if (self.isShowingRoute) {
            controller.isRouteMode = YES;
        }
        [controller setCurrentBookmark:sender];
        controller.centering = ^(Bookmark *currentBookmark) {
            [self centerAtMapWithLatitude:currentBookmark.coordinate.latitude
                            withLongitude:currentBookmark.coordinate.longitude];
            [self.bookmarksPopoverController dismissPopoverAnimated:YES];
        };
        controller.building = ^(Bookmark *currentBookmark) {
            [self actionDirection:currentBookmark];
            self.currentBookmark = currentBookmark;
        };
    }
}

- (IBAction)unwindToMainViewController:(UIStoryboardSegue *)unwindSegue {
    
}

@end
