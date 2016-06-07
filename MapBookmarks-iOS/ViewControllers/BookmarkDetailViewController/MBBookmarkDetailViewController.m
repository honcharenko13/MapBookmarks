#import "MBDataManager.h"
#import "MBBookmarkDetailViewController.h"
#import "SVProgressHUD.h"
#import "MBCustomCell.h"
#import "MBParsedBookmark.h"
#import <CoreData/CoreData.h>
#import "AppDelegate.h"
#import <CoreData/CoreData.h>
#import "MBMainViewController.h"

@interface MBBookmarkDetailViewController () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIButton *loadPlacesButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *trashButton;
@property (weak, nonatomic) IBOutlet UIButton *buildRouteButton;

@property (strong, nonatomic) NSMutableArray *arrayOfPlaces;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end

@implementation MBBookmarkDetailViewController

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self getDataFromServer];
    [self configureView];
}

- (void)setDetailItem:(Bookmark *)bookmark {
    if (_currentBookmark != bookmark) {
        _currentBookmark = bookmark;
    }
}

- (void)configureView {
    if (self.currentBookmark) {
        self.managedObjectContext = [(AppDelegate *)[[UIApplication sharedApplication]
                                                     delegate] managedObjectContext];
        self.fetchedResultsController = [Bookmark fetchwithDelegate:self andContext:self.managedObjectContext];
        self.arrayOfPlaces = [NSMutableArray new];
        self.nameLabel.text = self.currentBookmark.title;
        self.tableView.hidden = YES;
        NSLog(@"%@", self.currentBookmark.title);
        if([self.currentBookmark.title  isEqual: @"Unnamed bookmark"]) {
            self.tableView.hidden = NO;
            self.loadPlacesButton.hidden = YES;
        }
        if (self.isRouteMode) {
            self.trashButton.enabled = NO;
            self.buildRouteButton.enabled = NO;
        }
    }
}

#pragma mark - Load data from server

- (void)getDataFromServer {
    [SVProgressHUD show];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[MBDataManager sharedManager] loadDataWithLatitude:self.currentBookmark.latitude.doubleValue
                                                  longitude:self.currentBookmark.longitude.doubleValue
                                                  onSuccess:^(NSArray *responseArray) {
            [self.arrayOfPlaces addObjectsFromArray:responseArray];
            [self.tableView reloadData];
        } onFailure:^(NSError *error) {
            if(error) {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Network unavailable"
                                                                               message:@"It is impossible to load nearby places"
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *OkAction = [UIAlertAction actionWithTitle:@"OK"
                                                                   style:UIAlertActionStyleDefault
                                                                 handler:^(UIAlertAction *action) {}];
                [alert addAction:OkAction];
                [self presentViewController:alert animated:YES completion:nil];
            }
        }];
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
            [self.tableView reloadData];
        });
    });
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.arrayOfPlaces.count;
}

- (MBCustomCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MBCustomCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (void)configureCell:(MBCustomCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    MBParsedBookmark *object = self.arrayOfPlaces[indexPath.row];
    cell.namePlacesLabel.text = object.name;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MBParsedBookmark *parsedBookmark = self.arrayOfPlaces[indexPath.row];
    NSError *error = nil;
    self.currentBookmark.title = parsedBookmark.name;
    self.currentBookmark.coordinate = CLLocationCoordinate2DMake(parsedBookmark.latitude, parsedBookmark.longitude);
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"Unresolved error %@, %@", error, error.userInfo);
        abort();
    }
    [self.arrayOfPlaces removeObjectAtIndex:indexPath.row];
    [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    self.nameLabel.text = parsedBookmark.name;
    self.tableView.hidden = YES;
    self.loadPlacesButton.hidden = NO;
}

#pragma mark - Actions

- (IBAction)trashAction:(id)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Confirmation"
                                                                   message:@"Are you sure you want to remove bookmark?"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *OkAction = [UIAlertAction
                               actionWithTitle:@"OK"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction *action) {
                                   [self.managedObjectContext deleteObject:self.currentBookmark];
                                   NSError *error = nil;
                                   if(![self.managedObjectContext save:&error]) {
                                       NSLog(@"%@", error.localizedDescription);
                                   }
                                   [self.navigationController popViewControllerAnimated:YES];
                               }];
    UIAlertAction* cancel = [UIAlertAction
                             actionWithTitle:@"Cancel"
                             style:UIAlertActionStyleDefault
                             handler:^(UIAlertAction * action) {
                                 [alert dismissViewControllerAnimated:YES completion:nil];
                                 
                             }];
    [alert addAction:OkAction];
    [alert addAction:cancel];
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)loadPlacesAction:(id)sender {
    self.loadPlacesButton.hidden = YES;
    self.tableView.hidden = NO;
    if (self.isRouteMode) {
        self.building(self.currentBookmark);
    }
}

- (IBAction)showBookmarkCenterMap:(id)sender {
    self.centering(self.currentBookmark);
}

- (IBAction)buildRouteToBookmark:(id)sender {
    self.building(self.currentBookmark);
}
    
@end
