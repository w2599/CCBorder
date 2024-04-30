#import <Preferences/Preferences.h>
#import <libcolorpicker.h>

@interface CCBRootListController : PSListController
@end

@implementation CCBRootListController
	- (id)specifiers {
		if(_specifiers == nil) {
			_specifiers = [self loadSpecifiersFromPlistName:@"CCBorder" target:self];
		}
		return _specifiers;
	}

	- (void)respring {
		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.fiore.ccborder.respring"), NULL, NULL, YES);
	}	

@end
