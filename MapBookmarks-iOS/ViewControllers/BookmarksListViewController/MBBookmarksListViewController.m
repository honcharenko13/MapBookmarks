#import "Bookmark.h"
#import "MBBookmarksListViewController.h"
#import "AppDelegate.h"
#import "MBCustomCell.h"
#import "MBBookmarkDetailViewController.h"
#import "MBMainViewController.h"

@interface MBBookmarksListViewController () <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *editButton;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (assign, nonatomic) BOOL canEdit;
@property (strong, nonatomic) NSMutableArray *tempArray;

@end

@implementation MBBookmarksListViewController

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.managedObjectContext = [(AppDelegate *)[[UIApplication sharedApplication]
                                                 delegate] managedObjectContext];
    self.fetchedResultsController = [Bookmark fetchwithDelegate:self andContext:self.managedObjectContext];
    self.canEdit = NO;
    self.tempArray = [NSMutableArray new];
    if (self.fetchedResultsController.fetchedObjects.count == 0) {
        self.editButton.enabled = NO;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:YES];
    
    if(self.canEdit) {
        for (Bookmark *bookmark in self.tempArray) {
            Bookmark *current = [NSEntityDescription insertNewObjectForEntityForName:@"Bookmark"
                                                              inManagedObjectContext:self.managedObjectContext];
            current.title = bookmark.title;
            current.coordinate = bookmark.coordinate;
        }
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.fetchedResultsController.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = self.fetchedResultsController.sections[section];
    return sectionInfo.numberOfObjects;
}

- (MBCustomCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MBCustomCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (void)configureCell:(MBCustomCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    Bookmark *object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.titleLabel.text = object.title;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return self.canEdit;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.tempArray addObject:[self.fetchedResultsController objectAtIndexPath:indexPath]];
        [self.managedObjectContext deleteObject:[self.fetchedResultsController objectAtIndexPath:indexPath]];
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                          withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                          withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        default:
            return;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    UITableView *tableView = self.tableView;
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];
}

#pragma mark - Actions

- (IBAction)editAction:(UIBarButtonItem *)sender {
    if (self.canEdit) {
        sender.title = @"Edit";
        [(UIBarButtonItem *)sender setTitle:@"Edit"];
        self.canEdit = NO;
        self.tableView.editing = NO;
        NSError *error = nil;
        if(![self.managedObjectContext save:&error]) {
            NSLog(@"%@", error.localizedDescription);
        }
        if (self.fetchedResultsController.fetchedObjects.count == 0) {
            self.editButton.enabled = NO;
        }
    } else {
        sender.title = @"Done";
        [(UIBarButtonItem *)sender setTitle:@"Done"];
        self.canEdit = YES;
        self.tableView.editing = YES;
        
    }
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"detailIdentifier"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        Bookmark *current = [self.fetchedResultsController objectAtIndexPath:indexPath];
        MBBookmarkDetailViewController *controller = segue.destinationViewController;
        [controller setCurrentBookmark:current];
        controller.centering = ^(Bookmark *currentBookmark) {
            self.centering(currentBookmark);
        };
        controller.building = ^(Bookmark *currentBookmark) {
            self.building(currentBookmark);
        };
    }
}

@end
