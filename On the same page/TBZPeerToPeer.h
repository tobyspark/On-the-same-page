//
//  TBZPeerToPeer.h
//  On the same page
//
//  Created by TBZ.PhD on 23/11/2011.
//  Copyright (c) 2011 Toby Harris. All rights reserved.
//
//  Licensed under the MIT license: http://www.opensource.org/licenses/mit-license.php
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
    NSMutableSet*        netServicesResolving;
    
    NSMutableDictionary* connectedSockets;
    
    NSData*              EOFData;
    NSUInteger           EOFLength;
}

@property(strong, atomic) id delegate;
@property(strong, atomic) NSData* lastData;

- (BOOL)start;
- (BOOL)stop;
- (void)sendData:(NSData*)data;
- (void)sendData:(NSData*)data to:(NSArray*)arrayOfServiceNames;
- (NSString*)name;

@end

@protocol TBZPeerToPeerDelegate

- (void)peerToPeerDataReceived:(NSData*)data;
- (void)peerToPeerConnectionMade:(NSString*)serviceName;
- (void)peerToPeerConnectionLost:(NSString*)serviceName;

@end
