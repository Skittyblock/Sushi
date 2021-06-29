@class SBApplication;

@interface SBApplicationController
+ (id)sharedInstance;
- (SBApplication *)applicationWithBundleIdentifier:(NSString *)bundleIdentifier;
- (NSArray *)allApplications;
@end
