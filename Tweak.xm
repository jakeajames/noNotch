#include <substrate.h>
#include <UIKit/UIStatusBar.h>
#import <CoreGraphics/CoreGraphics.h>
#include <SpringBoard/SpringBoard.h>
#include <AppSupport/CPDistributedMessagingCenter.h>
#import <rocketbootstrap/rocketbootstrap.h>

CPDistributedMessagingCenter *messagingCenter; //message center

UIWindow *noNotchW; //window which will contain everything
UIView *noNotch; //the black border which will cover the notch
UIView *cover; //a supporting view which will help us hide and show the status bar
UIAccelerometer *accelerometer;
UIInterfaceOrientation oldOrientation;

//our hide and show methods. Add a nice transition
void hide() {
    [UIView animateWithDuration:1.0 animations:^(void) {
        noNotchW.alpha = 0;
    }];
}
void show() {
    if (oldOrientation != 1) return;
    [UIView animateWithDuration:1.0 animations:^(void) {
        noNotchW.alpha = 1;
    }];
}
void hideSB() {
    [UIView animateWithDuration:1.0 animations:^(void) {
        cover.alpha = 0;
    }];
}
void showSB() {
    [UIView animateWithDuration:1.0 animations:^(void) {
        cover.alpha = 1;
    }];
}

@interface SpringBoard ()
-(BOOL)isShowingHomescreen;
@end

@interface UIApplication ()
-(int)activeInterfaceOrientation;
@end

@interface UIStatusBarWindow : UIWindow
@end

@interface UIStatusBarWindow () <UIAccelerometerDelegate>
@end

@interface _UIStatusBar : UIView
@property (nonatomic, retain) UIColor *foregroundColor;
@end

BOOL isOnSpringBoard() {
    return [((SpringBoard*)[%c(SpringBoard) sharedApplication]) isShowingHomescreen];
}

%group SBHooks
%hook UIStatusBarWindow

- (void)layoutSubviews
{
    
    CGRect wholeFrame = [UIScreen mainScreen].bounds; //whole screen
    CGRect sbFrame = wholeFrame;
    sbFrame.size.height = 32;
    CGRect frame = CGRectMake(-50, -16, wholeFrame.size.width+100, wholeFrame.size.height+200); //this is the border which will cover the notch
    
    if (!noNotchW) {
        [messagingCenter registerForMessageName:@"hide" target:self selector:@selector(hide:)];
        [messagingCenter registerForMessageName:@"hide2" target:self selector:@selector(hide:)]; //apps need special treatment
        [messagingCenter registerForMessageName:@"show" target:self selector:@selector(show:)];
        
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
    ((UIView*)statusBar).tag = 414141;
    [cover addSubview:(UIView*)statusBar]; //add status bar inside our supporting view
    [noNotchW addSubview:cover]; //add supporting view inside the window
    
    //start listening for orientation changes
    if (!accelerometer) {
        accelerometer = [UIAccelerometer sharedAccelerometer];
        accelerometer.updateInterval = 0.5; //listen every half a second
        accelerometer.delegate = self;
    }
    
    %orig; //make SpringBoard do whatever it was gonna do before we kicked in and stole the notch
}

%new
- (void)accelerometer:(UIAccelerometer *)meter didAccelerate:(UIAcceleration *)acceleration {
    //if old orientation isn't equal to current orientation => orientation changed
    if (oldOrientation != [[%c(SpringBoard) sharedApplication] activeInterfaceOrientation]) {
        oldOrientation = [[%c(SpringBoard) sharedApplication] activeInterfaceOrientation];
        if (oldOrientation == 1 && noNotchW.alpha != 1)
            show();
        else if (oldOrientation != 1 && noNotchW.alpha != 0)
            hide();
    }
}
%new
- (void)hide:(NSString *)name {
    if ([name isEqualToString:@"hide2"] && isOnSpringBoard()) return;
    [UIView animateWithDuration:1.0 animations:^(void) {
        noNotchW.alpha = 0;
    }];
}
%new
- (void)show:(NSString *)name {
    [UIView animateWithDuration:1.0 animations:^(void) {
        noNotchW.alpha = 1;
    }];
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
    if (((UIView*)self).tag == 414141)
        %orig(1);
    else
        %orig(arg1);
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
/*%hook SpringBoard
-(void)frontDisplayDidChange:(id)newDisplay {
    %orig;
    
    if ([newDisplay isKindOfClass:%c(SBApplication)]) {
        if (cover.alpha == 0)
            showSB();
        if (noNotchW.alpha == 0)
            show();
    }
    
}
%end*/
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
-(void)grabberTongueBeganPulling:(id)arg1 withDistance:(double)arg2 andVelocity:(double)arg3 {
    if (cover.alpha != 0)
        hideSB();
    %orig;
}
-(void)_didDismiss {
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
%end

%group AppHooks
//if status bar is hidden => fullscreen app, therefore we need to hide the notch cover
%hook UIStatusBar_Base
-(void)setAlpha:(CGFloat)arg1 {
    if (arg1 == 0)
        [messagingCenter sendMessageName:@"hide2" userInfo:nil];
    else
        [messagingCenter sendMessageName:@"show" userInfo:nil];
    %orig(arg1);
}
-(void)setHidden:(BOOL)arg1 {
    if (arg1 == YES)
        [messagingCenter sendMessageName:@"hide2" userInfo:nil];
    else
        [messagingCenter sendMessageName:@"show" userInfo:nil];
    %orig(arg1);
}
-(CGFloat)alpha {
    if (%orig == 0)
        [messagingCenter sendMessageName:@"hide2" userInfo:nil];
    else
        [messagingCenter sendMessageName:@"show" userInfo:nil];
    return %orig;
}
-(BOOL)isHidden {
    if (%orig == YES)
        [messagingCenter sendMessageName:@"hide2" userInfo:nil];
    else
        [messagingCenter sendMessageName:@"show" userInfo:nil];
    return %orig;
}
%end
//check again after we reopen the app. This doesn't seem to be working that well
%hook UIApplicationDelegate
- (void)applicationDidBecomeActive:(UIApplication *)application {
    if ([[[[UIApplication sharedApplication] valueForKey:@"statusBarWindow"] valueForKey:@"statusBar"] alpha] == 0 || [[[[UIApplication sharedApplication] valueForKey:@"statusBarWindow"] valueForKey:@"statusBar"] isHidden] == YES)
        [messagingCenter sendMessageName:@"hide" userInfo:nil];
    %orig(application);
}
%end
%end

%ctor {
    messagingCenter = [CPDistributedMessagingCenter centerNamed:@"com.jakeashacks.noNotch"]; //setup our message center
    rocketbootstrap_distributedmessagingcenter_apply(messagingCenter); //use rocketbootstrap to get around sandbox limits
    
    if ([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.springboard"]) {
        [messagingCenter runServerOnCurrentThread];
        %init(SBHooks);
    }
    else {
        %init(AppHooks);
    }
}


    

