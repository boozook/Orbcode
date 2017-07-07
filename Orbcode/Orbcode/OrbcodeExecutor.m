//
//  OrbcodeExecutor.m
//  Orbcode
//
//  Created by Alexander Kozlovskij on 16.03.17.
//  Copyright © 2017 FZZR. All rights reserved.
//

#import "OrbcodeExecutor.h"
#import "StorageManager.h"

@interface OrbcodeExecutor()
{
}

#if TARGET_OS_IPHONE && !TARGET_IPHONE_SIMULATOR

@property (strong, nonatomic, nullable) RKOrbBasicProgram *currentProgram;
@property (strong, nonatomic, nullable) RKConvenienceRobot *robot;
@property (strong, nonatomic, nullable) id<RKRobotBase> robot_base;

@property (strong, nonatomic, nullable) RUICalibrateGestureHandler *calibrateHandler;

#else

@property (strong, nonatomic, nullable) NSObject *robot;
@property (strong, nonatomic, nullable) NSObject *currentProgram;

#endif

@end


@implementation OrbcodeExecutor

+ (OrbcodeExecutor *)sharedExecutor
{
	static OrbcodeExecutor *sharedExecutor;
	
	@synchronized(self)
	{
		if(!sharedExecutor)
			sharedExecutor = [[OrbcodeExecutor alloc] init];
		
		return sharedExecutor;
	}
}

- (instancetype)init
{
	if(self = [super init])
	{
		#if TARGET_OS_IPHONE && !TARGET_IPHONE_SIMULATOR
		[self initRobot];
		#endif
	}
	return self;
}



@synthesize view;
@synthesize robot;
@synthesize currentProgram;


//#if TARGET_OS_IPHONE && !TARGET_IPHONE_SIMULATOR
#if !TARGET_IPHONE_SIMULATOR

- (RKConvenienceRobot *)sharedRobot
{
	NSLog(@"get sharedRobot: %@", robot);
	return robot;
}


- (RKOrbBasicProgram *)compile:(nonnull NSString *) file directory:(nonnull NSString *) dir error:(NSError *_Nullable *_Nullable) error
{
	RKOrbBasicProgram *prog = [[RKOrbBasicProgram alloc] initWithFilePath:file directoryPath:dir error:error];
	NSLog(@"Program \"%@\" %@ %@ %@", [prog name], prog, [prog robot], robot);
	return prog;
}

- (void)setProgram:(nonnull RKOrbBasicProgram *) program
{
	NSLog(@"setProgram \"%@\" %@", [program name], program);
	[[self currentProgram] abort];
	[[self currentProgram] erase];
	[self setCurrentProgram:program];
	[[self view] refreshView];
}


- (BOOL)uploadProgram
{
	NSLog(@"uploadProgram \"%@\" %@", [currentProgram name], currentProgram);
	if([self hasRobot] && [self hasProgram])
	{
		[[self currentProgram] setRobot:[robot robot]];
		[[self currentProgram] load];
		[[self currentProgram] setRobot:[robot robot]];
		NSLog(@"UPLOADED");
		[[self view] refreshView];
		return YES;
	}
	[[self view] refreshView];
	
	return NO;
}

- (BOOL)executeProgram
{
	NSLog(@"executeProgram \"%@\" %@", [currentProgram name], currentProgram);
	if([self hasRobot] && [self hasProgram])
	{
		[[self currentProgram] execute];
		NSLog(@"EXECUTED");
		return YES;
	}
	
	return NO;
}


- (BOOL)hasRobot
{
	return [robot isOnline];
}

- (BOOL)hasProgram
{
	return currentProgram != nil;
}



#pragma mark - Sphero Reactions / Robot Ctrl


-(void)initRobot
{
	shouldOverrideRobotWhenEvent = YES;
	[[RKRobotDiscoveryAgent sharedAgent] addNotificationObserver:self selector:@selector(handleRobotStateChangeNotification:)];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(appWillResignActive:)
												 name:UIApplicationWillResignActiveNotification
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(appDidBecomeActive:)
												 name:UIApplicationDidBecomeActiveNotification
											   object:nil];
	[self refreshRobot];
}

- (void)setViewForCalibrateHandler:(UIView *)cview
{
	self.calibrateHandler = [[RUICalibrateGestureHandler alloc] initWithView:cview];
	[self.calibrateHandler setRobot:[robot robot]];
}


- (void)appDidBecomeActive:(NSNotification *)notification
{
	shouldOverrideRobotWhenEvent = YES;
	[RKRobotDiscoveryAgent startDiscovery];
}

- (void)appWillResignActive:(NSNotification*)notification
{
	//	[RKRobotDiscoveryAgent disconnectAll];
	[RKRobotDiscoveryAgent stopDiscovery];
}


BOOL shouldOverrideRobotWhenEvent = YES;

-(void)refreshRobot
{
	NSLog(@"refreshing Robot");
	shouldOverrideRobotWhenEvent = YES;
	
	NSLog(@"connectedRobots: %@", [[RKRobotDiscoveryAgent sharedAgent] connectedRobots]);
	NSLog(@"connectedRobots: %lu", (unsigned long)[[[RKRobotDiscoveryAgent sharedAgent] connectedRobots] count]);
	
	NSLog(@"existing Robot: %@, %d", robot, [robot isOnline]);
//	NSOrderedSet<RKRobotBase> *connectedRobots = [[RKRobotDiscoveryAgent sharedAgent] connectedRobots];
	NSOrderedSet *connectedRobots = [[RKRobotDiscoveryAgent sharedAgent] connectedRobots];
	
	
	id<RKRobotBase> robo = nil;
	if([connectedRobots count] == 0)
		[RKRobotDiscoveryAgent startDiscovery];
	else
	{
		robo = [connectedRobots firstObject];
		NSLog(@"ROBO::: %@ !!! %@", [robo class], robo);
		[robo sendCommand:[[RKGetUserRGBLEDColorCommand alloc] init]];
//		robot = [RKConvenienceRobot convenienceWithRobot:robo];
//		[self handleConnected];
	}
	
	NSLog(@".robot == robo  ::  %d", (robo == [self.robot robot]));
	
	if(self.robot != nil)
	{
		NSLog(@"GOT robot from connectedRobots: %@", robot);
//		NSLog(@"GOT robot currentHeading: %f", [robot currentHeading]);
		[robot sendCommand:[[RKGetUserRGBLEDColorCommand alloc] init]];
	}
	
	
//	[view refreshView];
}

- (void)handleRobotStateChangeNotification:(RKRobotChangedStateNotification*)notification
{
	NSLog(@"RK Notification: %@", notification);
	switch(notification.type)
	{
		case RKRobotConnecting:
			NSLog(@"RKRobotConnecting %@", notification);
			break;
		case RKRobotConnected:
		{
			NSLog(@"RKRobotConnected %@", notification);
			RKConvenienceRobot *convenience = [RKConvenienceRobot convenienceWithRobot:notification.robot];
			self.robot_base = notification.robot;
			self.robot = convenience;;
			break;
		}
		case RKRobotOnline:
		{
			NSLog(@"RKRobotOnline %@", notification);
			NSLog(@"ROBOT::: %@ !!! %@", [notification.robot class], notification.robot);
			RKConvenienceRobot *convenience = [RKConvenienceRobot convenienceWithRobot:notification.robot];
			self.robot_base = notification.robot;
			self.robot = convenience;
			shouldOverrideRobotWhenEvent = NO;
			[self handleConnected];
			break;
		}
		case RKRobotDisconnected:
		{
			NSLog(@"RKRobotDisconnected %@", notification);
			[self handleDisconnected];
//			self.robot = nil;
			break;
		}
		case RKRobotOffline:
		{
			NSLog(@"RKRobotOffline %@", notification);
			[self handleDisconnected];
			break;
		}
		case RKRobotFailedConnect:
		{
			NSLog(@"RKRobotFailedConnect %@", notification);
			[self handleDisconnected];
			break;
		}
		default:
		{
			NSLog(@"RKRobot??? %@", notification);
//			[self.navigationItem setPrompt:@"offline"];
			break;
		}
	}

	[[self view] refreshView];
}

#pragma mark Message Handlers

- (void) handleResponse:(RKDeviceResponse *)response forRobot:(id<RKRobotBase>)crobot
{
	NSLog(@"handleResponse: %@, class: %@", response, [RKOrbBasicAppendFragmentResponse class]);
	NSLog(@"shouldOverrideRobotWhenEvent = %hhd", shouldOverrideRobotWhenEvent);
	
	if(shouldOverrideRobotWhenEvent)
	{
		NSLog(@"override because shouldOverrideRobotWhenEvent");
		RKConvenienceRobot *convenience = [RKConvenienceRobot convenienceWithRobot:crobot];
		self.robot_base = crobot;
		self.robot = convenience;
		[self handleConnected];
	}
	
	switch(response.code)
	{
		case RKResponseCodeOK: break;
		case RKResponseCodeErrorGeneral: break;
		case RKResponseCodeErrorChecksum: break;
		case RKResponseCodeErrorFragment: break;
		case RKResponseCodeErrorBadCommand: break;
		case RKResponseCodeErrorUnsupported: break;
		case RKResponseCodeErrorBadMessage: break;
		case RKResponseCodeErrorParameter: break;
		case RKResponseCodeErrorExecute: break;
		case RKResponseCodeUnknownDevice: break;
		case RKResponseCodeLowVoltageError: break;
		case RKResponseCodeIllegalPageNum: break;
		case RKResponseCodeFlashFail: break;
		case RKResponseCodeMainAppCorrupt: break;
		case RKResponseCodeResponseTimeout: break;
		case RKResponseCodeErrorTimeout: break;
		case RKResponseCodeTimeoutErr: break;
		default: break;
	}

	
	if([response isKindOfClass:[RKOrbBasicAppendFragmentResponse class]])
	{
//		RKOrbBasicAppendFragmentResponse *resp = (RKOrbBasicAppendFragmentResponse *) response;
		
		if(response.code == RKResponseCodeErrorParameter)
		{
//			_messageView.text = [_messageView.text stringByAppendingFormat:@"Syntax error.\n"];
		}
		else if(response.code == RKResponseCodeErrorExecute)
		{
//			_messageView.text = [_messageView.text stringByAppendingFormat:@"Memory full! Program not loaded.\n"];
		}
	}
	
//	if([response isKindOfClass:[RKOrbBasicAppendFragmentResponse class]])
//	{
//		RKOrbBasicAppendFragmentResponse *resp = (RKOrbBasicAppendFragmentResponse *) response;
//	}
}


-(void) handleResponseString:(NSString*) stringResponse forRobot:(id<RKRobotBase>) robot
{
	NSLog(@"handleResponseString: \"%@\"", stringResponse);
}



-(void) handleAsyncMessage:(RKAsyncMessage *)message forRobot:(id<RKRobotBase>)robot
{
	NSLog(@"handleAsyncMessage");
	NSLog(@"\tmessage: %@, class: %@", message, [RKOrbBasicPrintMessage class]);
	if([message isKindOfClass:[RKOrbBasicPrintMessage class]])
	{
		// Show print message that are generated by the program to the user.
		RKOrbBasicPrintMessage *printMessage = (RKOrbBasicPrintMessage *)message;
//		_messageView.text = [_messageView.text stringByAppendingFormat:@"orbBasic Print: %@", printMessage.message];
		NSLog(@"RKOrbBasicPrintMessage: %@", printMessage.message);
	}
	else if([message isKindOfClass:[RKOrbBasicErrorASCII class]])
	{
		// Show code error messages to the user.
		RKOrbBasicErrorASCII *errorMessage = (RKOrbBasicErrorASCII *)message;
		NSLog(@"RKOrbBasicErrorASCII: %@", errorMessage.error);
//		_messageView.text = [_messageView.text stringByAppendingFormat:@"orbBasic Error: %@", errorMessage.error];
	}
	else if([message isKindOfClass:[RKOrbBasicErrorBinary class]])
	{
//		_messageView.text = @"orbBasic binary error.";
		NSLog(@"RKOrbBasicErrorBinary: %@", message.description);
	}
}

- (void)handleConnected
{
	NSLog(@"handleConnected");
//	[_robot sleep];
	[[self calibrateHandler] setRobot:robot.robot];
	[robot addResponseObserver:self];
//	// Enable buttons
//	self.appendButton.enabled = YES;
//	self.executeButton.enabled = NO;
//	self.abortButton.enabled = YES;
//	self.eraseButton.enabled = YES;
//	self.messageView.text = @"Select a program, load it to Sphero, and press to execute to run it. Press the Erase button to erase the program before loading another program.";
//	[self rebuildProperties];
//	[self.tableView reloadData];
}

- (void)handleDisconnected
{
	NSLog(@"handleDisconnected");
	if(![[RKRobotDiscoveryAgent sharedAgent] isDiscovering])
		[RKRobotDiscoveryAgent startDiscovery];
//	self.appendButton.enabled = NO;
//	self.executeButton.enabled = NO;
//	self.abortButton.enabled = NO;
//	self.eraseButton.enabled = NO;
//	[self.orbBasicProgram erase]; // This will change the state back to being unloaded.
//	self.messageView.text = @"Robot disconnected.";
}





#else

- (nullable NSObject *)sharedRobot { return nil; }

- (nullable NSObject *)compile:(nonnull NSString *) file directory:(nonnull NSString *) dir error:(NSError *_Nullable *_Nullable) error
{
	return [[NSObject alloc] init];
}

- (void)setProgram:(nonnull NSObject *) program {}
- (BOOL)uploadProgram { return NO; }
- (BOOL)executeProgram { return NO; }
- (BOOL)hasRobot { return NO; }
- (BOOL)hasProgram { return NO; }


#endif

//+ (RKConvenienceRobot *)sharedRobotConvenience
//{
//	
//}

//+ (RKRobotClassic *)sharedRobot
//{
//	RKRobotBase *robot = [[[RKRobotDiscoveryAgent sharedAgent] onlineRobots] firstObject];
//	return robot;
//}



@end
