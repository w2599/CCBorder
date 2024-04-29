@import Foundation;
@import UIKit;

@interface MTMaterialView : UIView
@end

@interface CCUIContentModuleContainerViewController : UIViewController
	@property (nonatomic,copy) NSString * moduleIdentifier;
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
static UIColor *borderColor = [UIColor blackColor];

//Most CC modules
%hook CCUIContentModuleContentContainerView	
	- (void)layoutSubviews {
		%orig;
		MTMaterialView *matView = MSHookIvar<MTMaterialView *>(self, "_moduleMaterialView");
		CGFloat cornerRadius = 0;
		if (!matView) {
			// if ([[[self _viewControllerForAncestor] moduleIdentifier] isEqualToString:@"com.apple.FocusUIModule"])
			// 	cornerRadius = self.compactContinuousCornerRadius;
			// else
				return;
		}
		else {
			if (matView.layer.cornerRadius > 0)
				cornerRadius = matView.layer.cornerRadius;
			else //Fixes flashlight expanded module
				cornerRadius = self.expandedContinuousCornerRadius;
		}

		self.layer.borderWidth = borderWidth;
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

//Home Controls
%hook MTMaterialView

	-(void)layoutSubviews {
		%orig;

		if (([self superview] && [[self superview] isKindOfClass:%c(HUGridCellBackgroundView)]) || [[self _viewControllerForAncestor] isKindOfClass:NSClassFromString(@"FCCCControlCenterModule")]) {
			self.layer.borderWidth = borderWidth;
			self.layer.borderColor = borderColor.CGColor;
			[self.layer setCornerRadius:self.layer.cornerRadius];
		}
	}

%end