#include <substrate.h>
#include <UIKit/UIStatusBar.h>
#import <CoreGraphics/CoreGraphics.h>
#include <SpringBoard/SpringBoard.h>

%hook SpringBoard

%property (nonatomic, assign) UIWindow *window; //add a new UIWindow property

- (void)applicationDidFinishLaunching:(UIApplication *)arg1
{
    CGRect wholeFrame = [UIScreen mainScreen].bounds; //whole screen
    CGRect frame = CGRectMake(-40.5, 0, wholeFrame.size.width+81, wholeFrame.size.height+200); //this is the border which will cover the notch
    
    self.window = [[UIWindow alloc] initWithFrame:wholeFrame]; //whole screen size goes to the window
    self.window.windowLevel = UIWindowLevelStatusBar-10; //make this be under the status bar
    self.window.hidden = NO; //we don't want it hidden for whatever reason
    
    UIView *blackView = [[UIView alloc] initWithFrame:frame]; //the notch view
    blackView.layer.borderColor = [UIColor blackColor].CGColor; //add a black border
    blackView.layer.borderWidth = 40.0f; //something thinner than the status bar
    
    [blackView setClipsToBounds:YES]; //we want the border to be round
    [blackView.layer setMasksToBounds:YES]; //^^
    blackView.layer.cornerRadius = 75; //corner radius
    self.window.userInteractionEnabled = NO; //we don't want our view to prevent touches
    [self.window addSubview: blackView]; //add our notch cover!
    
    %orig; //make SpringBoard do whatever it was gonna do before we kicked in and stole the notch
}


%end


