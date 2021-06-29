@interface SBUIController
+ (id)sharedInstanceIfExists;
- (void)activateApplication:(id)app fromIcon:(id)icon location:(long long)location activationSettings:(id)settings actions:(id)actions;
@end
