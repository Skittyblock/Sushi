// SkittyAppListViewController.h

#import <Preferences/PSViewController.h>
#import <UIKit/UIKit.h>

@interface SkittyAppListViewController : PSViewController <UITableViewDelegate, UITableViewDataSource, UISearchControllerDelegate, UISearchBarDelegate>

@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) UISearchController *searchController;
@property (nonatomic, retain) NSDictionary *fullAppList;
@property (nonatomic, retain) NSDictionary *appList;
@property (nonatomic, retain) NSArray *preferencesAppList;
@property (nonatomic, retain) NSArray *supportedIdentifiers;
@property (nonatomic, retain) NSArray *unsupportedIdentifiers;
@property (nonatomic, retain) NSArray *identifiers;
@property (nonatomic, retain) NSArray *supportedApps;

- (void)recieveAppList:(NSDictionary *)appList;

@end
