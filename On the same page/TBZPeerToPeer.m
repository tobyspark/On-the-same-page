//
//  TBZPeerToPeer.m
//  On the same page
//
//  Created by TBZ.PhD on 23/11/2011.
//  Copyright (c) 2011 Toby Harris. All rights reserved.
//
//  Licensed under the MIT license: http://www.opensource.org/licenses/mit-license.php
//

#import "TBZPeerToPeer.h"

#import "DDLog.h"
#import "DDTTYLogger.h"
#import "DDASLLogger.h"

// Log levels: off, error, warn, info, verbose
static const int ddLogLevel = LOG_LEVEL_VERBOSE;

@implementation TBZPeerToPeer

@synthesize delegate;
@synthesize lastData;

-(id)init
{
    if (self = [super init])
    {
        // Set End-of-file pattern
        EOFData = [GCDAsyncSocket CRLFData];
        EOFLength = [EOFData length];
        
        // Go!
        [self start];
    }
    return self;
}

- (BOOL)start
{
    // APPROACH
    // We need to be both server and client so there's a socket at both ends. 
    // The consequence of this is that both devices will attempt to initiate the connection.
    // We need to then keep the first connection made and reject any subsequent.
    
    // TASK: SERVER
    
    // Create our socket.
	// We tell it to invoke our delegate methods on the main thread.
	
	serverSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
	
	// Create an array to hold accepted incoming connections.
	
	connectedSockets = [[NSMutableDictionary alloc] init];
	
	// Now we tell the socket to accept incoming connections.
	// We don't care what port it listens on, so we pass zero for the port number.
	// This allows the operating system to automatically assign us an available port.
	
	NSError *err = nil;
	if ([serverSocket acceptOnPort:0 error:&err])
	{
		// So what port did the OS give us?
		
		UInt16 port = [serverSocket localPort];
		
		// Create and publish the bonjour service.
		// Obviously you will be using your own custom service type.
		
		serverService = [[NSNetService alloc] initWithDomain:@"local."
                                                        type:kTBZAppIdentifier
                                                        name:@""
                                                        port:port];
		
		[serverService setDelegate:self];
		[serverService publish];
	}
	else
	{
		DDLogError(@"Error in acceptOnPort:error: -> %@", err);
	}
    
    // TASK: CLIENT
    
    // Start browsing for bonjour services
	
	netServiceBrowser = [[NSNetServiceBrowser alloc] init];
	
	[netServiceBrowser setDelegate:self];
	[netServiceBrowser searchForServicesOfType:kTBZAppIdentifier inDomain:@"local."];
    
    netServicesResolving = [[NSMutableSet alloc] init];
    
    return YES;
}

- (BOOL)stop
{
    // TODO: Make Start and Stop actually work, instead of a hardcoded start
    
    // Is there a stop accepting?
    [serverSocket disconnectAfterReadingAndWriting];

    [serverService stop];
    
    return YES;
}

- (void)sendData:(NSData*)messageData to:(NSArray*)arrayOfServiceNames
{
    // Append our end-of-message bytes
    NSMutableData* data = [messageData mutableCopy];
    [data appendData:EOFData];
    
    // Cache this for any later repeats
    [self setLastData:data];
    
    for (NSString* serviceName in arrayOfServiceNames)
    {
        GCDAsyncSocket* socket = [connectedSockets objectForKey:serviceName];
        [socket writeData:data withTimeout:-1 tag:0];
    }
    
}

- (void)sendData:(NSData*)messageData
{
    [self sendData:messageData to:[connectedSockets allKeys]];
}

- (NSString*)name
{
    return [serverService name];
}

#pragma mark -

#pragma mark GCDAsyncSocketDelegate

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
	DDLogInfo(@"socket:%p didWriteDataWithTag:%d", sock, tag);
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
	DDLogInfo(@"socket:%p didReadData:withTag:%d", sock, tag);
	
    NSData* messageData = [data subdataWithRange:NSMakeRange(0, [data length] - EOFLength)];
    
    if ([delegate respondsToSelector:@selector(peerToPeerDataReceived:)])
    {
        [delegate peerToPeerDataReceived:messageData];
    }
    
    [sock readDataToData:EOFData withTimeout:-1.0 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
    // These are sockets we established here
    
	DDLogInfo(@"Socket:DidConnectToHost: %@ Port: %hu", host, port);
    
    #if !TARGET_IPHONE_SIMULATOR
    {
        // Backgrounding doesn't seem to be supported on the simulator yet
        
        [sock performBlock:^{
            if ([sock enableBackgroundingOnSocket])
                DDLogInfo(@"Enabled backgrounding on socket");
            else
                DDLogWarn(@"Enabling backgrounding failed!");
        }];
    }
    #endif
    
    [sock readDataToData:EOFData withTimeout:-1.0 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
    // These are incoming sockets from elsewhere
    
	DDLogInfo(@"Accepted new socket from %@:%hu", [newSocket connectedHost], [newSocket connectedPort]);
	
    #if !TARGET_IPHONE_SIMULATOR
    {
        // Backgrounding doesn't seem to be supported on the simulator yet
        
        [newSocket performBlock:^{
            if ([sock enableBackgroundingOnSocket])
                DDLogInfo(@"Enabled backgrounding on socket");
            else
                DDLogWarn(@"Enabling backgrounding failed!");
        }];
    }
    #endif
    
    [newSocket readDataToData:EOFData withTimeout:-1.0 tag:0];
}


- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    DDLogInfo(@"Socket:DidDisconnect: %@ withError: %@", sock, err);
    
    [connectedSockets enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([obj isEqual:sock])
        {
            [connectedSockets removeObjectForKey:key];
            
            DDLogInfo(@"Sending peerToPeerConnectionLost: %@", key);
            if ([delegate respondsToSelector:@selector(peerToPeerConnectionLost:)])
            {
                [delegate peerToPeerConnectionLost:key];
            }
            
            *stop = YES;
        }
    }];
}

#pragma mark NetService Client

- (void)netServiceBrowser:(NSNetServiceBrowser *)sender didNotSearch:(NSDictionary *)errorInfo
{
	DDLogError(@"DidNotSearch: %@", errorInfo);
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)sender
           didFindService:(NSNetService *)netService
               moreComing:(BOOL)moreServicesComing
{
	DDLogVerbose(@"DidFindService: %@", [netService name]);
	
    // Ignore ourselves
    if ([[netService name] isEqual:[serverService name]])
    {
        DDLogVerbose(@"Ignoring own service");
    }
    // Ignore a service we're already connected to
    else if ([[connectedSockets allKeys] containsObject:[netService name]])
    {
        DDLogVerbose(@"Ignoring %@ as already connected", [netService name]);
    }
    // Continue the process...
    else
    {
        [netService setDelegate:self];
        [netService resolveWithTimeout:5.0];
        
        // ARC dictates we need to keep a reference to this while it resolves
        [netServicesResolving addObject:netService];
    }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)sender
         didRemoveService:(NSNetService *)netService
               moreComing:(BOOL)moreServicesComing
{
	DDLogVerbose(@"DidRemoveService: %@", [netService name]);
}

- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)sender
{
	DDLogInfo(@"DidStopSearch");
}

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict
{
	DDLogError(@"DidNotResolve");
}

- (void)netServiceDidResolveAddress:(NSNetService *)netService
{
	DDLogInfo(@"DidResolve: %@", [netService addresses]);
    
    // Ignore a service we're already connected to
    if ([[connectedSockets allKeys] containsObject:[netService name]])
    {
        DDLogVerbose(@"Ignoring %@ as already connected", [netService name]);
    }
    else
    {
        BOOL done = NO;
        
        GCDAsyncSocket* socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        
        NSMutableArray* serverAddresses = [[netService addresses] mutableCopy];
        
        while (!done && ([serverAddresses count] > 0))
        {
            NSData *addr;
            
            // Note: The serverAddresses array probably contains both IPv4 and IPv6 addresses.
            // 
            // If your server is also using GCDAsyncSocket then you don't have to worry about it,
            // as the socket automatically handles both protocols for you transparently.
            
            addr = [serverAddresses objectAtIndex:0];
            [serverAddresses removeObjectAtIndex:0];
            
            DDLogVerbose(@"Attempting connection to %@", addr);
            
            NSError *err = nil;
            if ([socket connectToAddress:addr error:&err])
            {
                done = YES;
                
                // TASK: Success! Add connected socket to our list and notify our delegate
                
                [connectedSockets setObject:socket forKey:[netService name]];
                
                if ([delegate respondsToSelector:@selector(peerToPeerConnectionMade:)])
                {
                    [delegate peerToPeerConnectionMade:[netService name]];
                }
            }
            else
            {
                DDLogWarn(@"Unable to connect: %@", err);
            }
        }
        
        if (!done)
        {
            DDLogWarn(@"Unable to connect to any resolved address");
            socket = nil;
        }
    }
    
    [netServicesResolving removeObject:netService];
}

#pragma mark NetService Server

- (void)netServiceDidPublish:(NSNetService *)ns
{
	DDLogInfo(@"Bonjour Service Published: domain(%@) type(%@) name(%@) port(%i)",
			  [ns domain], [ns type], [ns name], (int)[ns port]);
}

- (void)netService:(NSNetService *)ns didNotPublish:(NSDictionary *)errorDict
{
	// Override me to do something here...
	// 
	// Note: This method in invoked on our bonjour thread.
	
	DDLogError(@"Failed to Publish Service: domain(%@) type(%@) name(%@) - %@",
               [ns domain], [ns type], [ns name], errorDict);
}

@end
