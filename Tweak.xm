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
	-(void)setCornerRadius:(double)arg1;
@end

@interface HUGridCell : UIView
	@property (nonatomic,retain) HUGridCellBackgroundView * gridBackgroundView;
@end

@interface HUTileCell : UIView
@end

@interface FCUIActivityControl : UIView {
	MTMaterialView *_backgroundView;
}
@end

@interface MRUTransportButton : UIView
@end

@interface MRUControlCenterView : UIView
	@property (retain, nonatomic) UIView *materialView;
	@property (nonatomic,readonly) MRUTransportButton * routingButton;
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

@interface CCUICAPackageView : UIView
@end

@interface CALayer (CCBorder)
	@property (assign) CGColorRef contentsMultiplyColor;
@end

static BOOL wantsBorder = YES;
static double borderWidth = 4.0;
static UIColor *borderColor;

static BOOL wantsCornerRadius = YES;
static double cornerRadius = 36;

%hook CALayer
	-(void)setOpacity:(float)opacity {
		if ([self.delegate isKindOfClass:%c(CCUICAPackageView)]) {
			id controller = [(CCUICAPackageView *)self.delegate _viewControllerForAncestor];
			if ([controller isKindOfClass:%c(CCUIDisplayModuleViewController)] ||
					[controller isKindOfClass:%c(MRUVolumeViewController)] ||
						[controller isKindOfClass:%c(SBElasticVolumeViewController)])
						opacity = opacity > 0 ? 1.0 : opacity;
		}

		%orig(opacity);
	}
%end

void colorLayers(NSArray *layers, CGColorRef color) {
	for (CALayer *sublayer in layers) {
		if ([sublayer isMemberOfClass:%c(CAShapeLayer)]) {
			CAShapeLayer *shapelayer = (CAShapeLayer *)sublayer;
			shapelayer.fillColor = color;
			shapelayer.strokeColor = color;
		}
		else if (sublayer.sublayers.count == 0) {
			sublayer.backgroundColor = color;
			sublayer.borderColor = color;
			sublayer.contentsMultiplyColor = color;			
		}

		colorLayers(sublayer.sublayers, color);
	}
}

%hook CCUIContinuousSliderView

	-(void)layoutSubviews {
		%orig;
		UIColor *glyphColor = nil;
		if ([[self _viewControllerForAncestor] isKindOfClass:NSClassFromString(@"CCUIDisplayModuleViewController")])
			glyphColor = [UIColor colorWithRed: 1.98 green: 1.2 blue: 0.04 alpha: 1];
		else if ([[self _viewControllerForAncestor] isKindOfClass:NSClassFromString(@"MRUVolumeViewController")] || [[self _viewControllerForAncestor] isKindOfClass:NSClassFromString(@"SBElasticVolumeViewController")])
			glyphColor = [UIColor colorWithRed: 0.6 green: 1.15 blue: 1.51 alpha: 1];

		UIView *packageView = MSHookIvar<UIView*>(self,"_compensatingGlyphView");
		if (packageView && glyphColor) {
			if ([packageView isKindOfClass:%c(CCUICAPackageView)])
				colorLayers(@[packageView.layer],glyphColor.CGColor);
			else if ([packageView isKindOfClass:%c(UIImageView)]) {
				[packageView setTintColor:glyphColor];
			}
		}
	}

%end

//Most CC modules
%hook CCUIContentModuleContentContainerView	
	- (void)layoutSubviews {
		%orig;
		MTMaterialView *matView = MSHookIvar<MTMaterialView *>(self, "_moduleMaterialView");
		CCUIContentModuleContainerViewController *viewController = [self _viewControllerForAncestor];

		if (wantsBorder) {
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

		if (wantsCornerRadius) {

			BOOL expanded = MSHookIvar<BOOL>(self, "_expanded");

			if (expanded)
				return;

			double tempCornerRadius = cornerRadius;				

			if ([[viewController moduleIdentifier] containsString:@"Home.ControlCenter"] || [[viewController moduleIdentifier] containsString:@"DisplayModule"] || [[viewController moduleIdentifier] containsString:@"controlcenter.audio"])
				tempCornerRadius = tempCornerRadius - 4;

			if (![[viewController moduleIdentifier] containsString:@"Home.ControlCenter"]) {
				[self setClipsToBounds: YES];
				self.layer.cornerRadius = tempCornerRadius;
				self.layer.cornerCurve = kCACornerCurveContinuous;				
			}				

			for (UIView *subview in self.subviews) {

				UIView *currentView = subview;
				while (currentView) {
					if([currentView isKindOfClass: %c(CCUIContinuousSliderView)] || [currentView isKindOfClass:%c(MTMaterialView)]) {

						[currentView setClipsToBounds: YES];
						currentView.layer.cornerRadius = tempCornerRadius;
						currentView.layer.cornerCurve = kCACornerCurveContinuous;						
					}					

					currentView = currentView.subviews.count > 0 ? currentView.subviews[0] : nil;
				}
			}
		}
	}

%end

//Home Tiles in CC
%hook UICollectionViewCell

	-(void)didMoveToWindow {
		%orig;			
		if ([self isKindOfClass:%c(HUGridCell)]) {
			if (wantsBorder) {
				self.layer.borderWidth = borderWidth;
				self.layer.borderColor = borderColor.CGColor;
			}

			// if (wantsCornerRadius) {
			// 	[((HUGridCell*)self).gridBackgroundView setCornerRadius:cornerRadius-8];
			// }
		}
	}	

%end

%group Corners

	%hook MRUControlCenterView

		-(void)layoutSubviews {
			%orig;
			CGRect origFrame = self.routingButton.frame;
			origFrame.origin.x = 115;
			origFrame.origin.y = 5;
			self.routingButton.frame = origFrame;
		}

	%end

%end

%group Borders

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

static void respring(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
  [[%c(FBSystemService) sharedInstance] exitAndRelaunch:YES];
}

static void reloadSettings() {

	static CFStringRef prefsKey = CFSTR("com.fiore.ccborder");
	CFPreferencesAppSynchronize(prefsKey);

	if (CFBridgingRelease(CFPreferencesCopyAppValue((CFStringRef)@"wantsBorder", prefsKey))) {
		wantsBorder = [(id)CFBridgingRelease(CFPreferencesCopyAppValue((CFStringRef)@"wantsBorder", prefsKey)) boolValue];
	}	

	if (CFBridgingRelease(CFPreferencesCopyAppValue((CFStringRef)@"wantsCornerRadius", prefsKey))) {
		wantsCornerRadius = [(id)CFBridgingRelease(CFPreferencesCopyAppValue((CFStringRef)@"wantsCornerRadius", prefsKey)) boolValue];
	}

	if (CFBridgingRelease(CFPreferencesCopyAppValue((CFStringRef)@"borderWidth", prefsKey))) {
		borderWidth = [(id)CFBridgingRelease(CFPreferencesCopyAppValue((CFStringRef)@"borderWidth", prefsKey)) doubleValue];
	}	

	if (CFBridgingRelease(CFPreferencesCopyAppValue((CFStringRef)@"cornerRadius", prefsKey))) {
		cornerRadius = [(id)CFBridgingRelease(CFPreferencesCopyAppValue((CFStringRef)@"cornerRadius", prefsKey)) doubleValue];
	}	

	if (CFBridgingRelease(CFPreferencesCopyAppValue((CFStringRef)@"borderColor", prefsKey))) {
		borderColor = LCPParseColorString([(id)CFBridgingRelease(CFPreferencesCopyAppValue((CFStringRef)@"borderColor", prefsKey)) stringValue],@"#808080");
	}
	else
		borderColor = [UIColor systemGrayColor];

	if (wantsBorder)
		%init(Borders);

	if (wantsCornerRadius)
		%init(Corners);		

	%init;
}

%ctor {
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)reloadSettings, CFSTR("com.fiore.ccborder.settingschanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
	reloadSettings();
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, respring, CFSTR("com.fiore.ccborder.respring"), NULL, CFNotificationSuspensionBehaviorCoalesce);
}