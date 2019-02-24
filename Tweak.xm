// Sopio: hides notification previews on the lock screen if Do Not Disturb is enabled
// (c) Trevor Schmitt, 2019.
// disclaimer: this code is probably pretty bad and could be done better; if you have any improvements or suggestions, I'm all ears

#import <CoreFoundation/CoreFoundation.h>

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

/* this group of code will run on iOS 11 and higher */
%group iOS11Up

/* detecting Do Not Disturb state on iOS 12 */
%hook DNDState
-(bool)isActive {
	if (kCFCoreFoundationVersionNumber > 1452.23) {
		dndEnabled = %orig;
	}
	return %orig;
}
%end

%hook BBServer
-(long long)_globalContentPreviewsSetting {
	/* detecting Do Not Disturb state on iOS 11 */
	if (kCFCoreFoundationVersionNumber >= 1443.00 && kCFCoreFoundationVersionNumber <= 1452.23) {
		[_settingsGateway setActiveBehaviorOverrideTypesChangeHandler:^(int value) {
			if (value == 1) {
				dndEnabled = YES;
			}
			else {
				dndEnabled = NO;
			}
		}];
	}
	if (dndEnabled == YES) {
		/* quick rundown of the various content preview settings:
		0 - content previews are always shown
		2 - content previews are hidden on lock screen, but show everywhere else
		3 - content previews are always hidden */
		return 2;
	}
	else {
		return %orig;
	}
}
%end
%end

/* this group of code will run on iOS 10 */
%group iOS10
/* iOS 10 doesn't have the global content preview setting present in iOS 11 and up */
/* Therefore, I'm doing something a bit different (aka original Sopio 1.0 code) */
%hook NCNotificationContent
- (NSString *)message {
	/* same method of detecting the Do Not Disturb state as used on iOS 11 */
	[_settingsGateway setActiveBehaviorOverrideTypesChangeHandler:^(int value) {
		if (value == 1) {
			dndEnabled = YES;
		}
		else {
			dndEnabled = NO;
		}
	}];
	if (dndEnabled == YES) {
		/* check if the user is on the lock screen */
		if ([[%c(SBLockScreenManager) sharedInstance] isLockScreenActive] == YES) {
			return @"Notification";
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
%end

%ctor {
	if (kCFCoreFoundationVersionNumber >= 1348.00 && kCFCoreFoundationVersionNumber < 1443.00) {
		/* iOS version is 10.0 or greater and less than 11.0 */
		%init(iOS10);
	}
	else if (kCFCoreFoundationVersionNumber >= 1443.00) {
		/* iOS version is 11.0 or greater */
		%init(iOS11Up);
	}
}

