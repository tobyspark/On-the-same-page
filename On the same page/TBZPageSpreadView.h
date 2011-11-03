

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
