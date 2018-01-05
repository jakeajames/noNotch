#include <substrate.h>
#include <UIKit/UIStatusBar.h>
#import <CoreGraphics/CoreGraphics.h>
#include <SpringBoard/SpringBoard.h>

@interface UIStatusBarWindow : UIWindow
@property (nonatomic, assign) UIWindow *noNotchW;
@property (nonatomic, assign) UIView *noNotch; //add a new UIWindow property (Call it something unique so it doesnt mess with any other tweaks)
@end

@interface UIStatusBar_Base : UIView
-(int)currentStyle;
@end

@interface _UIStatusBar : UIView
@property (nonatomic, retain) UIColor *foregroundColor;
@end

%hook UIStatusBarWindow
%property (nonatomic, assign) UIWindow *noNotchW;
%property (nonatomic, assign) UIView *noNotch; //add a new UIWindow property

- (void)layoutSubviews
{
    CGRect wholeFrame = [UIScreen mainScreen].bounds; //whole screen
    CGRect frame = CGRectMake(-34, 0, wholeFrame.size.width+68, wholeFrame.size.height+200); //this is the border which will cover the notch
    
    if (!self.noNotchW) {
        self.noNotchW = [[UIWindow alloc] initWithFrame:wholeFrame]; //whole screen size goes to the window
    }
    
    if (!self.noNotch) {
        self.noNotch = [[UIView alloc] initWithFrame:frame]; //the notch view
    }
    self.noNotch.layer.borderColor = [UIColor blackColor].CGColor; //add a black border
    self.noNotch.layer.borderWidth = 34.0f; //something thinner than the status bar
    
    [self.noNotch setClipsToBounds:YES]; //we want the border to be round
    [self.noNotch.layer setMasksToBounds:YES]; //^^
    self.noNotch.layer.cornerRadius = 68; //corner radius
    
    self.noNotchW.windowLevel = self.windowLevel - 1.0f; //make this be under the status bar
    self.noNotchW.hidden = NO; //we don't want it hidden for whatever reason
    self.noNotchW.userInteractionEnabled = NO; //we don't want our view to prevent touches
    [self.noNotchW addSubview:self.noNotch]; //add our notch cover!
    
    UIStatusBar_Base *statusBar = [self valueForKey:@"_statusBar"];
    statusBar.tag = 4141411337; //tag SpringBoard's status bar so it's never hidden, TODO: fix two status bars in landscape mode
    
    %orig; //make SpringBoard do whatever it was gonna do before we kicked in and stole the notch
}
%end

%hook UIStatusBarWindow
-(void)setHidden:(BOOL)arg1 {
    %orig(NO); //unhide it
}
%end
%hook UIStatusBar_Base
-(void)setAlpha:(CGFloat)arg1 {
    if(self.tag == 4141411337);
    arg1 = 1;
    %orig(arg1); //make it visible if ours
}
%end
%hook _UIStatusBar
- (void)setFrame:(CGRect)frame {
    frame.origin.y = -2; //align it correctly
    frame.size.height = 32;
    %orig(frame);
}
- (CGRect)bounds {
    CGRect frame = %orig;
    frame.origin.y = -2;
    frame.size.height = 32;
    return frame;
}
-(void)layoutSubviews {
    %orig;
    self.foregroundColor = [UIColor whiteColor]; //always white
}
%end

