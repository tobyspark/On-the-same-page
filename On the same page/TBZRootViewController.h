//
//  TBZRootViewController.h
//  On the same page
//
//  Created by TBZ.PhD on 19/10/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
@class TBZPageSpreadViewController;
@class TBZModelController;

@interface TBZRootViewController : UIViewController <UIPageViewControllerDelegate>

@property (weak, nonatomic) TBZModelController *modelController;
@property (strong, nonatomic) UIPageViewController *pageViewController;
@property (readonly, strong, nonatomic) TBZPageSpreadViewController *pageSpreadViewController;

@end
