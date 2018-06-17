@interface BBSettingsGateway : NSObject
-(id)initWithQueue:(id)arg1;
-(void)setActiveBehaviorOverrideTypesChangeHandler:(void (^)(int))block;
@end

@interface SBLockScreenManager : NSObject
+(id)sharedInstance;
-(BOOL)isLockScreenActive;
@end

BOOL dndEnabled = NO;
BBSettingsGateway *_settingsGateway = [[NSClassFromString(@"BBSettingsGateway") alloc] initWithQueue:dispatch_get_main_queue()];

%hook NCNotificationContent
- (NSString *)message {
	[_settingsGateway setActiveBehaviorOverrideTypesChangeHandler:^(int value) {
		if (value == 1) {
			dndEnabled = YES;
		}
		else {
			dndEnabled = NO;
		}
	}];
	if (dndEnabled == YES) {
		if ([[%c(SBLockScreenManager) sharedInstance] isLockScreenActive] == YES) {
			return @"New Notification";
		}
		else {
			return %orig;
		}
	}
	else {
		return %orig;
	}
}
%end