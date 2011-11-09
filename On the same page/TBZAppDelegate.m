//
//  TBZAppDelegate.m
//  On the same page
//
//  Created by TBZ.PhD on 19/10/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TBZAppDelegate.h"
#import "TBZPageSpreadView.h"

#import "DDLog.h"
#import "DDTTYLogger.h"
#import "DDASLLogger.h"

// The Bonjour application protocol, which must:
// 1) be no longer than 14 characters
// 2) contain only lower-case letters, digits, and hyphens
// 3) begin and end with lower-case letter or digit
// It should also be descriptive and human-readable
// Prepend _ if service rather than host
// Append ._tcp. to set TCP as protocol
#define kTBZAppIdentifier @"_tbz-osp._tcp."

// Log levels: off, error, warn, info, verbose
static const int ddLogLevel = LOG_LEVEL_VERBOSE;

@interface TBZAppDelegate (Private)
- (void)connectToNextAddressForServiceName:(NSString*)serviceName;
@end


// TODO: Fade pageSpread circle as proportion of viewers
// TODO: Remove viewer on disconnect (possibly should be putting sockets into netServicesFound dict)



@implementation TBZAppDelegate

@synthesize window;
@synthesize connectedSockets;
@synthesize pageSpread;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Configure logging framework
	
	[DDLog addLogger:[DDTTYLogger sharedInstance]];
	[DDLog addLogger:[DDASLLogger sharedInstance]];
    
    // TASK: SERVER
    
    // Create our socket.
	// We tell it to invoke our delegate methods on the main thread.
	
	serverSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
	
	// Create an array to hold accepted incoming connections.
	
	self.connectedSockets = [[NSMutableArray alloc] init];
	
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

- (void)notifyOfCurrentPage:(NSUInteger)page
{
    NSDictionary *message = [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSNumber numberWithUnsignedInteger:page], @"page",
                            [serverService name], @"name",
                            nil];
    
    NSMutableData *data = [[NSKeyedArchiver archivedDataWithRootObject:message] mutableCopy];
    [data appendData:[GCDAsyncSocket CRLFData]];
    
    for (GCDAsyncSocket* socket in self.connectedSockets)
    {
        [socket writeData:data withTimeout:-1 tag:0];
    }
}

#pragma mark Network Communication

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
	DDLogInfo(@"socket:%p didWriteDataWithTag:%d", sock, tag);
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
	DDLogInfo(@"socket:%p didReadData:withTag:%d", sock, tag);
	
    NSData* messageData = [data subdataWithRange:NSMakeRange(0, [data length] - [[GCDAsyncSocket CRLFData] length])];
    
	NSDictionary *message = [NSKeyedUnarchiver unarchiveObjectWithData:messageData];
	
	DDLogInfo(@"Network Response:\n%@", message);
    
    [self.pageSpread setPosition:[[message objectForKey:@"page"] unsignedIntegerValue] forViewer:[message objectForKey:@"name"]];
    
    [sock readDataToData:[GCDAsyncSocket CRLFData] withTimeout:-1.0 tag:0];
}

#pragma mark -

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
            
            [self.pageSpread addViewer:serviceName];
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

#pragma mark Socket Connection

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
	DDLogInfo(@"Socket:DidConnectToHost: %@ Port: %hu", host, port);
	
    // don't need to add - we build our list from incoming initiated only.
    
    // FIXME: should only need this on incoming sockets we retain?
    [sock readDataToData:[GCDAsyncSocket CRLFData] withTimeout:-1.0 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
	DDLogInfo(@"Accepted new socket from %@:%hu", [newSocket connectedHost], [newSocket connectedPort]);
	
	// The newSocket automatically inherits its delegate & delegateQueue from its parent.
	
    // check for existing connection to that name (not address?) and add if not found, and disconnect if found?
	[self.connectedSockets addObject:newSocket];
    
    [newSocket readDataToData:[GCDAsyncSocket CRLFData] withTimeout:-1.0 tag:0];
}


- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    DDLogInfo(@"Socket:DidDisconnect: %@ withError: %@", sock, err);
    
	[self.connectedSockets removeObject:sock];
    
    // TODO: establish the netservice it came from and try any remaining addresses
}

@end
