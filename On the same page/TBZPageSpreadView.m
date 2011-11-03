

#import "TBZPageSpreadView.h"

@implementation TBZPageSpreadViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    viewers = [NSMutableDictionary dictionary];
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
    
    [self setPosition:0 forViewer:viewerID];
}

- (void)removeViewer:(NSString*)viewerID
{
    [[viewers objectForKey:@"viewerID"] removeFromSuperview];
    [viewers removeObjectForKey:@"viewerID"];
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
    if (position < [pages count])
    {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:1];
        
        [[viewers objectForKey:viewerID] setCenter:[[pages objectAtIndex:position] center]];
        
        [UIView commitAnimations];
    }
    else
    {
        NSLog(@"Attempted to update to page beyond loaded pages");
    }
}

@end
