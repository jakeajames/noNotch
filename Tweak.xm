#include <substrate.h>
#include <UIKit/UIStatusBar.h>
#import <CoreGraphics/CoreGraphics.h>
#include <SpringBoard/SpringBoard.h>

UIWindow *noNotchW; //window which will contain everything
UIView *noNotch; //the black border which will cover the notch
UIView *cover; //a supporting view which will help us hide and show the status bar

//our hide and show methods. Add a nice transition
void hide() {
    [UIView animateWithDuration:1.0 animations:^(void) {
        noNotchW.alpha = 1;
        noNotchW.alpha = 0;
    }];
}
void show() {
    [UIView animateWithDuration:1.0 animations:^(void) {
        noNotchW.alpha = 0;
        noNotchW.alpha = 1;
    }];
}
void hideSB() {
    [UIView animateWithDuration:1.0 animations:^(void) {
        cover.alpha = 1;
        cover.alpha = 0;
    }];
}
void showSB() {
    [UIView animateWithDuration:1.0 animations:^(void) {
        cover.alpha = 0;
        cover.alpha = 1;
    }];
}

@interface UIStatusBarWindow : UIWindow
@end

@interface _UIStatusBar : UIView
@property (nonatomic, retain) UIColor *foregroundColor;
@end

%hook UIStatusBarWindow

- (void)layoutSubviews
{
    
    CGRect wholeFrame = [UIScreen mainScreen].bounds; //whole screen
    CGRect sbFrame = wholeFrame;
    sbFrame.size.height = 32;
    CGRect frame = CGRectMake(-50, -16, wholeFrame.size.width+100, wholeFrame.size.height+200); //this is the border which will cover the notch
    
    if (!noNotchW) {
        noNotchW = [[UIWindow alloc] initWithFrame:sbFrame]; //window will be as small as the status bar
        cover = [[UIView alloc] initWithFrame:sbFrame]; //the support view
    }
    
    if (!noNotch) {
        noNotch = [[UIView alloc] initWithFrame:frame]; //the notch view
    }
    noNotch.layer.borderColor = [UIColor blackColor].CGColor; //add a black border
    noNotch.layer.borderWidth = 50.0f; //something thinner than the status bar
    
    [noNotch setClipsToBounds:YES]; //we want the border to be round
    [noNotch.layer setMasksToBounds:YES]; //^^
    noNotch.layer.cornerRadius = 70; //corner radius
    
    noNotchW.windowLevel = 1096;
    noNotchW.hidden = NO; //we don't want it hidden for whatever reason
    noNotchW.userInteractionEnabled = YES; //touches will pass through the window
    noNotch.userInteractionEnabled = NO; //they won't pass through the notch cover because that's big and will block touches
    cover.userInteractionEnabled = YES; //touches will pass through the status bar
    
    [noNotchW addSubview:noNotch]; //add the notch cover inside the window
    UIStatusBar_Base *statusBar = [self valueForKey:@"_statusBar"];
    [cover addSubview:(UIView*)statusBar]; //add status bar inside our supporting view
    [noNotchW addSubview:cover]; //add supporting view inside the window
    
    %orig; //make SpringBoard do whatever it was gonna do before we kicked in and stole the notch
}

%end

//status bar window always visible
%hook UIStatusBarWindow
-(void)setHidden:(BOOL)arg1 {
    %orig(NO);
}
%end

//status bar always visible
%hook UIStatusBar_Base
-(void)setAlpha:(CGFloat)arg1 {
    //if the system wants to show the status bar make sure the notch cover window is also there
    if (arg1 == 1) {
        if (noNotchW.alpha == 0)
            show();
    }
    %orig(1);
}

%end

//align the status bar properly
%hook _UIStatusBar
- (void)setFrame:(CGRect)frame {
    frame.origin.y = -2;
    frame.size.height = 32;
    %orig(frame);
}
- (CGRect)bounds {
    CGRect frame = %orig;
    frame.origin.y = -2;
    frame.size.height = 32;
    return frame;
}
//make the status bar always white
-(void)layoutSubviews {
    %orig;
    self.foregroundColor = [UIColor whiteColor];
}
%end

//when we open an app make sure the notch cover is visible
%hook SpringBoard
-(void)frontDisplayDidChange:(id)newDisplay {
    %orig;
    
    if ([newDisplay isKindOfClass:%c(SBApplication)]) {
        if (cover.alpha == 0)
            showSB();
        if (noNotchW.alpha == 0)
            show();
    }
    
}
%end
//when control center is opened hide the status bar
%hook SBControlCenterController
-(void)presentAnimated:(BOOL)arg1 {
    if (cover.alpha != 0)
        hideSB();
    %orig;
}
-(void)presentAnimated:(BOOL)arg1 completion:(id)arg2 {
    if (cover.alpha != 0)
        hideSB();
    %orig;
}
//when control center is dismissed show the status bar
-(void)dismissAnimated:(BOOL)arg1 {
    if (cover.alpha == 0)
        showSB();
    %orig;
}
-(void)dismissAnimated:(BOOL)arg1 completion:(id)arg2 {
    if (cover.alpha == 0)
        showSB();
    %orig;
}
%end

//get rid of the notch cover when user enters wiggle mode. Can't think of an alternative
%hook SBEditingDoneButton
-(id)initWithFrame:(CGRect)arg1 {
    if (noNotchW.alpha != 0)
        hide();
    return %orig;
}
%end

