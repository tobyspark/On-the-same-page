//
//  TBZAppDelegate.h
//  On the same page
//
//  Created by Toby Harris on 19/10/2011.
//  Copyright (c) 2011 Toby Harris. All rights reserved.
//
//  Licensed under the MIT license: http://www.opensource.org/licenses/mit-license.php
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
