@interface UIStatusBarWindow : UIView
@property (nonatomic, assign) UIView *noNotch; //add a new UIWindow property (Call it something unique so it doesnt mess with any other tweaks)
@property (nonatomic, assign) UIView *cutoutView; //add a new UIWindow property (I like to make properties)
@end

@interface _UIStatusBar : UIView
@property (nonatomic, retain) UIColor *foregroundColor;
@end

@interface UIStatusBar_Base : UIView
-(int)currentStyle;
@end

%hook UIStatusBarWindow
%property (nonatomic, assign) UIView *noNotch; //add a new UIWindow property (Call it something unique so it doesnt mess with any other tweaks)
%property (nonatomic, assign) UIView *cutoutView; //add a new UIWindow property (I like to make properties)
- (void)layoutSubviews {
  %orig;
  if(!self.noNotch){
    CGRect wholeFrame = [UIScreen mainScreen].bounds; // Screen Boundries

    self.noNotch = [[UIView alloc] initWithFrame:wholeFrame]; //whole screen size goes to the window
    self.noNotch.userInteractionEnabled = NO; // Ensures that touches are passed through.
    self.noNotch.backgroundColor = [UIColor blackColor];
    [self addSubview:self.noNotch];

    self.cutoutView = [[UIView alloc] initWithFrame:CGRectMake(0,30,wholeFrame.size.width,wholeFrame.size.height-30)]; //the notch view (The 32px is the height of the Notch
    self.cutoutView.backgroundColor = [UIColor blackColor];
    self.cutoutView.userInteractionEnabled = NO; // Ensures that touches are passed through.
    self.cutoutView.layer.compositingFilter = @"destOut"; // Special filter used in iOS 11 to cut out stuff.
    self.cutoutView.layer.cornerRadius = 39; // Corner Radius of iPhone X
    [self addSubview:self.cutoutView]; // Add our cutout view.

    [self sendSubviewToBack:self.cutoutView];
    [self sendSubviewToBack:self.noNotch];
  }
  UIStatusBar_Base *statusBar = [self valueForKey:@"_statusBar"];
  statusBar.tag = 313123; // Tag which status bar is ours to use later.
}
-(void)setHidden:(BOOL)arg1{
  %orig(FALSE);
}
%end

%hook UIStatusBar_Base
-(void)setAlpha:(CGFloat)arg1 {
  if(self.tag == 313123) // Seeing as we want our system to work litterally everywhere we need to make sure our status bar isnt hidden.
    arg1 = 1;

  %orig(arg1);
}
%end

// We could just stop there but the statusBar sits on the edge of this. We want to minimise our impact on screen realestate so we move the status bar up.

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
-(void)layoutSubviews {
  %orig;
  self.foregroundColor = [UIColor whiteColor];
}
%end
