#import "MBTableOfBookmarksViewController.h"
#import <CoreData/CoreData.h>
#import "AppDelegate.h"
#import "Bookmark.h"
#import "MBCustomCell.h"

@interface MBTableOfBookmarksViewController () <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end

@implementation MBTableOfBookmarksViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.managedObjectContext = [(AppDelegate *)[[UIApplication sharedApplication]
                                                 delegate] managedObjectContext];
    self.fetchedResultsController = [Bookmark fetchwithDelegate:self andContext:self.managedObjectContext];
    self.tableView.delegate = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
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
    cell.popoverTableLabel.text = object.title;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Bookmark *object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [self.delegate actionDirection:object];
}

@end
