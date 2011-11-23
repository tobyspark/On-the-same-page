//
//  TBZAppDelegate.h
//  On the same page
//
//  Created by TBZ.PhD on 19/10/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GCDAsyncSocket.h"
#import "TBZRootViewController.h"
#import "TBZPeerToPeer.h"

@interface TBZAppDelegate : UIResponder <UIApplicationDelegate, TBZPeerToPeerDelegate>

@property (strong, nonatomic) TBZModelController *modelController;
@property (strong, nonatomic) TBZModelController *modelControllerNotes;
@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UIWindow *extWindow;


@property (strong, atomic) TBZPeerToPeer *p2p;

@property (weak, nonatomic) TBZPageSpreadViewController *pageSpread;

- (void)notifyOfCurrentPage:(NSUInteger)page previousPage:(NSUInteger)oldPage;

@end
