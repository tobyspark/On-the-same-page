//
//  TBZPeerToPeer.h
//  On the same page
//
//  Created by TBZ.PhD on 23/11/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

// The Bonjour application protocol, which must:
// 1) be no longer than 14 characters
// 2) contain only lower-case letters, digits, and hyphens
// 3) begin and end with lower-case letter or digit
// It should also be descriptive and human-readable
// Prepend _ if service rather than host
// Append ._tcp. to set TCP as protocol
#define kTBZAppIdentifier @"_tbz-osp._tcp."

#import <Foundation/Foundation.h>

@interface TBZPeerToPeer : NSObject <GCDAsyncSocketDelegate, NSNetServiceBrowserDelegate, NSNetServiceDelegate>
{
    NSNetService*        serverService;
	GCDAsyncSocket*      serverSocket;
    
    NSNetServiceBrowser* netServiceBrowser;
    NSMutableDictionary* netServicesFound;
    
    NSMutableArray*      connectedSockets;
    
    NSData*              EOFData;
    NSUInteger           EOFLength;
}

@property(strong, atomic) id delegate;

- (BOOL)start;
- (BOOL)stop;
- (void)sendData:(NSData*)data;
- (NSString*)name;

@end

@protocol TBZPeerToPeerDelegate

- (void)peerToPeerDataReceived:(NSData*)data;
- (void)peerToPeerConnectionMade:(NSString*)serviceName;
- (void)peerToPeerConnectionLost:(NSString*)serviceName;

@end
