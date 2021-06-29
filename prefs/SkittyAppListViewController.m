// Skitty App List - Custom AppList Alternative
// By Skitty

#import "SkittyAppListViewController.h"
#import "UIImage+Private.h"

#define BUNDLE_ID @"xyz.skitty.sushi"

CFNotificationCenterRef CFNotificationCenterGetDistributedCenter(void);

SkittyAppListViewController *controller;

static void setAppList(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	if ([(__bridge NSDictionary *)userInfo count] < 2) { // people must have at least two apps, right?
		return;
	}
	[controller recieveAppList:(__bridge NSDictionary *)userInfo];
}

static void post() {
	CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(), (CFStringRef)[BUNDLE_ID stringByAppendingString:@".getapps"], nil, nil, true);
}

@implementation SkittyAppListViewController

- (NSArray *)specifiers {
	return nil;
}

- (id)init {
	self = [super init];
	if (self) {
		self.title = @"Blacklisted Apps";

		CFNotificationCenterAddObserver(CFNotificationCenterGetDistributedCenter(), NULL, setAppList, (CFStringRef)[BUNDLE_ID stringByAppendingString:@".setapps"], nil, CFNotificationSuspensionBehaviorDeliverImmediately);

		[self getAppList];
		
		NSString *prefPath = [NSString stringWithFormat:@"/var/mobile/Library/Preferences/%@.apps.plist", BUNDLE_ID];
		NSMutableDictionary *prefs = [NSMutableDictionary dictionaryWithContentsOfFile:prefPath];
		NSArray *apps = @[];
		if ([[NSFileManager defaultManager] fileExistsAtPath:prefPath]) apps = [prefs objectForKey:@"Enabled"];
		self.preferencesAppList = apps;
		
		self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
		self.searchController.dimsBackgroundDuringPresentation = NO;
		self.searchController.delegate = self;
		self.searchController.searchBar.delegate = self;
		self.searchController.searchBar.placeholder = @"Search";

		self.navigationItem.searchController = self.searchController;
		self.navigationItem.hidesSearchBarWhenScrolling = NO; // unfortunatly, this is required.

		self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
		self.tableView.delegate = self;
		self.tableView.dataSource = self;
		[self.view addSubview:self.tableView];

		// This is probably a terrible way to do it.
		controller = self;
	}
	return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];
}

// Preferences
- (void)updatePreferencesAppList {
	NSString *prefPath = [NSString stringWithFormat:@"/var/mobile/Library/Preferences/%@.apps.plist", BUNDLE_ID];
	NSDictionary *preferencesDict = @{ @"Enabled": self.preferencesAppList };
	[preferencesDict writeToFile:prefPath atomically:YES];
}

- (void)updateSwitch:(UISwitch *)appSwitch {
	NSString *tag = [NSString stringWithFormat:@"%ld", (long)appSwitch.tag];
	NSInteger section = [[tag substringToIndex:1] intValue] - 1;
	NSInteger row = [[tag substringFromIndex:1] intValue];
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
	UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
	BOOL on = [(UISwitch *)cell.accessoryView isOn];

	NSString *bundleIdentifier = self.identifiers[indexPath.row];

	NSMutableArray *list = [self.preferencesAppList mutableCopy];
	if (on) [list addObject:bundleIdentifier];
	else [list removeObject:bundleIdentifier];

	self.preferencesAppList = list;
	[self updatePreferencesAppList];
}

// App List
- (void)getAppList {
	if (self.appList.count == 0) {
		self.appList = @{@"Loading!": @"Loading..."};
	}
	
	post();
}

- (void)recieveAppList:(NSDictionary *)appList {
	if ([appList count] < 2) {
		return;
	}
	self.fullAppList = appList;
	[self updateAppList:appList];
}

- (void)updateAppList:(NSDictionary *)appList {
	NSArray *ids = [appList keysSortedByValueUsingComparator:^(NSString *obj1, NSString *obj2) {
		return [obj1 compare:obj2];
	}];

	self.appList = appList;
	self.identifiers = ids;

	[self.tableView reloadData];
}

// Table View
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SkittyAppCell"];
	if (!cell) {
		cell = [[UITableViewCell alloc] initWithStyle:3 reuseIdentifier:@"SkittyAppCell"];
	}
	
	UISwitch *appSwitch = [[UISwitch alloc] init];
	appSwitch.tag = [[NSString stringWithFormat:@"%ld%ld", (long)indexPath.section + 1, (long)indexPath.row] intValue];
	[appSwitch addTarget:self action:@selector(updateSwitch:) forControlEvents:UIControlEventPrimaryActionTriggered];
	[cell setAccessoryView:appSwitch];
	
	cell.detailTextLabel.textColor = [UIColor grayColor];
	
	if ([self.preferencesAppList containsObject:self.identifiers[indexPath.row]]) {
		[appSwitch setOn:YES animated:NO];
	}

	cell.textLabel.text = [self.fullAppList objectForKey:self.identifiers[indexPath.row]];
	// cell.detailTextLabel.text = self.identifiers[indexPath.row];
	
	cell.imageView.image = [UIImage _applicationIconImageForBundleIdentifier:self.identifiers[indexPath.row] format:0 scale:[UIScreen mainScreen].scale];
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.identifiers.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return nil;
}

// Search Bar
- (void)searchWithText:(NSString *)text {
	NSDictionary *newAppList;
	if (text.length == 0) {
		newAppList = self.fullAppList;
	} else {
		NSMutableDictionary *mutableList = [[NSMutableDictionary alloc] init];
		NSArray *ids = [self.fullAppList keysSortedByValueUsingComparator:^(NSString *obj1, NSString *obj2) {
			return [obj1 compare:obj2];
		}];
		NSArray<NSString *> *names = [[self.fullAppList allValues] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
			return [obj1 compare:obj2 options:NSNumericSearch];
		}];
		for (int i = 0; i < names.count; i++) {
			if ([names[i].lowercaseString rangeOfString:text.lowercaseString].location != NSNotFound) {
				[mutableList setObject:names[i] forKey:ids[i]];
			}
		}
		newAppList = [mutableList copy];
	}
	[self updateAppList:newAppList];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)text {
	[self searchWithText:text];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
	[searchBar setShowsCancelButton:YES animated:YES];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
	[self searchWithText:searchBar.text];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
	[searchBar resignFirstResponder];
	[searchBar setShowsCancelButton:NO animated:YES];
	[self searchWithText:nil];
}

@end
