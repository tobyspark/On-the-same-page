//
//  TBZModelController.h
//  On the same page
//
//  Created by Toby Harris on 19/10/2011.
//  Copyright (c) 2011 Toby Harris. All rights reserved.
//
//  Licensed under the MIT license: http://www.opensource.org/licenses/mit-license.php
//

#import <Foundation/Foundation.h>

@class TBZDataViewController;

@interface TBZModelController : NSObject <UIPageViewControllerDataSource>
- (TBZDataViewController *)viewControllerAtIndex:(NSUInteger)index storyboard:(UIStoryboard *)storyboard;
- (NSUInteger)indexOfViewController:(TBZDataViewController *)viewController;
- (NSUInteger)pageCount;

- (id)initWithDirectory:(NSString*)bundleDir;
@end
