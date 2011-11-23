//
//  TBZAppDelegate.m
//  On the same page
//
//  Created by TBZ.PhD on 19/10/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TBZAppDelegate.h"
#import "TBZPageSpreadView.h"
#import "TBZModelController.h"

#import "DDLog.h"
#import "DDTTYLogger.h"
#import "DDASLLogger.h"

// Log levels: off, error, warn, info, verbose
static const int ddLogLevel = LOG_LEVEL_VERBOSE;

// TODO: Load images on demand, not as a whole at load
// TODO: Remove viewer on disconnect (possibly should be putting sockets into netServicesFound dict)

@implementation TBZAppDelegate

@synthesize window;
@synthesize modelController;
@synthesize modelControllerNotes;
@synthesize extWindow;
@synthesize pageSpread;
@synthesize p2p;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Configure logging framework
	
	[DDLog addLogger:[DDTTYLogger sharedInstance]];
	[DDLog addLogger:[DDASLLogger sharedInstance]];
    
    // TASK: Setup networking
    [self setP2p:[[TBZPeerToPeer alloc] init]];
    [self.p2p setDelegate:self];
    
    // TASK: Setup slide data
    [self setModelController:[[TBZModelController alloc] initWithDirectory:@"slideImages"]];
    [(TBZRootViewController*)self.window.rootViewController setModelController:[self modelController]];
    
    // TASK: Set to not sleep, pretty essential for a presentation app!
    [application setIdleTimerDisabled:YES];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
    
    NSArray* screens = [UIScreen screens];

    if ([screens count] > 1)
    {
        UIScreen* extScreen = [screens objectAtIndex:1];
        // TODO: Select best screen mode
        
        if (extWindow == nil || !CGRectEqualToRect(extWindow.bounds, [extScreen bounds])) 
        {
            TBZRootViewController *rootViewController = (TBZRootViewController*)[self.window rootViewController];
            TBZRootViewController *extRootViewController = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateInitialViewController];
            
            // Set data sources: move slides as-is to external, invoke slides-with-notes on internal.
            [extRootViewController setModelController:[self modelController]];
            [self setModelControllerNotes:[[TBZModelController alloc] initWithDirectory:@"slideImagesNotes"]];
            [rootViewController setModelController:[self modelControllerNotes]];
            
            TBZDataViewController *startingViewController = [self.modelControllerNotes viewControllerAtIndex:0 storyboard:[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil]];
            NSArray *viewControllers = [NSArray arrayWithObject:startingViewController];
            [rootViewController.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:NULL];
            
            rootViewController.pageViewController.dataSource = self.modelControllerNotes;
            
            
            //[rootViewController.pageViewController setDataSource:[self modelControllerNotes]];
            
            extWindow = [[UIWindow alloc] initWithFrame:[extScreen bounds]];
            [extWindow setScreen:extScreen];
            [extWindow setRootViewController:extRootViewController];
            [extWindow makeKeyAndVisible];
        }
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

#pragma mark -

- (void)notifyOfCurrentPage:(NSUInteger)page previousPage:(NSUInteger)oldPage
{
    // Duplicate View Notify
    if ([self extWindow])
    {
        NSArray *viewControllers = [NSArray arrayWithObject:[self.modelController viewControllerAtIndex:page storyboard:[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil]]];
        UIPageViewControllerNavigationDirection direction = (page>oldPage) ? UIPageViewControllerNavigationDirectionForward : UIPageViewControllerNavigationDirectionReverse;
        
        TBZRootViewController* extRootViewController = (TBZRootViewController*)[self.extWindow rootViewController];
        [extRootViewController.pageSpreadViewController setCurrentPage:page];
        [extRootViewController.pageViewController setViewControllers:viewControllers
                                                           direction:direction
                                                            animated:YES 
                                                          completion:nil];
    }
    
    // Network Notify
    NSDictionary *message = [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSNumber numberWithUnsignedInteger:page], @"page",
                            [p2p name], @"name",
                            nil];
    
    NSMutableData *data = [[NSKeyedArchiver archivedDataWithRootObject:message] mutableCopy];

    [p2p sendData:data];
}

#pragma mark - TBZPeerToPeerDelegate

- (void)peerToPeerDataReceived:(NSData*)data
{
    NSDictionary *message = [NSKeyedUnarchiver unarchiveObjectWithData:data];
	
	DDLogInfo(@"Network Response:\n%@", message);
    
    [self.pageSpread setPosition:[[message objectForKey:@"page"] unsignedIntegerValue] forViewer:[message objectForKey:@"name"]];
    
}

- (void)peerToPeerConnectionMade:(NSString*)serviceName
{
    [self.pageSpread addViewer:serviceName];
}

- (void)peerToPeerConnectionLost:(NSString*)serviceName
{
    [self.pageSpread removeViewer:serviceName];
}

@end
