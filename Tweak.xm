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
-(void)colorSliderGlyphs;
@end

@interface MRUContinuousSliderView : CCUIContinuousSliderView
	@property (nonatomic,readonly) UIView *materialView;
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
static UIColor *borderColor = nil;

static BOOL wantsCornerRadius = YES;
static double cornerRadius = 36;

static BOOL wantsGlyphColoring = YES;
static UIColor *brightnessGlyphColor = nil;
static UIColor *volumeGlyphColor = nil;

%group GlyphColoring
	%hook CALayer
		-(void)setOpacity:(float)opacity {
			if ([self.delegate isKindOfClass:%c(CCUICAPackageView)] || [self.delegate isKindOfClass:%c(UIImageView)]) {
				id controller = [(UIView *)self.delegate _viewControllerForAncestor];
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

		%new
		-(void)colorSliderGlyphs {
			UIColor *glyphColor = nil;
			if ([[self _viewControllerForAncestor] isKindOfClass:NSClassFromString(@"CCUIDisplayModuleViewController")])
				glyphColor = brightnessGlyphColor;
			else if ([[self _viewControllerForAncestor] isKindOfClass:NSClassFromString(@"MRUVolumeViewController")] || [[self _viewControllerForAncestor] isKindOfClass:NSClassFromString(@"SBElasticVolumeViewController")])
				glyphColor = volumeGlyphColor;

			UIView *packageView = MSHookIvar<UIView*>(self,"_compensatingGlyphView");
			if (packageView && glyphColor) {
				if ([packageView isKindOfClass:%c(CCUICAPackageView)])
					colorLayers(@[packageView.layer],glyphColor.CGColor);
				else if ([packageView isKindOfClass:%c(UIImageView)]) {
					[packageView setTintColor:glyphColor];
				}
			}		
		}

		-(void)didMoveToWindow {
			%orig;
			[self colorSliderGlyphs];
		}

		-(void)_applyGlyphState:(id)arg1 performConfiguration:(BOOL)arg2 {
			%orig;
			[self colorSliderGlyphs];
		}

	%end
%end

%group Corners

	%hook CCUIButtonModuleView
	
		-(double)_continuousCornerRadius {return cornerRadius;}

		-(void)_setContinuousCornerRadius:(double)arg1 {%orig(cornerRadius);}

		-(void)layoutSubviews {
			%orig;
			UIView *bgView = MSHookIvar<UIView*>(self,"_highlightedBackgroundView");
			if (bgView)
				bgView.layer.cornerRadius = cornerRadius;
		}

	%end

	%hook MRUContinuousSliderView
	
		-(void)layoutSubviews {
			%orig;
			if ([[self _viewControllerForAncestor] isKindOfClass:NSClassFromString(@"CCUIDisplayModuleViewController")] || [[self _viewControllerForAncestor] isKindOfClass:NSClassFromString(@"MRUVolumeViewController")])			
				self.materialView.layer.cornerRadius = cornerRadius;
		}
	%end

	%hook CCUIContinuousSliderView

		-(double)continousSliderCornerRadius {
			if ([[self _viewControllerForAncestor] isKindOfClass:NSClassFromString(@"CCUIDisplayModuleViewController")] || [[self _viewControllerForAncestor] isKindOfClass:NSClassFromString(@"MRUVolumeViewController")])
				return cornerRadius;

			return %orig;
		}

		-(void)setContinuousSliderCornerRadius:(double)arg1 {
			if ([[self _viewControllerForAncestor] isKindOfClass:NSClassFromString(@"CCUIDisplayModuleViewController")] || [[self _viewControllerForAncestor] isKindOfClass:NSClassFromString(@"MRUVolumeViewController")])
				arg1 = cornerRadius;

			%orig(arg1);
		}	

	%end	

	%hook CCUIContentModuleContainerViewController

		-(double)_continuousCornerRadiusForCompactState {return cornerRadius;}

	%end

	%hook CCUIContentModuleContentContainerView

		-(void)layoutSubviews {
			%orig;
			CCUIContentModuleContainerViewController *viewController = [self _viewControllerForAncestor];			
			if ([[viewController moduleIdentifier] isEqualToString:@"com.apple.FocusUIModule"] && !viewController.expanded) {
					for (UIView *subview in self.subviews) {
						UIView *currentView = subview;
						while (currentView) {
							if([currentView isKindOfClass:%c(MTMaterialView)])
								currentView.layer.cornerRadius = cornerRadius;

							currentView = currentView.subviews.count > 0 ? currentView.subviews[0] : nil;
						}
				}					
			}			
		}

		-(double)compactContinuousCornerRadius {return cornerRadius;}

		-(void)setCompactContinuousCornerRadius:(double)arg1 {%orig(cornerRadius);}
	%end

	%hook MRUControlCenterView

		-(double)cornerRadius {return cornerRadius;}

		-(void)setCornerRadius:(double)arg1 {%orig(cornerRadius);}		
		
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
	NSDictionary *prefs = [[NSDictionary alloc] initWithContentsOfFile:@"/var/jb/var/mobile/Library/Preferences/com.fiore.ccborder.plist"];
	if(prefs)
	{
		wantsBorder = [prefs objectForKey:@"wantsBorder"] ? [[prefs objectForKey:@"wantsBorder"] boolValue] : wantsBorder;
		wantsCornerRadius = [prefs objectForKey:@"wantsCornerRadius"] ? [[prefs objectForKey:@"wantsCornerRadius"] boolValue] : wantsCornerRadius;
		wantsGlyphColoring = [prefs objectForKey:@"wantsGlyphColoring"] ? [[prefs objectForKey:@"wantsGlyphColoring"] boolValue] : wantsGlyphColoring;
		borderWidth = [prefs objectForKey:@"borderWidth"] ? [[prefs objectForKey:@"borderWidth"] doubleValue] : borderWidth;
		cornerRadius = [prefs objectForKey:@"cornerRadius"] ? [[prefs objectForKey:@"cornerRadius"] doubleValue] : cornerRadius;
		borderColor = [prefs objectForKey:@"borderColor"] ? LCPParseColorString([prefs objectForKey:@"borderColor"],@"#A9A9A9") : borderColor;
		brightnessGlyphColor = [prefs objectForKey:@"brightnessGlyphColor"] ? LCPParseColorString([prefs objectForKey:@"brightnessGlyphColor"],@"#FF8548") : brightnessGlyphColor;
		volumeGlyphColor = [prefs objectForKey:@"volumeGlyphColor"] ? LCPParseColorString([prefs objectForKey:@"volumeGlyphColor"],@"#00C6FB") : volumeGlyphColor;
	}

	if (!borderColor)
		borderColor = LCPParseColorString(@"#A9A9A9",@"#A9A9A9");

	if (!brightnessGlyphColor)
		brightnessGlyphColor = LCPParseColorString(@"#FF8548",@"#FF8548");

	if (!volumeGlyphColor)
		volumeGlyphColor = LCPParseColorString(@"#00C6FB",@"#00C6FB");
}

%ctor {
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)reloadSettings, CFSTR("com.fiore.ccborder.settingschanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
	reloadSettings();
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, respring, CFSTR("com.fiore.ccborder.respring"), NULL, CFNotificationSuspensionBehaviorCoalesce);

	if (wantsBorder)
		%init(Borders);

	if (wantsCornerRadius)
		%init(Corners);	

	if (wantsGlyphColoring)
		%init(GlyphColoring);

	%init;
}