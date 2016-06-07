#import "Bookmark.h"

@implementation Bookmark

@synthesize coordinate = _coordinate;

#pragma mark - FetchedResultsController

+ (NSFetchedResultsController *)fetchwithDelegate:(id)delegate
                                       andContext:(NSManagedObjectContext *)context {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Bookmark" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES];
    [fetchRequest setSortDescriptors:@[sortDescriptor]];
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                                managedObjectContext:context
                                                                                                  sectionNameKeyPath:nil
                                                                                                           cacheName:nil];
    aFetchedResultsController.delegate = delegate;
    NSError *error = nil;
    if (![aFetchedResultsController performFetch:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    return aFetchedResultsController;
}

#pragma mark - Custom Accessors

- (CLLocationCoordinate2D)coordinate {
    CLLocationCoordinate2D location = CLLocationCoordinate2DMake(self.latitude.doubleValue, self.longitude.doubleValue);
    return location;
}

- (void)setCoordinate:(CLLocationCoordinate2D)coordinate {
    self.latitude = @(coordinate.latitude);
    self.longitude = @(coordinate.longitude);
    _coordinate = coordinate;
}

@end
