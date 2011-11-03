//
//  TBZModelController.h
//  On the same page
//
//  Created by TBZ.PhD on 19/10/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TBZDataViewController;

@interface TBZModelController : NSObject <UIPageViewControllerDataSource>
- (TBZDataViewController *)viewControllerAtIndex:(NSUInteger)index storyboard:(UIStoryboard *)storyboard;
- (NSUInteger)indexOfViewController:(TBZDataViewController *)viewController;
- (NSUInteger)pageCount;
@end
