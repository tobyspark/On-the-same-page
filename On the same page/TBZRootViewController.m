//
//  TBZRootViewController.m
//  On the same page
//
//  Created by Toby Harris on 19/10/2011.
//  Copyright (c) 2011 Toby Harris. All rights reserved.
//
//  Licensed under the MIT license: http://www.opensource.org/licenses/mit-license.php
//

#import "TBZRootViewController.h"

#import "TBZModelController.h"
#import "TBZDataViewController.h"
#import "TBZPageSpreadView.h"

#import "TBZAppDelegate.h"

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
    
    // TASK: Little tweaks
    [self.pageSpreadViewController setCurrentPage:0];
    
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

#pragma mark - UIPageViewController delegate methods

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed
{
    if (completed)
    {
        NSUInteger page = [self.modelController indexOfViewController:[pageViewController.viewControllers objectAtIndex:0]];
        NSUInteger oldPage = [self.modelController indexOfViewController:[previousViewControllers objectAtIndex:0]];
        
        [self.pageSpreadViewController setCurrentPage:page];
        
        TBZAppDelegate* appDelegate = (TBZAppDelegate*)[[UIApplication sharedApplication] delegate];
        
        [appDelegate notifyOfCurrentPage:page previousPage:oldPage];
    }
}

@end
