#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <MapKit/MapKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface Bookmark : NSManagedObject <MKAnnotation>

@property (nonatomic, assign) CLLocationCoordinate2D coordinate;

+ (NSFetchedResultsController *)fetchwithDelegate:(id)delegate
                                       andContext:(NSManagedObjectContext *)context;

@end

NS_ASSUME_NONNULL_END

#import "Bookmark+CoreDataProperties.h"
