@import <AppKit/CPView.j>
@import <AppKit/CPApplication.j>

var methodCalled;

@implementation CPViewTest : OJTestCase
{
    CPView view;
    CPView view1;
    CPView view2;
    CPView view3;

    CPWindow window;
}

- (void)setUp
{
    // This will init the global var CPApp which are used internally in the AppKit
    [[CPApplication alloc] init];

    window = [[CPWindow alloc] initWithContentRect:CGRectMake(0.0, 0.0, 1000.0, 1000.0) styleMask:CPWindowNotSizable];

    view = [[CPView alloc] initWithFrame:CGRectMakeZero()];
    view1 = [[CPResponderView alloc] initWithFrame:CGRectMakeZero()];
    view2 = [[CPResponderView alloc] initWithFrame:CGRectMakeZero()];
    view3 = [[CPResponderView alloc] initWithFrame:CGRectMakeZero()];

    [view1 setIdentifier:@"view1"];
    [view2 setIdentifier:@"view2"];
    [view3 setIdentifier:@"view3"];

    methodCalled = [];

    [super setUp];
}

- (void)testCanCreate
{
    [self assertTrue:!!view];
}

/*
    During the layout process for the view, _CPImageAndTextView.j throws
    a ReferenceError with the following:

        "hasDOMImageElement" is not defined

    The referenced variable is #if PLATFORM(DOM) excluded in all other
    instances. While not isolated to the behaviour of a CPView alone, the
    following test ensures that pending actions in the _CPDisplayServer can
    be flushed without touching unimplemented portions of the test platform
    (e.g. the DOM). There are times where we want to confirm that some setting
    requiring relayout (e.g. string truncation based on available space), the
    following test should help ensure those types of tests are safe to carry
    out with ojunit.

    Demonstrates issue #562.
*/
- (void)testCanFlushPendingLayoutWork
{
    [self assert:undefined same:[_CPDisplayServer run]];
}

- (void)testHasThemeState
{
    [self assertTrue:[view hasThemeState:CPThemeStateNormal] message:@"By default, CPView should be in CPThemeStateNormal"];

    view._themeState = CPThemeState(CPThemeStateDisabled, CPThemeStateBordered);
    [self assertTrue:[view hasThemeState:CPThemeStateDisabled] message:@"CPView should be in state CPThemeStateDisabled"];
    [self assertTrue:[view hasThemeState:CPThemeStateBordered] message:@"CPView should be in state CPThemeStateBordered"];
    [self assertTrue:[view hasThemeState:CPThemeState(CPThemeStateBordered, CPThemeStateDisabled)] message:@"CPView should be in the combined state of CPThemeStateDisabled and CPThemeStateBordered"];
    [self assertTrue:[view hasThemeStates:[CPThemeStateBordered, CPThemeStateDisabled]] message:@"hasThemeState works with an array argument"];
    [self assertFalse:[view hasThemeState:CPThemeState(CPThemeStateNormal)] message:@"CPView should not be in CPThemeStateNormal"];
}

- (void)testSetThemeState
{
    [self assert:String(CPThemeStateNormal) equals:String([view themeState]) message:@"CPView should initialy have CPThemeStateNormal"];

    [view setThemeState:CPThemeStateDisabled];
    [self assert:String(CPThemeStateDisabled) equals:String([view themeState]) message:@"The view should be CPThemeStateDisabled"];

    [view setThemeState:CPThemeStateHighlighted];
    [self assert:String(CPThemeState(CPThemeStateDisabled, CPThemeStateHighlighted)) equals:String([view themeState]) message:@"Theme state should be CPThemeStateHighlighted and CPThemeStateDisabled"];

    [view unsetThemeState:[view themeState]];
    [view setThemeState:CPThemeState(CPThemeStateNormal, CPThemeStateHighlighted)];
    [self assertFalse:[view hasThemeState:CPThemeStateNormal] message:@"CPThemeStateNormal cannot exist as part of a compound state"];
    [self assert:String([view themeState]) equals:String(CPThemeStateHighlighted) message:@"The view should be CPThemeStateHighlighted"];

    [view setThemeState:CPThemeState(CPThemeStateHighlighted, CPThemeStateDisabled)];
    [self assertTrue:[view hasThemeState:CPThemeStateHighlighted] message:@"The view should be CPThemeStateHighlighted"];
    [self assertTrue:[view hasThemeState:CPThemeStateDisabled] message:@"The view should be CPThemeStateDisabled"];
    [self assert:String(CPThemeState(CPThemeStateDisabled, CPThemeStateHighlighted)) equals:String([view themeState]) message:@"The view should be in the combined state of CPThemeStateDisabled and CPThemeStateHighlighted"];

    [view unsetThemeState:[view themeState]];
    [view setThemeStates:[CPThemeStateSelected, CPThemeStateDisabled]];
    [self assert:String(CPThemeState(CPThemeStateDisabled, CPThemeStateSelected)) equals:String([view themeState]) message:@"setThemeState works with array argument"];
}

- (void)testUnsetThemeState
{
    [self assert:String(CPThemeStateNormal) equals:String([view themeState]) message:@"CPView should initialy have CPThemeStateNormal"];
    [view unsetThemeState:CPThemeStateNormal];
    [self assert:String(CPThemeStateNormal) equals:String([view themeState]) message:@"CPView always be in CPThemeStateNormal even if you try to unset it"];

    [view setThemeState:CPThemeStateDisabled];
    [view unsetThemeState:CPThemeStateDisabled];
    [self assert:String(CPThemeStateNormal) equals:String([view themeState]) message:@"CPView should be in CPThemeStateNormal when all other theme states have been unset from it"];

    [view setThemeState:CPThemeState(CPThemeStateDisabled, CPThemeStateHighlighted)];
    [view unsetThemeState:CPThemeStateDisabled];
    [self assert:String(CPThemeStateHighlighted) equals:String([view themeState]) message:"@CPView should have the remaining state when one of its combined states is unset"];

    [view setThemeState:CPThemeState(CPThemeStateDisabled, CPThemeStateHighlighted, CPThemeStateBordered)];
    [view unsetThemeState:CPThemeState(CPThemeStateBordered, CPThemeStateHighlighted, CPThemeStateDisabled)];
    [self assert:String(CPThemeStateNormal) equals:String([view themeState]) message:@"CPView should be able to unset a combined theme state"];

    [view setThemeState:CPThemeState(CPThemeStateDisabled, CPThemeStateHighlighted, CPThemeStateBordered)];
    [view unsetThemeStates:[CPThemeStateBordered, CPThemeStateHighlighted]];
    [self assert:String(CPThemeStateDisabled) equals:String([view themeState]) message:@"unsetThemeState works with array argument"];

    [view setThemeState:CPThemeStateDisabled];
    [view unsetThemeStates:[CPThemeStateDisabled, CPThemeStateHighlighted]];
    [self assert:String(CPThemeStateNormal) equals:String([view themeState]) message:@"CPView should be able to unset a combined theme state that has more theme states than the view currently has"];

    [view setThemeState:CPThemeState(CPThemeStateDisabled, CPThemeStateBordered)];
    var returnValue = [view unsetThemeStates:[CPThemeStateDisabled, CPThemeStateHighlighted]];
    [self assert:String(CPThemeStateBordered) equals:String([view themeState]) message:@"CPView should be able to unset a combined theme state that has not entirely overlapping themestates"];
    [self assertTrue:returnValue message:@"When unsetThemeState successfully unsets anything, it return YES"];

    [view setThemeState:CPThemeState(CPThemeStateDisabled, CPThemeStateBordered)];
    var returnValue = [view unsetThemeStates:[CPThemeStateSelected, CPThemeStateHighlighted]];
    [self assert:String(CPThemeState(CPThemeStateDisabled, CPThemeStateBordered)) equals:String([view themeState]) message:@"CPView not unset any theme states it does not have"];
    [self assertFalse:returnValue message:@"When unsetThemeState doesn't unset anything, it returns NO"];

    [view setThemeState:CPThemeState(CPThemeStateDisabled, CPThemeStateBordered)];
    var returnValue = [view unsetThemeState:null];
    [self assert:String(CPThemeState(CPThemeStateDisabled, CPThemeStateBordered)) equals:String([view themeState]) message:@"Trying to unset a null themestate does not change the current themestate of the view"];
    [self assertFalse:returnValue message:@"Trying to unset a null themestate returns false"];
}

- (void)testThemeAttributes
{
    var attributes = [CPView themeAttributes];

    if (attributes)
    {
        var keys = [attributes allKeys],
            firstKey = [keys objectAtIndex:0];

        [self assertTrue:[view hasThemeAttribute:[firstKey]] message:[view className] + " should have the theme attribute \"" + firstKey + "\""];
    }

    [self assertFalse:[view hasThemeAttribute:@"foobar"] message:[view className] + " should not have theme attribute \"" + firstKey + "\""];
}

- (void)testIsVisible
{
    [self assertFalse:[view _isVisible] message:"view must belong to a window to be visible"];
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView];

    [self assertFalse:[contentView _isVisible] message:"view must belong to a visible window to be visible"];
    [theWindow orderFront:self];
    // Fake this because we don't have the DOM in unit tests.
    [theWindow._isVisible = YES];
    [self assertTrue:[contentView _isVisible] message:"view is the content view of a visible window, hence visible"];

    [self assertFalse:[view _isVisible] message:"view must belong to a window to be visible"];
    [contentView addSubview:view];
    [self assertTrue:[view _isVisible] message:"view is a subview of a visible content view, hence visible"];

    [view setHidden:YES];
    [self assertFalse:[view _isVisible] message:"view is hidden"];

    [view setHidden:NO];
    [self assertTrue:[view _isVisible] message:"view is not hidden again"];

    [contentView setHidden:YES];
    [self assertFalse:[view _isVisible] message:"a superview is hidden"];

    [contentView setHidden:NO];
    [contentView removeFromSuperview];
    [self assertFalse:[view _isVisible] message:"a superview does not belong to a visible window"];
}

- (void)testNextValidKeyView
{
    var viewA = [CPView new],
        viewB = [CPView new],
        viewC = [CPCollectionView new],
        viewD = [CPView new],
        viewE = [CPView new];

    [viewA setNextKeyView:viewB];
    [viewB setNextKeyView:viewC];

    [self assert:viewC equals:[viewA nextValidKeyView]];

    // Make a loop which is harder to detect.
    [viewA setNextKeyView:viewB];
    [viewB setNextKeyView:viewD];
    [viewD setNextKeyView:viewE];
    [viewE setNextKeyView:viewD];

    [self assert:nil equals:[viewA nextValidKeyView]];
}

- (void)testConvertPoint_fromView_shouldChangeNothingForSameView
{
    var tView0 = [CPView new],
        aWindow = [CPWindow new];

    [aWindow setContentView:tView0];

    [tView0 setFrame:CGRectMake(3, 5, 13, 17)];

    [self assertTrue:CGPointEqualToPoint(CGPointMake(7, 11), [tView0 convertPoint:CGPointMake(7, 11) fromView:tView0])]
}

- (void)testConvertPoint_fromView_shouldAddSubviewCoordinatesWhenMovingUp
{
    var tView0 = [CPView new],
        subView0 = [CPView new],
        aWindow = [CPWindow new];

    [aWindow setContentView:tView0];

    [tView0 addSubview:subView0];
    [tView0 setFrame:CGRectMake(30, 50, 130, 170)];
    [subView0 setFrame:CGRectMake(3, 5, 13, 17)];

    [self assertTrue:CGPointEqualToPoint(CGPointMake(10, 16), [tView0 convertPoint:CGPointMake(7, 11) fromView:subView0])]
}

- (void)testConvertPoint_fromView_shouldWorkBetweenSiblingViews
{
    var tView0 = [CPView new],
        subView0 = [CPView new],
        aWindow = [CPWindow new];

    [[aWindow contentView] addSubview:tView0];
    [[aWindow contentView] addSubview:subView0];

    [tView0 setFrame:CGRectMake(30, 50, 130, 170)];
    [subView0 setFrame:CGRectMake(3, 5, 13, 17)];

    [self assertTrue:CGPointEqualToPoint(CGPointMake(34, 56), [subView0 convertPoint:CGPointMake(7, 11) fromView:tView0])]
}

- (void)testConvertPoint_fromView_shouldSubtractSubviewCoordinatesWhenMovingDown
{
    var tView0 = [CPView new],
        subView0 = [CPView new],
        aWindow = [CPWindow new];

    [aWindow setContentView:tView0];

    [tView0 addSubview:subView0];
    [tView0 setFrame:CGRectMake(30, 50, 130, 170)];
    [subView0 setFrame:CGRectMake(3, 5, 13, 17)];

    [self assertTrue:CGPointEqualToPoint(CGPointMake(4, 6), [subView0 convertPoint:CGPointMake(7, 11) fromView:tView0])]
}

+ (CPArray)createResponderView:(/*@ref */CPView)viewOut siblingView:(/*@ref */CPView)siblingViewOut inWindow:(/*@ref */CPWindow)windowOut
{
    var aView = [CPResponderView new],
        siblingView = [CPResponderView new],
        aWindow = [CPWindow new];

    [[aWindow contentView] addSubview:aView];
    [[aWindow contentView] addSubview:siblingView];

    if (viewOut)
        @deref(viewOut) = aView;
    if (siblingViewOut)
        @deref(siblingViewOut) = siblingView;
    if (windowOut)
        @deref(windowOut) = aWindow;

    return aView;
}

- (void)testWhenFirstResponderShouldHaveThemeStateFirstResponder
{
    var aView, siblingView, aWindow;
    [CPViewTest createResponderView:@ref(aView) siblingView:@ref(siblingView) inWindow:@ref(aWindow)];

    [self assertFalse:[aView hasThemeState:CPThemeStateFirstResponder]];
    [self assertFalse:[siblingView hasThemeState:CPThemeStateFirstResponder]];

    [aWindow makeFirstResponder:aView];
    [self assertTrue:[aView hasThemeState:CPThemeStateFirstResponder]];

    [aWindow makeFirstResponder:siblingView];
    [self assertTrue:[siblingView hasThemeState:CPThemeStateFirstResponder]];
}

- (void)testWhenChildOfFirstResponderShouldHaveThemeStateFirstResponder
{
    var aView, siblingView, aWindow;
    [CPViewTest createResponderView:@ref(aView) siblingView:@ref(siblingView) inWindow:@ref(aWindow)];
    var subview = [CPView new];
    [aView addSubview:subview];

    [aWindow makeFirstResponder:aView];
    [self assertTrue:[aView hasThemeState:CPThemeStateFirstResponder]];
    [self assertTrue:[subview hasThemeState:CPThemeStateFirstResponder]];
}

- (void)testWhenNotFirstResponderShouldLoseThemeStateFirstResponder
{
    var aView, siblingView, aWindow;
    [CPViewTest createResponderView:@ref(aView) siblingView:@ref(siblingView) inWindow:@ref(aWindow)];

    [aWindow makeFirstResponder:aView];
    [self assertFalse:[siblingView hasThemeState:CPThemeStateFirstResponder]];

    [aWindow makeFirstResponder:siblingView];
    [self assertFalse:[aView hasThemeState:CPThemeStateFirstResponder]];
}

- (void)testWhenNotChildOfFirstResponderShouldLoseThemeStateFirstResponder
{
    var aView, siblingView, aWindow;
    [CPViewTest createResponderView:@ref(aView) siblingView:@ref(siblingView) inWindow:@ref(aWindow)];
    var subview = [CPView new];
    [aView addSubview:subview];

    [aWindow makeFirstResponder:aView];
    [self assertTrue:[aView hasThemeState:CPThemeStateFirstResponder]];
    [self assertTrue:[subview hasThemeState:CPThemeStateFirstResponder]];

    [aWindow makeFirstResponder:siblingView];
    [self assertFalse:[aView hasThemeState:CPThemeStateFirstResponder]];
    [self assertFalse:[subview hasThemeState:CPThemeStateFirstResponder]];
}

- (void)testWhenFirstResponderButNotKeyWindowShouldStillHaveThemeStateFirstResponder
{
    var aView, siblingView, aWindow;
    [CPViewTest createResponderView:@ref(aView) siblingView:@ref(siblingView) inWindow:@ref(aWindow)];

    var aView2, siblingView2, aWindow2;
    [CPViewTest createResponderView:@ref(aView2) siblingView:@ref(siblingView2) inWindow:@ref(aWindow2)];

    [aWindow makeKeyWindow];
    [aWindow makeFirstResponder:aView];
    [self assertTrue:[aView hasThemeState:CPThemeStateFirstResponder]];

    [aWindow2 makeFirstResponder:siblingView];
    [aWindow2 makeKeyWindow];

    [self assertTrue:[aView hasThemeState:CPThemeStateFirstResponder]];
    [self assertTrue:[siblingView hasThemeState:CPThemeStateFirstResponder]];
}

- (void)testWhenChildOfFirstResponderButNotKeyWindowShouldStillHaveThemeStateFirstResponder
{
    var aView, siblingView, aWindow;
    [CPViewTest createResponderView:@ref(aView) siblingView:@ref(siblingView) inWindow:@ref(aWindow)];

    var subview = [CPView new];
    [aView addSubview:subview];

    var aView2, siblingView2, aWindow2;
    [CPViewTest createResponderView:@ref(aView2) siblingView:@ref(siblingView2) inWindow:@ref(aWindow2)];

    [aWindow makeKeyWindow];
    [aWindow makeFirstResponder:aView];
    [aWindow2 makeFirstResponder:siblingView];
    [aWindow2 makeKeyWindow];
    [self assertTrue:[subview hasThemeState:CPThemeStateFirstResponder]];
}

- (void)testWhenNotFirstResponderButNotKeyWindowShouldStillLoseThemeStateFirstResponder
{
    var aView, siblingView, aWindow;
    [CPViewTest createResponderView:@ref(aView) siblingView:@ref(siblingView) inWindow:@ref(aWindow)];

    var aView2, siblingView2, aWindow2;
    [CPViewTest createResponderView:@ref(aView2) siblingView:@ref(siblingView2) inWindow:@ref(aWindow2)];

    [aWindow makeKeyWindow];
    [aWindow makeFirstResponder:aView];
    [aWindow2 makeFirstResponder:siblingView];
    [aWindow2 makeKeyWindow];
    [aWindow makeFirstResponder:siblingView];

    [self assertFalse:[aView hasThemeState:CPThemeStateFirstResponder]];
}

- (void)testWhenNotChildOfFirstResponderButNotKeyWindowShouldShouldStillLoseThemeStateFirstResponder
{
    var aView, siblingView, aWindow;
    [CPViewTest createResponderView:@ref(aView) siblingView:@ref(siblingView) inWindow:@ref(aWindow)];

    var subview = [CPView new];
    [aView addSubview:subview];

    var aView2, siblingView2, aWindow2;
    [CPViewTest createResponderView:@ref(aView2) siblingView:@ref(siblingView2) inWindow:@ref(aWindow2)];

    [aWindow makeKeyWindow];
    [aWindow makeFirstResponder:aView];
    [aWindow2 makeFirstResponder:siblingView];
    [aWindow2 makeKeyWindow];
    [aWindow makeFirstResponder:siblingView];

    [self assertFalse:[subview hasThemeState:CPThemeStateFirstResponder]];
}

- (void)testWhenAndOnlyWhenWindowIsKeyEveryViewShouldHaveThemeStateKeyWindow
{
    var aView, siblingView, aWindow;
    [CPViewTest createResponderView:@ref(aView) siblingView:@ref(siblingView) inWindow:@ref(aWindow)];

    var subview = [CPView new];
    [aView addSubview:subview];

    var aView2, siblingView2, aWindow2;
    [CPViewTest createResponderView:@ref(aView2) siblingView:@ref(siblingView2) inWindow:@ref(aWindow2)];

    [aWindow makeKeyWindow];
    [self assertTrue:[aView hasThemeState:CPThemeStateKeyWindow]];
    [self assertTrue:[siblingView hasThemeState:CPThemeStateKeyWindow]];
    [self assertTrue:[subview hasThemeState:CPThemeStateKeyWindow]];
    [self assertFalse:[aView2 hasThemeState:CPThemeStateKeyWindow]];
    [self assertFalse:[siblingView2 hasThemeState:CPThemeStateKeyWindow]];

    [aWindow2 makeKeyWindow];
    [self assertFalse:[aView hasThemeState:CPThemeStateKeyWindow]];
    [self assertFalse:[siblingView hasThemeState:CPThemeStateKeyWindow]];
    [self assertFalse:[subview hasThemeState:CPThemeStateKeyWindow]];
    [self assertTrue:[aView2 hasThemeState:CPThemeStateKeyWindow]];
    [self assertTrue:[siblingView2 hasThemeState:CPThemeStateKeyWindow]];
}

- (void)testWhenFirstResponderBeforeBeingAddedSubviewShouldHaveThemeStateFirstResponder
{
    var aView, siblingView, aWindow;
    [CPViewTest createResponderView:@ref(aView) siblingView:@ref(siblingView) inWindow:@ref(aWindow)];

    [self assertFalse:[aView hasThemeState:CPThemeStateFirstResponder]];
    [self assertFalse:[siblingView hasThemeState:CPThemeStateFirstResponder]];

    [aWindow makeFirstResponder:aView];

    var subview = [CPView new];
    [aView addSubview:subview];
    [self assertTrue:[subview hasThemeState:CPThemeStateFirstResponder]];
}

- (void)testWhenRemovedSubviewShouldLoseThemeStateFirstResponder
{
    var aView, siblingView, aWindow;
    [CPViewTest createResponderView:@ref(aView) siblingView:@ref(siblingView) inWindow:@ref(aWindow)];

    [aWindow makeFirstResponder:aView];
    var subview = [CPView new];
    [aView addSubview:subview];
    [subview removeFromSuperview];
    [self assertFalse:[subview hasThemeState:CPThemeStateFirstResponder]];
}

- (void)testWhenAddedSubviewMethodCalled
{
    var expectedRestult = [@"viewWillMoveToSuperview_view1", @"viewDidMoveToSuperview_view1", "viewWillMoveToWindow_view1", "viewDidMoveToWindow_view1"];

    [[window contentView] addSubview:view1];

    [self assert:expectedRestult equals:methodCalled];
}

- (void)testWhenAddedSubviewWithoutWindowMethodCalled
{
    var expectedRestult = [@"viewWillMoveToSuperview_view2", @"viewDidMoveToSuperview_view2"];

    [view1 addSubview:view2];

    [self assert:expectedRestult equals:methodCalled];
}

- (void)testWhenAddedSubviewTwiceMethodCalled
{
    var expectedRestult = [@"viewWillMoveToSuperview_view1", @"viewDidMoveToSuperview_view1", "viewWillMoveToWindow_view1", "viewDidMoveToWindow_view1", @"viewWillMoveToSuperview_view1", @"viewDidMoveToSuperview_view1", "viewWillMoveToWindow_view1", "viewDidMoveToWindow_view1"];

    [[window contentView] addSubview:view1];
    [[window contentView] addSubview:view1];

    [self assert:expectedRestult equals:methodCalled];
}

- (void)testWhenRemovedSubviewMethodCalled
{
    var expectedRestult = [@"viewWillMoveToSuperview_view1", @"viewDidMoveToSuperview_view1"];

    [view1 removeFromSuperview];

    [self assert:expectedRestult equals:methodCalled];
}

- (void)testWhenAddedSubviewThenRemovedSubviewMethodCalled
{
    var expectedRestult = [@"viewWillMoveToSuperview_view1", @"viewDidMoveToSuperview_view1", "viewWillMoveToWindow_view1", "viewDidMoveToWindow_view1"];

    [[window contentView] addSubview:view1];

    methodCalled = [];
    [view1 removeFromSuperview];

    [self assert:expectedRestult equals:methodCalled];
}

- (void)testWhenAddedSubviewThenRemovedSubviewWithoutWindowMethodCalled
{
    var expectedRestult = [@"viewWillMoveToSuperview_view1", @"viewDidMoveToSuperview_view1"];

    [view1 addSubview:view2];

    methodCalled = [];
    [view1 removeFromSuperview];

    [self assert:expectedRestult equals:methodCalled];
}

- (void)testWhenAddedTwoSubviewsMethodCalled
{
    var expectedRestult = [@"viewWillMoveToSuperview_view2", @"viewDidMoveToSuperview_view2",@"viewWillMoveToSuperview_view1", @"viewDidMoveToSuperview_view1", "viewWillMoveToWindow_view1", "viewWillMoveToWindow_view2", "viewDidMoveToWindow_view2",  "viewDidMoveToWindow_view1"];

    [view1 addSubview:view2];
    [[window contentView] addSubview:view1];

    [self assert:expectedRestult equals:methodCalled];
}

- (void)testWhenAddedTwoSubviewsThenRemovedMethodCalled
{
    var expectedRestult = [@"viewWillMoveToSuperview_view1", @"viewDidMoveToSuperview_view1", "viewWillMoveToWindow_view1", "viewWillMoveToWindow_view2", "viewDidMoveToWindow_view2",  "viewDidMoveToWindow_view1"];

    [view1 addSubview:view2];
    [[window contentView] addSubview:view1];

    methodCalled = [];
    [view1 removeFromSuperview];

    [self assert:expectedRestult equals:methodCalled];
}

- (void)testWhenAddedTwoSubviewsThenAddedTheViewToAnotherViewWithoutWindowMethodCalled
{
    var expectedRestult = [@"viewWillMoveToSuperview_view1", @"viewDidMoveToSuperview_view1", @"viewWillMoveToWindow_view1", @"viewDidMoveToWindow_view1", @"viewWillMoveToSuperview_view1", @"viewDidMoveToSuperview_view1", @"viewWillMoveToWindow_view1", @"viewDidMoveToWindow_view1"];

    [[window contentView] addSubview:view1];
    [view2 addSubview:view1];

    [self assert:expectedRestult equals:methodCalled];
}

- (void)testWhenAddedOneSubviewsWithSetSubviewsMethodCalled
{
    var expectedRestult = [@"viewWillMoveToSuperview_view1", @"viewDidMoveToSuperview_view1", "viewWillMoveToWindow_view1", "viewDidMoveToWindow_view1"];

    [[window contentView] setSubviews:[view1]];

    [self assert:expectedRestult equals:methodCalled];
}

- (void)testWhenAddedTwoSubviewsWithSetSubviewsMethodCalled
{
    var expectedRestult = [@"viewWillMoveToSuperview_view1", @"viewDidMoveToSuperview_view1", "viewWillMoveToWindow_view1", "viewDidMoveToWindow_view1", @"viewWillMoveToSuperview_view2", @"viewDidMoveToSuperview_view2", "viewWillMoveToWindow_view2", "viewDidMoveToWindow_view2"];

    [[window contentView] setSubviews:[view1, view2]];

    [self assert:expectedRestult equals:methodCalled];
}

- (void)testWhenAddedTwoSubviewsThenSetSubviewsWithOneViewMethodCalled
{
    var expectedRestult = [@"viewWillMoveToSuperview_view2", @"viewDidMoveToSuperview_view2", "viewWillMoveToWindow_view2", "viewDidMoveToWindow_view2"];

    [[window contentView] setSubviews:[view1, view2]];

    methodCalled = [];

    [[window contentView] setSubviews:[view1]];

    [self assert:expectedRestult equals:methodCalled];
}

- (void)testWhenAddedTwoSubviewsThenSetSubviewsWithTwoViewsMethodCalled
{
    var expectedRestult = [@"viewWillMoveToSuperview_view2", @"viewDidMoveToSuperview_view2", "viewWillMoveToWindow_view2", "viewDidMoveToWindow_view2", @"viewWillMoveToSuperview_view3", @"viewDidMoveToSuperview_view3", "viewWillMoveToWindow_view3", "viewDidMoveToWindow_view3"];

    [[window contentView] setSubviews:[view1, view2]];

    methodCalled = [];

    [[window contentView] setSubviews:[view1, view3]];

    [self assert:expectedRestult equals:methodCalled];
}

- (void)testWhenReplacedViewWithSameViewMethodCalled
{
    var expectedRestult = [];

    [[window contentView] addSubview:view1];

    methodCalled = [];

    [[window contentView] replaceSubview:view1 with:view1];

    [self assert:expectedRestult equals:methodCalled];
}

- (void)testWhenReplacedViewWithOtherViewMethodCalled
{
    var expectedRestult = [@"viewWillMoveToSuperview_view2", @"viewDidMoveToSuperview_view2", "viewWillMoveToWindow_view2", "viewDidMoveToWindow_view2", @"viewWillMoveToSuperview_view1", @"viewDidMoveToSuperview_view1", "viewWillMoveToWindow_view1", "viewDidMoveToWindow_view1"];

    [[window contentView] addSubview:view1];

    methodCalled = [];

    [[window contentView] replaceSubview:view1 with:view2];

    [self assert:expectedRestult equals:methodCalled];
}

- (void)testWhenReplacedViewWithOtherAddedViewMethodCalled
{
    var expectedRestult = [@"viewWillMoveToSuperview_view2", @"viewDidMoveToSuperview_view2", "viewWillMoveToWindow_view2", "viewDidMoveToWindow_view2", @"viewWillMoveToSuperview_view1", @"viewDidMoveToSuperview_view1", "viewWillMoveToWindow_view1", "viewDidMoveToWindow_view1"];

    [[window contentView] addSubview:view1];
    [[window contentView] addSubview:view2];

    methodCalled = [];

    [[window contentView] replaceSubview:view1 with:view2];

    [self assert:expectedRestult equals:methodCalled];
}

- (void)testLayoutSubviews
{
    var layoutView = [[CPLayoutView alloc] initWithFrame:CGRectMakeZero()];

    [layoutView setIdentifier:@"layoutView"];

    [[window contentView] addSubview:layoutView];
    [layoutView setNeedsLayout]

    methodCalled = [];
    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];

    var expectedRestult = ["layoutSubivews_layoutView"];
    [self assert:expectedRestult equals:methodCalled];


    [layoutView setNeedsLayout]
    [layoutView setNeedsLayout]

    methodCalled = [];
    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];

    expectedRestult = ["layoutSubivews_layoutView"];
    [self assert:expectedRestult equals:methodCalled];


    [layoutView setNeedsLayout:YES]

    methodCalled = [];
    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];

    expectedRestult = ["layoutSubivews_layoutView"];
    [self assert:expectedRestult equals:methodCalled];


    [layoutView setNeedsLayout:YES];
    [layoutView setNeedsLayout:NO];

    methodCalled = [];
    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];

    expectedRestult = [];
    [self assert:expectedRestult equals:methodCalled];


    [layoutView setNeedsLayout:YES];
    [layoutView setNeedsLayout:NO];
    [layoutView setNeedsLayout:YES];

    methodCalled = [];
    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];

    expectedRestult = ["layoutSubivews_layoutView"];
    [self assert:expectedRestult equals:methodCalled];
}

- (void)testToolTipInitialEmpty
{
    [self assert:nil equals:view._toolTip];
    [self assert:nil equals:view._toolTipInstalled];
    [self assert:nil equals:view._toolTipFunctionIn];
    [self assert:nil equals:view._toolTipFunctionOut];
}

- (void)testToolTipWithToolTipAndNoWindow
{
    [view setToolTip:@"tooltip"];

    [self assert:@"tooltip" equals:view._toolTip];
    [self assert:nil equals:view._toolTipInstalled];
    [self assert:nil equals:view._toolTipFunctionIn];
    [self assert:nil equals:view._toolTipFunctionOut];
}

- (void)testToolTipWithToolTipAndWindow
{
    [view setToolTip:@"tooltip"];

    [[window contentView] addSubview:view]

    [self assert:@"tooltip" equals:view._toolTip];
    [self assertTrue:view._toolTipInstalled];
    [self assertTrue:!!view._toolTipFunctionIn];
    [self assertTrue:!!view._toolTipFunctionOut];
}

- (void)testToolTipWithToolTipAndWindowThenNoWindow
{
    [view setToolTip:@"tooltip"];

    [[window contentView] addSubview:view]
    [view removeFromSuperview];

    [self assert:@"tooltip" equals:view._toolTip];
    [self assert:NO equals:view._toolTipInstalled];
    [self assert:nil equals:view._toolTipFunctionIn];
    [self assert:nil equals:view._toolTipFunctionOut];
}

- (void)testToolTipWithNoToolTipAndWindowThenNoWindowThenToolTip
{
    [self assert:nil equals:view._toolTip];
    [self assert:nil equals:view._toolTipInstalled];
    [self assert:nil equals:view._toolTipFunctionIn];
    [self assert:nil equals:view._toolTipFunctionOut];

    [[window contentView] addSubview:view];

    [self assert:nil equals:view._toolTip];
    [self assert:nil equals:view._toolTipInstalled];
    [self assert:nil equals:view._toolTipFunctionIn];
    [self assert:nil equals:view._toolTipFunctionOut];

    [view setToolTip:@"tooltip"];

    [self assert:@"tooltip" equals:view._toolTip];
    [self assertTrue:view._toolTipInstalled];
    [self assertTrue:!!view._toolTipFunctionIn];
    [self assertTrue:!!view._toolTipFunctionOut];

    [view removeFromSuperview];

    [self assert:@"tooltip" equals:view._toolTip];
    [self assert:NO equals:view._toolTipInstalled];
    [self assert:nil equals:view._toolTipFunctionIn];
    [self assert:nil equals:view._toolTipFunctionOut];
}

- (void)testAppearanceDefaultvalue
{
    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];

    [self assert:nil equals:[view appearance]];
    [self assertFalse:[view hasThemeState:CPThemeStateAppearanceVibrantDark]];
    [self assertFalse:[view hasThemeState:CPThemeStateAppearanceVibrantLight]];
    [self assert:nil equals:[view effectiveAppearance]];
}

- (void)testAppearanceWithVibrantDark
{
    [view setAppearance:[CPAppearance appearanceNamed:CPAppearanceNameVibrantDark]];
    [self assert:[CPAppearance appearanceNamed:CPAppearanceNameVibrantDark] equals:[view appearance]];
    [self assert:[CPAppearance appearanceNamed:CPAppearanceNameVibrantDark] equals:[view effectiveAppearance]];

    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
    [self assertTrue:[view hasThemeState:CPThemeStateAppearanceVibrantDark]];
    [self assertFalse:[view hasThemeState:CPThemeStateAppearanceVibrantLight]];
}

- (void)testAppearanceWithVibrantLight
{
    [view setAppearance:[CPAppearance appearanceNamed:CPAppearanceNameVibrantLight]];

    [self assert:[CPAppearance appearanceNamed:CPAppearanceNameVibrantLight] equals:[view appearance]];
    [self assert:[CPAppearance appearanceNamed:CPAppearanceNameVibrantLight] equals:[view effectiveAppearance]];

    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
    [self assertTrue:[view hasThemeState:CPThemeStateAppearanceVibrantLight]];
    [self assertFalse:[view hasThemeState:CPThemeStateAppearanceVibrantDark]];
}

- (void)testAppearanceReset
{
    [view setAppearance:[CPAppearance appearanceNamed:CPAppearanceNameVibrantLight]];
    [view setAppearance:nil];

    [self assert:nil equals:[view appearance]];
    [self assert:nil equals:[view effectiveAppearance]];

    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
    [self assertFalse:[view hasThemeState:CPThemeStateAppearanceVibrantLight]];
    [self assertFalse:[view hasThemeState:CPThemeStateAppearanceVibrantDark]];
}

- (void)testEffectiveAppearance
{
    var secondView = [[CPView alloc] initWithFrame:CGRectMakeZero()];

    [view addSubview:secondView];

    [self assert:nil equals:[secondView appearance]];

    [view setAppearance:[CPAppearance appearanceNamed:CPAppearanceNameVibrantLight]];

    [self assert:[CPAppearance appearanceNamed:CPAppearanceNameVibrantLight] equals:[secondView effectiveAppearance]];
}

- (void)testEffectiveAppearanceWithMovingViews
{
    var viewA = [[CPView alloc] initWithFrame:CGRectMakeZero()],
        viewB = [[CPView alloc] initWithFrame:CGRectMakeZero()];

    [viewA setAppearance:[CPAppearance appearanceNamed:CPAppearanceNameVibrantLight]];
    [viewB setAppearance:[CPAppearance appearanceNamed:CPAppearanceNameVibrantDark]];

    [viewA addSubview:view];

    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
    [self assert:[CPAppearance appearanceNamed:CPAppearanceNameVibrantLight] equals:[view effectiveAppearance]];
    [self assertTrue:[view hasThemeState:CPThemeStateAppearanceVibrantLight]];
    [self assertFalse:[view hasThemeState:CPThemeStateAppearanceVibrantDark]];

    [viewB addSubview:view];

    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
    [self assert:[CPAppearance appearanceNamed:CPAppearanceNameVibrantDark] equals:[view effectiveAppearance]];
    [self assertFalse:[view hasThemeState:CPThemeStateAppearanceVibrantLight]];
    [self assertTrue:[view hasThemeState:CPThemeStateAppearanceVibrantDark]];
}

- (void)testEffectiveAppearanceWithMovingViewHierarchy
{
    var viewC = [[CPView alloc] initWithFrame:CGRectMakeZero()],
        viewA = [[CPView alloc] initWithFrame:CGRectMakeZero()],
        viewB = [[CPView alloc] initWithFrame:CGRectMakeZero()];

    [view setAppearance:[CPAppearance appearanceNamed:CPAppearanceNameVibrantLight]];
    [viewC setAppearance:[CPAppearance appearanceNamed:CPAppearanceNameVibrantDark]];

    [viewA addSubview:viewB];
    [view addSubview:viewA];

    [self assert:[CPAppearance appearanceNamed:CPAppearanceNameVibrantLight] equals:[viewB effectiveAppearance]];

    [viewC addSubview:viewA];
    [self assert:[CPAppearance appearanceNamed:CPAppearanceNameVibrantDark] equals:[viewB effectiveAppearance]];
}

- (void)testEffectiveAppearanceReset
{
    var viewA = [[CPView alloc] initWithFrame:CGRectMakeZero()],
        viewB = [[CPView alloc] initWithFrame:CGRectMakeZero()];

    [viewA setAppearance:[CPAppearance appearanceNamed:CPAppearanceNameVibrantLight]];
    [viewB setAppearance:[CPAppearance appearanceNamed:CPAppearanceNameVibrantDark]];

    [viewA addSubview:view];
    [self assert:[CPAppearance appearanceNamed:CPAppearanceNameVibrantLight] equals:[view effectiveAppearance]];

    [view removeFromSuperview];
    [self assert:nil equals:[view effectiveAppearance]];
}

@end

@implementation CPLayoutView : CPView
{

}

- (void)layoutSubviews
{
    [super layoutSubviews];

    var string = @"layoutSubivews_" + [self identifier];
    [methodCalled addObject:string];
}

@end

@implementation CPResponderView : CPView

- (void)viewDidMoveToSuperview
{
    var string = @"viewDidMoveToSuperview_" + [self identifier];
    [methodCalled addObject:string];
}

- (void)viewDidMoveToWindow
{
    var string = @"viewDidMoveToWindow_" + [self identifier];
    [methodCalled addObject:string];
}

- (void)viewWillMoveToSuperview:(CPView)newSuperview
{
    var string = @"viewWillMoveToSuperview_" + [self identifier];
    [methodCalled addObject:string];
}

- (void)viewWillMoveToWindow:(CPWindow)newWindow
{
    var string = @"viewWillMoveToWindow_" + [self identifier];
    [methodCalled addObject:string];
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

@end
