@import Foundation;
@import UIKit;
#import <libcolorpicker.h>

@interface FBSystemService : NSObject
  +(id)sharedInstance;
  -(void)exitAndRelaunch:(BOOL)arg1;
@end

@interface MTMaterialView : UIView
@end

@interface CCUIContentModuleContainerViewController : UIViewController
	@property (nonatomic,copy) NSString * moduleIdentifier;
	@property (assign,getter=isTransitioning,nonatomic) BOOL transitioning;
	@property (assign,getter=isExpanded,nonatomic) BOOL expanded; 
@end

@interface UIView (Private)
	- (id)_viewControllerForAncestor;
@end

@interface CCUIContentModuleContentContainerView : UIView {
	MTMaterialView *_moduleMaterialView;
}
	@property (assign,nonatomic) double compactContinuousCornerRadius;
	@property (assign,nonatomic) double expandedContinuousCornerRadius;	
@end

@interface CCUIRoundButton : UIView {
	MTMaterialView *_normalStateBackgroundView;
}
@end

@interface CCUIContinuousSliderView : UIView {
	MTMaterialView *_backgroundView;	
}
@property (assign,getter=isGlyphVisible,nonatomic) BOOL glyphVisible;
@end

@interface HUGridCellBackgroundView : UIView
	@property (assign,nonatomic) double cornerRadius;
@end

@interface HUGridCell : UIView
@end

@interface HUTileCell : UIView
@end

@interface FCUIActivityControl : UIView {
	MTMaterialView *_backgroundView;
}
@end

@interface MRUControlCenterView : UIView
	@property (retain, nonatomic) UIView *materialView;
@end

@interface MRUControlCenterButton : UIView
	@property (retain, nonatomic) UIView *backgroundView;
@end

@interface MRUNowPlayingView : UIView
@end

@interface _FCUIAddActivityControl : UIView {
	MTMaterialView *_backgroundMaterialView;
}
@end

@interface MediaControlsVolumeSliderView : UIView {
	UIView *_materialView;
}
@end

static double borderWidth = 4.0;
static UIColor *borderColor;

//Most CC modules
%hook CCUIContentModuleContentContainerView	
	- (void)layoutSubviews {
		%orig;
		MTMaterialView *matView = MSHookIvar<MTMaterialView *>(self, "_moduleMaterialView");
		CCUIContentModuleContainerViewController *viewController = [self _viewControllerForAncestor];
		CGFloat borderWidthTemp = borderWidth;
		CGFloat cornerRadius = 0;
		if (!matView) {
			//Fixes focus indicator
			if ([[viewController moduleIdentifier] isEqualToString:@"com.apple.FocusUIModule"]) {
				if (!viewController.expanded)
					cornerRadius = self.compactContinuousCornerRadius;
				else
					borderWidthTemp = 0.0;
			}
			else
				return;
		}
		else {
			if (matView.layer.cornerRadius > 0)
				cornerRadius = matView.layer.cornerRadius;
			else //Fixes flashlight expanded module
				cornerRadius = viewController.expanded ? self.expandedContinuousCornerRadius : self.compactContinuousCornerRadius;
		}

		self.layer.borderWidth = borderWidthTemp;
		self.layer.borderColor = borderColor.CGColor;
		[self.layer setCornerRadius:cornerRadius];
	}

%end

//Round Toggle Controls, True Tone etc
%hook CCUIRoundButton
	- (void)layoutSubviews {
		%orig;
		MTMaterialView *matView = MSHookIvar<MTMaterialView *>(self, "_normalStateBackgroundView");
		if (!matView) return;

		self.layer.borderWidth = borderWidth;
		self.layer.borderColor = borderColor.CGColor;
		[self.layer setCornerRadius:matView.layer.cornerRadius];
	}

%end

//Volume & Brightness Controls
%hook CCUIContinuousSliderView
	- (void)layoutSubviews {
		%orig;
		MTMaterialView *matView = MSHookIvar<MTMaterialView *>(self, "_backgroundView");
		if (!matView) return;		

		self.layer.borderWidth = self.frame.size.width < 15 ? 1.0 : borderWidth;
		self.layer.borderColor = borderColor.CGColor;
		[self.layer setCornerRadius:matView.layer.cornerRadius];
	}

%end

//Focus Modes
%hook FCUIActivityControl	
	- (void)layoutSubviews {
		%orig;

		MTMaterialView *matView = MSHookIvar<MTMaterialView *>(self, "_backgroundView");
		if (!matView) return;

		self.layer.borderWidth = borderWidth;
		self.layer.borderColor = borderColor.CGColor;
		[self.layer setCornerRadius:matView.layer.cornerRadius];
	}
%end

//Tiny + button when 3d touching on dnd module
%hook _FCUIAddActivityControl	
	- (void)layoutSubviews {
		%orig;

		MTMaterialView *matView = MSHookIvar<MTMaterialView *>(self, "_backgroundMaterialView");
		if (!matView) return;

		self.layer.borderWidth = borderWidth;
		self.layer.borderColor = borderColor.CGColor;
		[self.layer setCornerRadius:matView.layer.cornerRadius];
	}

%end

//Music Platter
%hook MRUNowPlayingView	
	- (void)layoutSubviews {
		%orig;

		self.layer.borderWidth = borderWidth;
		self.layer.borderColor = borderColor.CGColor;
	}

%end

//Music Platter Control Center button
%hook MRUControlCenterButton	
	- (void)layoutSubviews {
		%orig;

		MTMaterialView *matView = MSHookIvar<MTMaterialView *>(self, "_backgroundView");
		if (!matView) return;		

		matView.layer.borderWidth = borderWidth;
		matView.layer.borderColor = borderColor.CGColor;
	}

%end

//Home App in CC, Needs hook in com.apple.HomeUI
// %hook HUControllableItemCollectionViewController

// 	-(void)collectionView:(id)arg1 didEndDisplayingCell:(id)arg2 forItemAtIndexPath:(id)arg3 {
// 		if ([arg2 isKindOfClass:%c(HUTileCell)]) {
// 			HUTileCell *cell = arg2;
// 			cell.layer.borderWidth = borderWidth;
// 			cell.layer.borderColor = borderColor.CGColor;
// 		}
// 		%orig;
// 	}

// %end

//Home Tiles in CC
%hook UICollectionViewCell

	-(void)didMoveToWindow {
		%orig;			
		if ([self isKindOfClass:%c(HUGridCell)]) {
			self.layer.borderWidth = borderWidth;
			self.layer.borderColor = borderColor.CGColor;				
		}
	}	

%end

static void respring(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
  [[%c(FBSystemService) sharedInstance] exitAndRelaunch:YES];
}

static void reloadSettings() {

	NSDictionary *prefs = [[NSDictionary alloc] initWithContentsOfFile:@"/var/jb/var/mobile/Library/Preferences/com.fiore.ccborder.plist"];
	if(prefs)
		borderColor = [prefs objectForKey:@"borderColor"] ? LCPParseColorString([prefs objectForKey:@"borderColor"],@"#808080") : [UIColor systemGrayColor];
	else
		borderColor = [UIColor systemGrayColor];

}

%ctor {
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)reloadSettings, CFSTR("com.fiore.ccborder.settingschanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
	reloadSettings();
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, respring, CFSTR("com.fiore.ccborder.respring"), NULL, CFNotificationSuspensionBehaviorCoalesce);
}