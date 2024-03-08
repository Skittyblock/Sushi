// Sushi, by Skitty
// Now playing banner with integrated media controls

#import <MediaRemote/MediaRemote.h>
#import "SUNowPlayingManager.h"
#import "SUNowPlayingWindow.h"
#import "SUNowPlayingViewController.h"
#import "SBApplication.h"
#import "SBApplicationController.h"
#import "SBLockScreenManager.h"
#import "SpringBoard+Sushi.h"
#import <rootless.h>

#define BUNDLE_ID @"xyz.skitty.sushi"

CFNotificationCenterRef CFNotificationCenterGetDistributedCenter(void);

typedef void (^MRMediaRemoteGetNowPlayingClientBlock)(id client);
void MRMediaRemoteGetNowPlayingClient(dispatch_queue_t queue, MRMediaRemoteGetNowPlayingClientBlock block);
NSString *MRNowPlayingClientGetBundleIdentifier(id client);
NSString *MRNowPlayingClientGetParentAppBundleIdentifier(id client);

static NSDictionary *settings;
static NSArray *systemIdentifiers;

static BOOL enabled = YES;
static BOOL enabledInApp = NO;

static void updateNowPlayingApp();
static void updateNowPlayingInfo();
static NSArray *blacklistedApps();

// Preference updates
static void refreshPrefs() {
	CFArrayRef keyList = CFPreferencesCopyKeyList((CFStringRef)BUNDLE_ID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	if (keyList) {
		settings = (NSMutableDictionary *)CFBridgingRelease(CFPreferencesCopyMultiple(keyList, (CFStringRef)BUNDLE_ID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost));
		CFRelease(keyList);
	} else {
		settings = nil;
	}
	if (!settings) {
		settings = [[NSMutableDictionary alloc] initWithContentsOfFile:[NSString stringWithFormat:ROOT_PATH_NS(@"/var/mobile/Library/Preferences/%@.plist"), BUNDLE_ID]];
	}

	enabled = [([settings objectForKey:@"enabled"] ?: @(YES)) boolValue];
	enabledInApp = [([settings objectForKey:@"enabledInApp"] ?: @(NO)) boolValue];
	[SUNowPlayingManager sharedManager].window.rootViewController.shouldPlayFeedback = YES;
	[SUNowPlayingManager sharedManager].window.rootViewController.location = [([settings objectForKey:@"location"] ?: @(0)) intValue];
	[SUNowPlayingManager sharedManager].window.rootViewController.disableAutoDismiss = [([settings objectForKey:@"disableAutoDismiss"] ?: @(NO)) boolValue];
	[SUNowPlayingManager sharedManager].window.rootViewController.dismissWhenExpanded = [([settings objectForKey:@"dismissWhenExpanded"] ?: @(NO)) boolValue];
	[SUNowPlayingManager sharedManager].window.rootViewController.bannerView.matchSystemTheme = [([settings objectForKey:@"matchSystemTheme"] ?: @(YES)) boolValue];
	[SUNowPlayingManager sharedManager].window.rootViewController.bannerView.darkMode = [([settings objectForKey:@"darkMode"] ?: @(YES)) boolValue];
	[SUNowPlayingManager sharedManager].window.rootViewController.bannerView.oled = [([settings objectForKey:@"oled"] ?: @(NO)) boolValue];
	[SUNowPlayingManager sharedManager].window.rootViewController.bannerView.blurred = [([settings objectForKey:@"blurred"] ?: @(NO)) boolValue];
	[SUNowPlayingManager sharedManager].window.rootViewController.bannerView.blurThickness = [([settings objectForKey:@"blurThickness"] ?: @(1)) intValue];
	[SUNowPlayingManager sharedManager].window.rootViewController.bannerView.tintStrength = [([settings objectForKey:@"tint"] ?: @(NO)) boolValue] ? [([settings objectForKey:@"tintStrength"] ?: @(0.3)) floatValue] : 0;
	[[SUNowPlayingManager sharedManager].window.rootViewController.bannerView updateColors];

	BOOL customDismissInterval = [([settings objectForKey:@"customDismissInterval"] ?: @(NO)) boolValue];
	[SUNowPlayingManager sharedManager].window.rootViewController.dismissInterval = customDismissInterval ? [([settings objectForKey:@"dismissInterval"] ?: @(3)) intValue] : 3;
}

static void PreferencesChangedCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	refreshPrefs();
}

// Create now playing window
%hook SpringBoard
%property (nonatomic, retain) SUNowPlayingManager *sushiManager;

- (void)applicationDidFinishLaunching:(id)arg1 {
	%orig;

	self.sushiManager = [SUNowPlayingManager sharedManager];
	self.sushiManager.enabled = enabled;
	if (@available(iOS 16.0, *)) {
		UIWindowScene *windowScene = nil;
		for (UIScene *scene in self.connectedScenes) {
			if ([scene isKindOfClass:[UIWindowScene class]]) {
				windowScene = (UIWindowScene *)scene;
				break;
			}
		}
		if (!windowScene) return;
		self.sushiManager.window = [[%c(SUNowPlayingWindow) alloc] initWithWindowScene:windowScene role:nil debugName:@"SushiWindow"];
	} else if (@available(iOS 15.0, *)) {
		self.sushiManager.window = [[%c(SUNowPlayingWindow) alloc] initWithScreen:[UIScreen mainScreen] role:nil debugName:@"SushiWindow"];
	} else {
		self.sushiManager.window = [[%c(SUNowPlayingWindow) alloc] initWithScreen:[UIScreen mainScreen] debugName:@"SushiWindow"];
	}
	self.sushiManager.window.rootViewController = [[SUNowPlayingViewController alloc] init];

	[self addActiveOrientationObserver:self.sushiManager];
	if (@available(iOS 16.0, *)) {
    	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(nowPlayingAppDidChange) name:(__bridge NSString *)kMRMediaRemoteNowPlayingApplicationDidChangeNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(nowPlayingInfoDidChange) name:(__bridge NSString *)kMRMediaRemoteNowPlayingInfoDidChangeNotification object:nil];
	}

	refreshPrefs();
	updateNowPlayingApp();
}

%new
- (void)nowPlayingAppDidChange {
	updateNowPlayingApp();
}

%new
- (void)nowPlayingInfoDidChange {
	dispatch_async(dispatch_get_main_queue(), ^{
		updateNowPlayingInfo();
	});
}

%end

// Track now playing info changes
%hook SBMediaController

- (void)_setNowPlayingApplication:(SBApplication *)app {
	%orig;
	if (app) [[SUNowPlayingManager sharedManager].window.rootViewController appPlayingUpdate:app.bundleIdentifier];
}

- (void)setNowPlayingInfo:(id)info {
	%orig;
	updateNowPlayingInfo();
}

%end

// Hide on power button press
%hook SBLockHardwareButton

- (void)singlePress:(id)arg1 {
	%orig;
	[[SUNowPlayingManager sharedManager].window.rootViewController animateOut];
}

%end

// Disable reachability when banner is presented from the bottom
%hook SBReachabilityManager

- (void)toggleReachability {
	if ([SUNowPlayingManager sharedManager].enabled == YES && [SUNowPlayingManager sharedManager].window.hidden == NO && [SUNowPlayingManager sharedManager].window.rootViewController.location == 1) return;
	%orig;
}

%end

static void updateNowPlayingApp() {
    MRMediaRemoteGetNowPlayingClient(dispatch_get_main_queue(), ^(id client) {
		if (client != nil) {
			NSString *bundleIdentifier = MRNowPlayingClientGetBundleIdentifier(client);
			if (bundleIdentifier == nil) {
				bundleIdentifier = MRNowPlayingClientGetParentAppBundleIdentifier(client);
			}
			if (bundleIdentifier != nil) {
				[[SUNowPlayingManager sharedManager].window.rootViewController appPlayingUpdate:bundleIdentifier];
			}
		}
	});
}

static void updateNowPlayingInfo() {
	MRMediaRemoteGetNowPlayingInfo(dispatch_get_main_queue(), ^(CFDictionaryRef information) {
		NSMutableDictionary *userInfo = [(__bridge NSDictionary *)information mutableCopy];
		userInfo[@"currentApplication"] = [[(SpringBoard *)[UIApplication sharedApplication] _accessibilityFrontMostApplication] bundleIdentifier];
		userInfo[@"locked"] = @([[%c(SBLockScreenManager) sharedInstance] isUILocked]);
		userInfo[@"enabledInApp"] = @(enabledInApp);
		userInfo[@"blacklistedApps"] = blacklistedApps();
		[[SUNowPlayingManager sharedManager].window.rootViewController nowPlayingUpdate:userInfo];
	});	
}

// App List
static NSMutableDictionary *appList() {
	NSMutableDictionary *mutableDict = [[NSMutableDictionary alloc] init];
	for (SBApplication *app in [[NSClassFromString(@"SBApplicationController") sharedInstance] allApplications]) {
		bool add = YES;
		NSString *name = app.displayName ?: @"Error";
		for (NSString *id in systemIdentifiers) {
			if ([app.bundleIdentifier isEqual:id]) {
				add = NO;
			}
		}
		if (add) {
			[mutableDict setObject:name forKey:app.bundleIdentifier];
		}
	}

	return mutableDict;
}

static void getAppList(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	if (![[[NSBundle mainBundle] bundleIdentifier] isEqual:@"com.apple.springboard"]) {
		return;
	}

	NSMutableDictionary *mutableDict = appList();

	CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(), (CFStringRef)[BUNDLE_ID stringByAppendingString:@".setapps"], nil, (__bridge CFDictionaryRef)mutableDict, true);
}

static NSArray *blacklistedApps() {
	NSArray *apps = @[];
	NSString *prefPath = [NSString stringWithFormat:ROOT_PATH_NS(@"/var/mobile/Library/Preferences/%@.apps.plist"), BUNDLE_ID];

	if ([[NSFileManager defaultManager] fileExistsAtPath:prefPath]) {
		NSDictionary *appPrefs = [NSDictionary dictionaryWithContentsOfFile:prefPath];
		apps = appPrefs[@"Enabled"];
	}

	return apps;
}

static void testNotification(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	[[NSNotificationCenter defaultCenter] postNotificationName:[BUNDLE_ID stringByAppendingString:@".test"] object:nil userInfo:nil];
}

%ctor {
	// Hidden system apps
	systemIdentifiers = @[@"com.apple.AppSSOUIService", @"com.apple.AuthKitUIService", @"com.apple.BusinessChatViewService", @"com.apple.CTNotifyUIService", @"com.apple.ctkui", @"com.apple.ClipViewService", @"com.apple.CredentialSharingService", @"com.apple.CarPlaySplashScreen", @"com.apple.HealthENLauncher", @"com.apple.HealthENBuddy", @"com.apple.PublicHealthRemoteUI", @"com.apple.FTMInternal", @"com.apple.appleseed.FeedbackAssistant", @"com.apple.FontInstallViewService", @"com.apple.BarcodeScanner", @"com.apple.icloud.spnfcurl", @"com.apple.ScreenTimeUnlock", @"com.apple.CarPlaySettings", @"com.apple.SharedWebCredentialViewService", @"com.apple.sidecar", @"com.apple.Spotlight", @"com.apple.iMessageAppsViewService", @"com.apple.AXUIViewService", @"com.apple.AccountAuthenticationDialog", @"com.apple.AdPlatformsDiagnostics", @"com.apple.CTCarrierSpaceAuth", @"com.apple.CheckerBoard", @"com.apple.CloudKit.ShareBear", @"com.apple.AskPermissionUI", @"com.apple.CompassCalibrationViewService", @"com.apple.sidecar.camera", @"com.apple.datadetectors.DDActionsService", @"com.apple.DataActivation", @"com.apple.DemoApp", @"com.apple.Diagnostics", @"com.apple.DiagnosticsService", @"com.apple.carkit.DNDBuddy", @"com.apple.family", @"com.apple.fieldtest", @"com.apple.gamecenter.GameCenterUIService", @"com.apple.HealthPrivacyService", @"com.apple.Home.HomeUIService", @"com.apple.InCallService", @"com.apple.MailCompositionService", @"com.apple.mobilesms.compose", @"com.apple.MobileReplayer", @"com.apple.MusicUIService", @"com.apple.PhotosViewService", @"com.apple.PreBoard", @"com.apple.PrintKit.Print-Center", @"com.apple.social.SLYahooAuth", @"com.apple.SafariViewService", @"org.coolstar.SafeMode", @"com.apple.ScreenshotServicesSharing", @"com.apple.ScreenshotServicesService", @"com.apple.ScreenSharingViewService", @"com.apple.SIMSetupUIService", @"com.apple.Magnifier", @"com.apple.purplebuddy", @"com.apple.SharedWebCredentialsViewService", @"com.apple.SharingViewService", @"com.apple.SiriViewService", @"com.apple.susuiservice", @"com.apple.StoreDemoViewService", @"com.apple.TVAccessViewService", @"com.apple.TVRemoteUIService", @"com.apple.TrustMe", @"com.apple.CoreAuthUI", @"com.apple.VSViewService", @"com.apple.PassbookStub", @"com.apple.PassbookUIService", @"com.apple.WebContentFilter.remoteUI.WebContentAnalysisUI", @"com.apple.WebSheet", @"com.apple.iad.iAdOptOut", @"com.apple.ios.StoreKitUIService", @"com.apple.webapp", @"com.apple.webapp1", @"com.apple.springboard", @"com.apple.PassbookSecureUIService", @"com.apple.Photos.PhotosUIService", @"com.apple.RemoteiCloudQuotaUI", @"com.apple.shortcuts.runtime", @"com.apple.SleepLockScreen", @"com.apple.SubcredentialUIService", @"com.apple.dt.XcodePreviews", @"com.apple.icq"];

	refreshPrefs();
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PreferencesChangedCallback, (CFStringRef)[BUNDLE_ID stringByAppendingString:@".prefschanged"], NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
	CFNotificationCenterAddObserver(CFNotificationCenterGetDistributedCenter(), NULL, getAppList, (CFStringRef)[BUNDLE_ID stringByAppendingString:@".getapps"], NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
	CFNotificationCenterAddObserver(CFNotificationCenterGetDistributedCenter(), NULL, testNotification, (CFStringRef)[BUNDLE_ID stringByAppendingString:@".test"], NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
}
