//
//  TBZRootViewController.h
//  On the same page
//
//  Created by Toby Harris on 19/10/2011.
//  Copyright (c) 2011 Toby Harris. All rights reserved.
//
//  Licensed under the MIT license: http://www.opensource.org/licenses/mit-license.php
//

#import <UIKit/UIKit.h>
@class TBZPageSpreadViewController;
@class TBZModelController;

@interface TBZRootViewController : UIViewController <UIPageViewControllerDelegate>

@property (weak, nonatomic) TBZModelController *modelController;
@property (strong, nonatomic) UIPageViewController *pageViewController;
@property (readonly, strong, nonatomic) TBZPageSpreadViewController *pageSpreadViewController;

@end
