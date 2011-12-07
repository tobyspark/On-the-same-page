//
//  TBZPageSpreadView.h
//  On the same page
//
//  Created by Toby Harris on 22/10/2011.
//  Copyright (c) 2011 Toby Harris. All rights reserved.
//
//  Licensed under the MIT license: http://www.opensource.org/licenses/mit-license.php
//

#import <UIKit/UIKit.h>

@interface TBZPageSpreadViewController : UIViewController
{
    NSMutableDictionary*    viewers;
    NSArray*                pages;
}

- (void)setPageCount:(NSUInteger)count;

- (void)addViewer:(NSString*)viewerID;
- (void)removeViewer:(NSString*)viewerID;
- (void)setPosition:(NSUInteger)position forViewer:(NSString*)viewerID;
- (void)setCurrentPage:(NSUInteger)position;

@end
