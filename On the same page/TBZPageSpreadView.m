//
//  TBZPageSpreadView.h
//  On the same page
//
//  Created by Toby Harris on 22/10/2011.
//  Copyright (c) 2011 Toby Harris. All rights reserved.
//
//  Licensed under the MIT license: http://www.opensource.org/licenses/mit-license.php
//

#import "TBZPageSpreadView.h"

@interface TBZPageSpreadViewController (Private) 
- (void)layoutSubviews;
- (void) setViewerAlpha;
@end

@implementation TBZPageSpreadViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    viewers = [NSMutableDictionary dictionary];
    
    TBZAppDelegate *appDelegate = (TBZAppDelegate*)[[UIApplication sharedApplication] delegate];
    
    if ([appDelegate respondsToSelector:@selector(setPageSpread:)])
    {
        [appDelegate setPageSpread:self];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration
{
    [self layoutSubviews];
}

- (void)setPageCount:(NSUInteger)count;
{
    UIImage* pageImage = [UIImage imageNamed:@"pageIcon-Normal"];
    UIImage* pageHighlightImage = [UIImage imageNamed:@"pageIcon-Highlighted"];
    
    NSMutableArray* tempPageArray = [NSMutableArray arrayWithCapacity:count];
    for (NSUInteger p=0; p < count; p++) 
    {
        // Create view and display
        UIImageView* pageImageView = [[UIImageView alloc] initWithImage:pageImage highlightedImage:pageHighlightImage];
        
        [self.view addSubview:pageImageView];
        
        // Add to the array so we can reference it later by page index
        [tempPageArray addObject:pageImageView];
        
        pageImageView = nil;
    }
    pages = [NSArray arrayWithArray:tempPageArray];
    
    // Position the page images
    [self layoutSubviews];
}

- (void)addViewer:(NSString*)viewerID
{
    UIImage* viewerImage = [UIImage imageNamed:@"pageIcon-Viewer"];
    UIImageView* viewerImageView = [[UIImageView alloc] initWithImage:viewerImage];
    [self.view addSubview:viewerImageView];
    
    [viewers setObject:viewerImageView forKey:viewerID];
    
    [self setViewerAlpha];
    
    [self setPosition:0 forViewer:viewerID];
}

- (void)removeViewer:(NSString*)viewerID
{
    [[viewers objectForKey:@"viewerID"] removeFromSuperview];
    [viewers removeObjectForKey:@"viewerID"];
    
    [self setViewerAlpha];
}

- (void)setCurrentPage:(NSUInteger)position
{
    NSUInteger count = [pages count];
    for (NSUInteger i=0; i < count; i++)
    {
        [[pages objectAtIndex:i] setHighlighted:(i==position) ? YES:NO];
    }
}

- (void)setPosition:(NSUInteger)position forViewer:(NSString*)viewerID
{
    NSLog(@"setPosition: %d forViewer: %@", position, viewerID);
    
    if (position < [pages count])
    {
        UIView* view = [viewers objectForKey:viewerID];
        
        // Set tag so we can keep trace, ie. on orientation change
        [view setTag:position];
        
        // Animate to new position
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:1];
        
        [view setCenter:[[pages objectAtIndex:position] center]];
        
        [UIView commitAnimations];
    }
    else
    {
        NSLog(@"Attempted to update to page beyond loaded pages");
    }
}

- (void)layoutSubviews // This is not the UIView method, but yes, guess where it was first.
{
    NSUInteger count = [pages count];
    CGFloat separationWidth = self.view.bounds.size.width / (count + 1);
    
    for (NSUInteger p=0; p < count; p++) 
    {
        CGFloat centerX = floorf((p + 1) * separationWidth);
        CGFloat centerY = floorf(self.view.bounds.size.height / 2);
        
        [[pages objectAtIndex:p] setCenter:CGPointMake(centerX, centerY)];
    }
    
    [viewers enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) 
    {
        [obj setCenter:[[pages objectAtIndex:[obj tag]] center]];
    }];
}

- (void) setViewerAlpha
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:1];
    
    CGFloat proportion = 1.0 / (CGFloat)MAX([viewers count], 1);

    [viewers enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) 
    {
        [obj setAlpha:proportion];
    }];
    
    [UIView commitAnimations];
}

@end
