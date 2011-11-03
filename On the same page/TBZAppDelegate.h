//
//  TBZAppDelegate.h
//  On the same page
//
//  Created by TBZ.PhD on 19/10/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TCPServer.h"

@interface TBZAppDelegate : UIResponder <UIApplicationDelegate, TCPServerDelegate, NSStreamDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic)   TCPServer			*server;
@property (strong, nonatomic)   NSInputStream		*inStream;
@property (strong, nonatomic)   NSOutputStream		*outStream;
@property ()                    BOOL				inReady;
@property ()                    BOOL				outReady;

@end
