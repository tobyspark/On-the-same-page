//
//  TBZRootViewController.m
//  On the same page
//
//  Created by TBZ.PhD on 19/10/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TBZRootViewController.h"

#import "TBZModelController.h"

#import "TBZDataViewController.h"

#import "TBZPageSpreadView.h"

@interface TBZRootViewController ()
@property (readonly, strong, nonatomic) TBZModelController *modelController;
@property (readonly, strong, nonatomic) TBZPageSpreadViewController *pageSpreadViewController;
@end

@implementation TBZRootViewController

@synthesize pageViewController = _pageViewController;
@synthesize modelController = _modelController;
@synthesize pageSpreadViewController = _pageSpreadViewController;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // TASK: Divide up screen
    
    CGRect pageSpreadRect;
    CGRect pageViewRect;
    CGRectDivide(self.view.bounds, &pageSpreadRect, &pageViewRect, 20, CGRectMaxYEdge);
    
    NSLog(@"x: %f, y: %f, w:%f, h:%f", pageSpreadRect.origin.x, pageSpreadRect.origin.y, pageSpreadRect.size.width, pageSpreadRect.size.height);
    
    // TASK: Setup Page Spread
    
    _pageSpreadViewController = [[TBZPageSpreadViewController alloc] init];
    [self addChildViewController:self.pageSpreadViewController];
    [self.view addSubview:self.pageSpreadViewController.view]; 
    
    [self.pageSpreadViewController.view setFrame:pageSpreadRect];
    [self.pageSpreadViewController setPageCount:[self.modelController pageCount]];

    // Configure the page view controller and add it as a child view controller.
    NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:UIPageViewControllerSpineLocationMin] forKey:UIPageViewControllerOptionSpineLocationKey];
    self.pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStylePageCurl navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:options];
    self.pageViewController.delegate = self;

    TBZDataViewController *startingViewController = [self.modelController viewControllerAtIndex:0 storyboard:self.storyboard];
    NSArray *viewControllers = [NSArray arrayWithObject:startingViewController];
    [self.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:NULL];

    self.pageViewController.dataSource = self.modelController;

    [self addChildViewController:self.pageViewController];
    [self.view addSubview:self.pageViewController.view];
    self.pageViewController.view.frame = pageViewRect;

    [self.pageViewController didMoveToParentViewController:self];    

    // Add the page view controller's gesture recognizers to the book view controller's view so that the gestures are started more easily.
    self.view.gestureRecognizers = self.pageViewController.gestureRecognizers;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration
{
    CGRect pageSpreadRect;
    CGRect pageViewRect;
    CGRectDivide(self.view.bounds, &pageSpreadRect, &pageViewRect, 20, CGRectMaxYEdge);
    
    [self.pageViewController.view setFrame:pageViewRect];
    [self.pageSpreadViewController.view setFrame:pageSpreadRect];
}

- (TBZModelController *)modelController
{
    /*
     Return the model controller object, creating it if necessary.
     In more complex implementations, the model controller may be passed to the view controller.
     */
    if (!_modelController) {
        _modelController = [[TBZModelController alloc] init];
    }
    return _modelController;
}

#pragma mark - UIPageViewController delegate methods


- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed
{
    if (completed)
    {
        [self.pageSpreadViewController setCurrentPage:[self.modelController indexOfViewController:[pageViewController.viewControllers objectAtIndex:0]]];
    }
}


//- (UIPageViewControllerSpineLocation)pageViewController:(UIPageViewController *)pageViewController spineLocationForInterfaceOrientation:(UIInterfaceOrientation)orientation
//{
//    if (UIInterfaceOrientationIsPortrait(orientation)) {
//        // In portrait orientation: Set the spine position to "min" and the page view controller's view controllers array to contain just one view controller. Setting the spine position to 'UIPageViewControllerSpineLocationMid' in landscape orientation sets the doubleSided property to YES, so set it to NO here.
//        UIViewController *currentViewController = [self.pageViewController.viewControllers objectAtIndex:0];
//        NSArray *viewControllers = [NSArray arrayWithObject:currentViewController];
//        [self.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:NULL];
//        
//        self.pageViewController.doubleSided = NO;
//        return UIPageViewControllerSpineLocationMin;
//    }
//
//    // In landscape orientation: Set set the spine location to "mid" and the page view controller's view controllers array to contain two view controllers. If the current page is even, set it to contain the current and next view controllers; if it is odd, set the array to contain the previous and current view controllers.
//    TBZDataViewController *currentViewController = [self.pageViewController.viewControllers objectAtIndex:0];
//    NSArray *viewControllers = nil;
//
//    NSUInteger indexOfCurrentViewController = [self.modelController indexOfViewController:currentViewController];
//    if (indexOfCurrentViewController == 0 || indexOfCurrentViewController % 2 == 0) {
//        UIViewController *nextViewController = [self.modelController pageViewController:self.pageViewController viewControllerAfterViewController:currentViewController];
//        viewControllers = [NSArray arrayWithObjects:currentViewController, nextViewController, nil];
//    } else {
//        UIViewController *previousViewController = [self.modelController pageViewController:self.pageViewController viewControllerBeforeViewController:currentViewController];
//        viewControllers = [NSArray arrayWithObjects:previousViewController, currentViewController, nil];
//    }
//    [self.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:NULL];
//
//
//    return UIPageViewControllerSpineLocationMid;
//}

@end
