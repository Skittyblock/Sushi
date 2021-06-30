// Sushi, by Skitty
// Now playing banner with integrated media controls

#import <MediaRemote/MediaRemote.h>
#import "SUWindow.h"
#import "SUNowPlayingViewController.h"
#import "SpringBoard+SUWindow.h"
#import "SBApplication.h"
#import "SBApplicationController.h"
#import "SBLockScreenManager.h"

#define BUNDLE_ID @"xyz.skitty.sushi"

CFNotificationCenterRef CFNotificationCenterGetDistributedCenter(void);

static SUNowPlayingViewController *nowPlayingControllerInstance;

static NSDictionary *settings;
static NSArray *systemIdentifiers;

static BOOL enabled = YES;
static BOOL enabledInApp = NO;

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
		settings = [[NSMutableDictionary alloc] initWithContentsOfFile:[NSString stringWithFormat:@"/var/mobile/Library/Preferences/%@.plist", BUNDLE_ID]];
	}

	enabled = [([settings objectForKey:@"enabled"] ?: @(YES)) boolValue];
	enabledInApp = [([settings objectForKey:@"enabledInApp"] ?: @(NO)) boolValue];
	nowPlayingControllerInstance.location = [([settings objectForKey:@"location"] ?: @(0)) intValue];
	nowPlayingControllerInstance.dismissWhenExpanded = [([settings objectForKey:@"dismissWhenExpanded"] ?: @(NO)) boolValue];
	nowPlayingControllerInstance.bannerView.matchSystemTheme = [([settings objectForKey:@"matchSystemTheme"] ?: @(YES)) boolValue];
	nowPlayingControllerInstance.bannerView.darkMode = [([settings objectForKey:@"darkMode"] ?: @(YES)) boolValue];
	nowPlayingControllerInstance.bannerView.oled = [([settings objectForKey:@"oled"] ?: @(NO)) boolValue];
	nowPlayingControllerInstance.bannerView.blurred = [([settings objectForKey:@"blurred"] ?: @(NO)) boolValue];
	nowPlayingControllerInstance.bannerView.blurThickness = [([settings objectForKey:@"blurThickness"] ?: @(1)) intValue];
	nowPlayingControllerInstance.bannerView.tintStrength = [([settings objectForKey:@"tint"] ?: @(NO)) boolValue] ? [([settings objectForKey:@"tintStrength"] ?: @(0.3)) floatValue] : 0;
	[nowPlayingControllerInstance.bannerView updateColors];

	BOOL customDismissInterval = [([settings objectForKey:@"customDismissInterval"] ?: @(NO)) boolValue];
	nowPlayingControllerInstance.dismissInterval = customDismissInterval ? [([settings objectForKey:@"dismissInterval"] ?: @(3)) intValue] : 3;
}

static void PreferencesChangedCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	refreshPrefs();
}

// Create now playing window
%hook SpringBoard
%property (nonatomic, retain) SUWindow *sushiWindow;

- (void)applicationDidFinishLaunching:(id)arg1 {
	%orig;

	nowPlayingControllerInstance = [[SUNowPlayingViewController alloc] init];
	nowPlayingControllerInstance.shouldPlayFeedback = YES;
	refreshPrefs();

	self.sushiWindow = [[SUWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	self.sushiWindow.rootViewController = nowPlayingControllerInstance;
	self.sushiWindow.windowLevel = UIWindowLevelStatusBar + 100.0;
	self.sushiWindow.enabled = enabled;
}

%end

// Track now playing info changes
// Could also probably use kMRMediaRemoteNowPlayingInfoDidChangeNotification instead
%hook SBMediaController

- (void)_setNowPlayingApplication:(SBApplication *)app {
	%orig;
	if (app) [[NSNotificationCenter defaultCenter] postNotificationName:@"xyz.skitty.sushi.appchange" object:nil userInfo:@{ @"id": app.bundleIdentifier }];
}

- (void)setNowPlayingInfo:(id)info {
	%orig;

	MRMediaRemoteGetNowPlayingInfo(dispatch_get_main_queue(), ^(CFDictionaryRef information) {
		NSMutableDictionary *userInfo = [(__bridge NSDictionary *)information mutableCopy];
		userInfo[@"currentApplication"] = [[(SpringBoard *)[UIApplication sharedApplication] _accessibilityFrontMostApplication] bundleIdentifier];
		userInfo[@"locked"] = @([[%c(SBLockScreenManager) sharedInstance] isUILocked]);
		userInfo[@"enabledInApp"] = @(enabledInApp);
		userInfo[@"blacklistedApps"] = blacklistedApps();
		[[NSNotificationCenter defaultCenter] postNotificationName:@"xyz.skitty.sushi.songchange" object:nil userInfo:userInfo];
	});	
}

%end

// Hide on power button press
%hook SBLockHardwareButton

- (void)singlePress:(id)arg1 {
	%orig;
	[nowPlayingControllerInstance animateOut];
}

%end

// Disable reachability when banner is presented from the bottom
%hook SBReachabilityManager

- (void)toggleReachability {
	if (((SUWindow *)nowPlayingControllerInstance.view.superview).enabled == YES && nowPlayingControllerInstance.view.superview.hidden == NO && nowPlayingControllerInstance.location == 1) return;
	%orig;
}

%end

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
	NSString *prefPath = [NSString stringWithFormat:@"/var/mobile/Library/Preferences/%@.apps.plist", BUNDLE_ID];

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
