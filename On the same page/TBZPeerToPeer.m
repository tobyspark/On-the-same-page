//
//  TBZPeerToPeer.m
//  On the same page
//
//  Created by TBZ.PhD on 23/11/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TBZPeerToPeer.h"

#import "DDLog.h"
#import "DDTTYLogger.h"
#import "DDASLLogger.h"

// Log levels: off, error, warn, info, verbose
static const int ddLogLevel = LOG_LEVEL_VERBOSE;

@interface TBZPeerToPeer (Private)
- (void)connectToNextAddressForServiceName:(NSString*)serviceName;
@end

@implementation TBZPeerToPeer

@synthesize delegate;

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
    // TASK: SERVER
    
    // Create our socket.
	// We tell it to invoke our delegate methods on the main thread.
	
	serverSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
	
	// Create an array to hold accepted incoming connections.
	
	connectedSockets = [[NSMutableArray alloc] init];
	
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
		
        //		// You can optionally add TXT record stuff
        //		
        //		NSMutableDictionary *txtDict = [NSMutableDictionary dictionaryWithCapacity:2];
        //		
        //		[txtDict setObject:@"moo" forKey:@"cow"];
        //		[txtDict setObject:@"quack" forKey:@"duck"];
        //		
        //		NSData *txtData = [NSNetService dataFromTXTRecordDictionary:txtDict];
        //		[serverService setTXTRecordData:txtData];
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
    
    netServicesFound = [NSMutableDictionary dictionary];
    
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

- (void)sendData:(NSData*)messageData
{
    // Append our end-of-message bytes
    NSMutableData* data = [messageData mutableCopy];
    [data appendData:EOFData];
    
    // Send to all sockets we have
    for (GCDAsyncSocket* socket in connectedSockets)
    {
        [socket writeData:data withTimeout:-1 tag:0];
    }
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
	DDLogInfo(@"Socket:DidConnectToHost: %@ Port: %hu", host, port);
	
    // don't need to add - we build our list from incoming initiated only.
    
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
    
    // FIXME: should only need this on incoming sockets we retain?
    [sock readDataToData:EOFData withTimeout:-1.0 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
	DDLogInfo(@"Accepted new socket from %@:%hu", [newSocket connectedHost], [newSocket connectedPort]);
	
	// The newSocket automatically inherits its delegate & delegateQueue from its parent.
	
    // check for existing connection to that name (not address?) and add if not found, and disconnect if found?
	[connectedSockets addObject:newSocket];
    
    [newSocket readDataToData:EOFData withTimeout:-1.0 tag:0];
}


- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    DDLogInfo(@"Socket:DidDisconnect: %@ withError: %@", sock, err);
    
	[connectedSockets removeObject:sock];
    
    // TODO: establish the netservice it came from and try any remaining addresses
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
	
    if ([[netService name] isEqual:[serverService name]])
    {
        DDLogVerbose(@"Ignoring own service");
    }
    else
    {
        [netService setDelegate:self];
        [netService resolveWithTimeout:5.0];
        
        NSMutableDictionary* serviceInfo = [NSMutableDictionary dictionaryWithCapacity:4];
        [serviceInfo setObject:netService forKey:@"service"];
        [serviceInfo setObject:[NSNumber numberWithBool:NO] forKey:@"connected"];
        [serviceInfo setObject:[NSNumber numberWithBool:NO] forKey:@"resolved"];
        
        [netServicesFound setObject:serviceInfo forKey:[netService name]];
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
	
    NSMutableDictionary* serviceInfo = [netServicesFound objectForKey:[netService name]];
    
    [serviceInfo setObject:[NSNumber numberWithBool:YES] forKey:@"resolved"];
    [serviceInfo setObject:[[netService addresses] mutableCopy] forKey:@"untriedAddresses"];
    
    [self connectToNextAddressForServiceName:[netService name]];
}

- (void)connectToNextAddressForServiceName:(NSString*)serviceName
{
	BOOL done = NO;
    
    GCDAsyncSocket* asyncSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    NSMutableArray* serverAddresses = [[netServicesFound objectForKey:serviceName] objectForKey:@"untriedAddresses"];
    
	while (!done && ([serverAddresses count] > 0))
	{
		NSData *addr;
		
		// Note: The serverAddresses array probably contains both IPv4 and IPv6 addresses.
		// 
		// If your server is also using GCDAsyncSocket then you don't have to worry about it,
		// as the socket automatically handles both protocols for you transparently.
		
		if (YES) // Iterate forwards
		{
			addr = [serverAddresses objectAtIndex:0];
			[serverAddresses removeObjectAtIndex:0];
		}
		else // Iterate backwards
		{
			addr = [serverAddresses lastObject];
			[serverAddresses removeLastObject];
		}
		
		DDLogVerbose(@"Attempting connection to %@", addr);
		
		NSError *err = nil;
		if ([asyncSocket connectToAddress:addr error:&err])
		{
			done = YES;
            
            if ([delegate respondsToSelector:@selector(peerToPeerConnectionMade:)])
            {
                [delegate peerToPeerConnectionMade:serviceName];
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
        asyncSocket = nil;
	}
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
