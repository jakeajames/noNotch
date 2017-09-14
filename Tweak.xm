#include <substrate.h>
#include <UIKit/UIStatusBar.h>
#import <CoreGraphics/CoreGraphics.h>
#include <SpringBoard/SpringBoard.h>


@interface UIStatusBar (noNotch)
@property (nonatomic, copy, readwrite) UIColor *foregroundColor;
@end

%hook UIStatusBarWindow
-(void)layoutSubviews {
%orig;
//could have as well just changed background color of current status bar, but this way I have more freedom to customize, i.e add cornerRadius
//ik formatting sucks

UIStatusBar *status = MSHookIvar<UIStatusBar *>(self, "_statusBar");
status.foregroundColor = [UIColor whiteColor];

CGRect frame = CGRectMake(0, 0, 375, 44);

UIView *newStatus = [[UIView alloc] initWithFrame:frame];
newStatus.layer.cornerRadius = 20;
newStatus.layer.masksToBounds = YES;
[newStatus setBackgroundColor:[UIColor blackColor]];

[self addSubview:newStatus];
[self bringSubviewToFront:status];


}
%end


