//
//  OrbInfoViewController.m
//  Orbcode
//
//  Created by Alexander Kozlovskij on 15.03.17.
//  Copyright © 2017 FZZR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OrbInfoViewController.h"
#import "OrbcodeExecutor.h"
#if TARGET_OS_IPHONE && !TARGET_IPHONE_SIMULATOR
//#import <RobotKitClassic/RobotKitClassic.h>
#import <RobotKit/RobotKit.h>
#import <RobotUIKit/RobotUIKit.h>
#endif




@interface PropertyRow : NSObject
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *value;
- (instancetype)initWith:(NSString *)name value:(NSString *)value;
@end

@implementation PropertyRow

//@synthesize name;
//@synthesize value;

- (instancetype)initWith:(NSString *)name value:(NSString *)theValue
{
	if(self = [super init])
	{
		self.name = name;
		self.value = theValue;
	}
	return self;
}

+ (instancetype)row:(NSString *)name value:(NSString *)value
{
	return [[PropertyRow alloc] initWith:name value:value];
}
@end



#if TARGET_OS_IPHONE && !TARGET_IPHONE_SIMULATOR
@interface OrbInfoViewController () <RKResponseObserver>

@property (strong, nonatomic) RUICalibrateGestureHandler  *calibrateHandler;

#else
@interface OrbInfoViewController ()

#endif

@property (strong, nonatomic) UIBarButtonItem *sleepBtn;
@property (strong, nonatomic) NSMutableArray<PropertyRow *> *properties;


@end


@implementation OrbInfoViewController


- (void) refreshView
{
	NSLog(@"refreshView");
	[self refreshListRequested];
}

- (void)preconfigureView
{
	// Setup view bars:
	//	if(!self.extendedLayoutIncludesOpaqueBars)
	//		self.edgesForExtendedLayout = UIRectEdgeNone;

	[self.refreshControl addTarget:self action:@selector(refreshListRequested) forControlEvents:UIControlEventValueChanged];
	[self.refreshControl setAttributedTitle:[[NSAttributedString alloc] initWithString:@"pull to refresh"]];

//	_connectBluetoothDeviceSwitch = [[UISwitch alloc] init];
//	[_connectBluetoothDeviceSwitch setOn:[bluetoothDevice connected]];
//	[_connectBluetoothDeviceSwitch addTarget:self action:@selector(connectBluetoothDeviceSwitchTriggered:) forControlEvents:UIControlEventValueChanged];

	_sleepBtn = [[UIBarButtonItem alloc] initWithTitle:@"sleep" style:UIBarButtonItemStylePlain target:self action:@selector(sleepRequested:)];
//	self.navigationItem.rightBarButtonItems = @[_sleepBtn, [[UIBarButtonItem alloc] initWithCustomView:_connectBluetoothDeviceSwitch]];
	self.navigationItem.rightBarButtonItems = @[_sleepBtn];
}

- (void)configureView
{
	#if TARGET_OS_IPHONE && !TARGET_IPHONE_SIMULATOR
	RKConvenienceRobot *robot = [[OrbcodeExecutor sharedExecutor] sharedRobot];
	
	NSLog(@"configureView:: robot: %@", robot);
	
	// TOP Bar:
	if(robot != nil)
	{
		self.title = [robot name];
		
		if([robot isOnline])
			[self.navigationItem setPrompt:@"online"];
		else if([robot isConnected])
			[self.navigationItem setPrompt:@"connected"];
		else
			[self.navigationItem setPrompt:@"disconnected"];
	}
	else
	{
		self.title = @"";
		[self.navigationItem setPrompt:@"offline"];
	}
	[_sleepBtn setEnabled:(robot != nil && [robot isOnline])];
	
	
	// Table:
	if([[RKRobotDiscoveryAgent sharedAgent] isDiscovering] && ![robot isOnline])
	{
		if(![self.refreshControl isRefreshing])
			[self.refreshControl beginRefreshing];
	}
	else
	{
		if([self.refreshControl isRefreshing])
			[self.refreshControl endRefreshing];
	}

	if(self.refreshControl.refreshing)
		[self.refreshControl setAttributedTitle:[[NSAttributedString alloc] initWithString:@"refreshing"]];
	else
		[self.refreshControl setAttributedTitle:[[NSAttributedString alloc] initWithString:@"pull to refresh"]];
	#endif
}

- (void)refreshListRequested
{
	[self.refreshControl beginRefreshing];
	[[OrbcodeExecutor sharedExecutor] refreshRobot];
	[self rebuildProperties];
	[self configureView];
	[self.refreshControl endRefreshing];
}

- (void)sleepRequested:(id)sender
{
	NSLog(@"sleepRequested: %@", [[OrbcodeExecutor sharedExecutor] sharedRobot]);
	#if TARGET_OS_IPHONE && !TARGET_IPHONE_SIMULATOR
	[[[OrbcodeExecutor sharedExecutor] sharedRobot] sleep];
	#endif
}



- (void)rebuildProperties
{
	if(_properties == nil)
		_properties = [NSMutableArray<PropertyRow *> array];
}



- (void)viewDidLoad
{
    [super viewDidLoad];

     self.clearsSelectionOnViewWillAppear = NO;

	[self preconfigureView];
	[self configureView];

	#if !TARGET_IPHONE_SIMULATOR
//	[self initRobot];
	[[OrbcodeExecutor sharedExecutor] setView:self];
	[[OrbcodeExecutor sharedExecutor] setViewForCalibrateHandler:self.view];
	#endif

//	[[NSNotificationCenter defaultCenter] addObserver:self
//											 selector:@selector(appWillResignActive:)
//												 name:UIApplicationWillResignActiveNotification
//											   object:nil];
//	[[NSNotificationCenter defaultCenter] addObserver:self
//											 selector:@selector(appDidBecomeActive:)
//												 name:UIApplicationDidBecomeActiveNotification
//											   object:nil];
}

//- (void)appDidBecomeActive:(NSNotification *)notification
//{
//	#if !TARGET_IPHONE_SIMULATOR
//	[RKRobotDiscoveryAgent startDiscovery];
//	#endif
//}
//
//- (void)appWillResignActive:(NSNotification*)notification
//{
//	#if !TARGET_IPHONE_SIMULATOR
////	[RKRobotDiscoveryAgent disconnectAll];
//	[RKRobotDiscoveryAgent stopDiscovery];
//	#endif
//}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
}



@end


//@implementation OrbInfoViewController
//
//#define SPHERO_PROPERTY_CELL @"SpheroPropertyCell"
//

////@synthesize connectBluetoothDeviceSwitch;
//

//
//

//
//

//
//
//
////- (void)addRowIntoTheList
////{
////	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
////	[self.tableView insertRowsAtIndexPaths:@[ indexPath ]
////						  withRowAnimation:(immediately ? UITableViewRowAnimationNone : UITableViewRowAnimationAutomatic)];
////}
//
//- (void)viewDidAppear:(BOOL)animated
//{
//	[super viewDidAppear:animated];
//	[RKRobotDiscoveryAgent startDiscovery];
//}
//

//
//
//
//
//- (void)rebuildProperties
//{
////	if(_properties == nil)
//		_properties = [NSMutableArray<PropertyRow *> array];
//	
//	if(bluetoothDevice != nil)
//	{
//		[_properties addObject:[PropertyRow row:@"address" value:[bluetoothDevice address]]];
//		[_properties addObject:[PropertyRow row:@"description" value:[bluetoothDevice description]]];
//		[_properties addObject:[PropertyRow row:@"battery" value:[NSString stringWithFormat:@"%d", [bluetoothDevice batteryLevel]]]];
//		[_properties addObject:[PropertyRow row:@"major" value:[NSString stringWithFormat:@"%d", [bluetoothDevice majorClass]]]];
//		[_properties addObject:[PropertyRow row:@"minor" value:[NSString stringWithFormat:@"%d", [bluetoothDevice minorClass]]]];
//		[_properties addObject:[PropertyRow row:@"product" value:[NSString stringWithFormat:@"%d", [bluetoothDevice productId]]]];
//		[_properties addObject:[PropertyRow row:@"scoUID" value:[NSString stringWithFormat:@"%@", [bluetoothDevice scoUID]]]];
//		[_properties addObject:[PropertyRow row:@"type" value:[NSString stringWithFormat:@"%d", [bluetoothDevice type]]]];
//		[_properties addObject:[PropertyRow row:@"vendorId" value:[NSString stringWithFormat:@"%d", [bluetoothDevice vendorId]]]];
//		[_properties addObject:[PropertyRow row:@"connectedServices" value:[NSString stringWithFormat:@"%d", [bluetoothDevice connectedServices]]]];
//		[_properties addObject:[PropertyRow row:@"connectedServicesCount" value:[NSString stringWithFormat:@"%d", [bluetoothDevice connectedServicesCount]]]];
//	}
//	
//	if(_robot != nil)
//	{
////		if(_robot isMemberOfClass:RKRobot)
//		RKVersioningResponse *ver = [_robot lastVersioning];
//		NSString *model = nil;
//		switch([ver modelNumber])
//		{
//			case SpheroS1: model = @"SpheroS1"; break;
//			case SpheroS2: model = @"SpheroS2"; break;
//			case SpheroS3: model = @"SpheroS3"; break;
//			case OllieBadFirmware: model = @"OllieBadFirmware"; break;
//			case Ollie01: model = @"Ollie01"; break;
//			case BB8_01: model = @"BB8_01"; break;
//			case WeBall: model = @"WeBall"; break;
//			case Unknown4: model = @"Unknown4"; break;
//			default: model = [NSString stringWithFormat:@"%d", [ver modelNumber]]; break;
//		}
//		[_properties addObject:[PropertyRow row:@"model" value:model]];
//		[_properties addObject:[PropertyRow row:@"v.bootloader" value:[[ver bootloaderVersion] versionString]]];
//		[_properties addObject:[PropertyRow row:@"v.hardware" value:[ver hardwareVersion]]];
//		[_properties addObject:[PropertyRow row:@"v.mainApp" value:[[ver mainAppVersion] versionString]]];
//		[_properties addObject:[PropertyRow row:@"v.orbBasic" value:[ver orbBasicVersion]]];
//		[_properties addObject:[PropertyRow row:@"v.overlay.mng" value:[ver overlayManagerVersion]]];
//		[_properties addObject:[PropertyRow row:@"v.record" value:[ver recordVersion]]];
//		
//		[_properties addObject:[PropertyRow row:@"name" value:[_robot name]]];
//		[_properties addObject:[PropertyRow row:@"connected" value:[NSString stringWithFormat:@"%d", [_robot isConnected]]]];
//		[_properties addObject:[PropertyRow row:@"online" value:[NSString stringWithFormat:@"%d", [_robot isOnline]]]];
//		[_properties addObject:[PropertyRow row:@"identifier" value:[[_robot robot] identifier]]];
//		[_properties addObject:[PropertyRow row:@"serialNumber" value:[[_robot robot] serialNumber]]];
//		[_properties addObject:[PropertyRow row:@"isBootloader" value:[NSString stringWithFormat:@"%d", [[_robot robot] isBootloader]]]];
//	}
//}
//
//
//
//#pragma mark - Sphero Reactions
//
//
//-(void)initRobot
//{
//	[[RKRobotDiscoveryAgent sharedAgent] addNotificationObserver:self selector:@selector(handleRobotStateChangeNotification:)];
//	
//	if([[[RKRobotDiscoveryAgent sharedAgent] connectedRobots] count] == 0)
//		[RKRobotDiscoveryAgent startDiscovery];
//	else
//	{
//		id robo = [[[RKRobotDiscoveryAgent sharedAgent] connectedRobots] firstObject];
//		NSLog(@"ROBO::: %@ !!! %@", [robo class], robo);
//		_robot = [RKConvenienceRobot convenienceWithRobot:[[[RKRobotDiscoveryAgent sharedAgent] connectedRobots] firstObject]];
//		[self refreshListRequested];
//	}
//}
//
//- (void)handleRobotStateChangeNotification:(RKRobotChangedStateNotification*)notification
//{
//	NSLog(@"RK Notification: %@", notification);
//	switch(notification.type)
//	{
//		case RKRobotConnecting:
//			[self.navigationItem setPrompt:@"connecting"];
//			[self handleConnecting];
//			break;
//		case RKRobotOnline:
//		{
//			NSLog(@"RK robot class: %@", [notification.robot class]);
//			[self.navigationItem setPrompt:@"online"];
//			// Do not allow the robot to connect if the application is not running
//			RKConvenienceRobot *convenience = [RKConvenienceRobot convenienceWithRobot:notification.robot];
//			if([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive)
//			{
//				[convenience disconnect];
//				return;
//			}
//			self.robot = convenience;
//			[self handleConnected];
//			break;
//		}
//		case RKRobotDisconnected:
//			[self.navigationItem setPrompt:@"disconnected"];
//			[self handleDisconnected];
//			self.robot = nil;
//			[RKRobotDiscoveryAgent startDiscovery];
//			break;
//		default:
//			[self.navigationItem setPrompt:@"offline"];
//			break;
//	}
//	
//	[self configureView];
//}
//
//- (void)handleConnecting
//{
//	// Handle robot connecting here
//	NSLog(@"Connecting");
//}
//
//- (void)handleConnected
//{
//	NSLog(@"Connected");
//	[_robot sleep];
////	[_calibrateHandler setRobot:_robot.robot];
////	[_robot addResponseObserver:self];
////	// Enable buttons
////	self.appendButton.enabled = YES;
////	self.executeButton.enabled = NO;
////	self.abortButton.enabled = YES;
////	self.eraseButton.enabled = YES;
////	self.messageView.text = @"Select a program, load it to Sphero, and press to execute to run it. Press the Erase button to erase the program before loading another program.";
//	[self rebuildProperties];
//	[self.tableView reloadData];
//}
//
//- (void)handleDisconnected
//{
//	NSLog(@"Disconnected");
////	self.appendButton.enabled = NO;
////	self.executeButton.enabled = NO;
////	self.abortButton.enabled = NO;
////	self.eraseButton.enabled = NO;
////	[self.orbBasicProgram erase]; // This will change the state back to being unloaded.
////	self.messageView.text = @"Robot disconnected.";
//}
//
//
//
//-(void)deinitRobot
//{
//	// TODO:
//}
//
//
//-(void)connectToRobot
//{
////	[RKRobotConnected sharedRobotProvider];
////	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleRobotOnline:) name:kRobotDidChangeStateNotification object:nil];
////	if ([[RKRobotProvider sharedRobotProvider] isRobotUnderControl])
////	{
////		[[RKRobotProvider sharedRobotProvider] openRobotConnection];
////	}else
////	{
////		[[RKRobotProvider sharedRobotProvider] controlConnectedRobot];
////	}
//}
//
///** notification that Robot is Online and ready for use */
////-(void) handleRobotOnline:(NSNotification *)notification
////{
////	[self configureView];
//////	RKRobotClassic *robot = [notification.userInfo objectForKey:@"robot"];
//////	NSLog(@"Connected %@", robot);
////}
//
//
//#pragma mark Message Handlers
//
//- (void) handleResponse:(RKDeviceResponse *)response forRobot:(id<RKRobotBase>)robot
//{
//	NSLog(@"handleResponse: %@", response);
////	if ([response isKindOfClass:[RKOrbBasicAppendFragmentResponse class]]) {
////		if (response.code == RKResponseCodeErrorParameter) {
////			_messageView.text = [_messageView.text stringByAppendingFormat:@"Syntax error.\n"];
////		} else if (response.code == RKResponseCodeErrorExecute) {
////			_messageView.text = [_messageView.text stringByAppendingFormat:@"Memory full! Program not loaded.\n"];
////		}
////	}
//}
//
//-(void) handleResponseString:(NSString*) stringResponse forRobot:(id<RKRobotBase>) robot
//{
//	NSLog(@"handleResponseString: %@", stringResponse);
//}
//
//-(void) handleAsyncMessage:(RKAsyncMessage *)message forRobot:(id<RKRobotBase>)robot
//{
//	NSLog(@"handleAsyncMessage: %@", message);
////	if ([message isKindOfClass:[RKOrbBasicPrintMessage class]]) {
////		// Show print message that are generated by the program to the user.
////		RKOrbBasicPrintMessage *printMessage = (RKOrbBasicPrintMessage *)message;
////		_messageView.text = [_messageView.text stringByAppendingFormat:@"orbBasic Print: %@", printMessage.message];
////	} else if ([message isKindOfClass:[RKOrbBasicErrorASCII class]]) {
////		// Show code error messages to the user.
////		RKOrbBasicErrorASCII *errorMessage = (RKOrbBasicErrorASCII *)message;
////		_messageView.text = [_messageView.text stringByAppendingFormat:@"orbBasic Error: %@", errorMessage.error];
////	} else if ([message isKindOfClass:[RKOrbBasicErrorBinary class]]) {
////		_messageView.text = @"orbBasic binary error.";
////	}
//}
//
//
////-(void) handleReadOdometerResponse:(RKGetOdometerResponse*) response forRobot:(id<RKRobotBase>) robot
////{
////	
////}
////
////-(void) handleSleepWillOccurAsyncMessage:(RKSleepWillOccurMessage*) msg forRobot:(id<RKRobotBase>) robot
////{
////	
////}
////
////-(void) handleSleepDidOccurAsyncMessage:(RKSleepDidOccurMessage*) msg forRobot:(id<RKRobotBase>) robot
////{
////	
////}
////
////-(void) handleCollisionDetectedAsyncMessage:(RKCollisionDetectedAsyncData*) msg forRobot:(id<RKRobotBase>) robot
////{
////	
////}
////
////-(void) handleSensorsAsyncData:(RKDeviceSensorsAsyncData*) msg forRobot:(id<RKRobotBase>) robot
////{
////	
////}
//
//
//#pragma mark - UI Reactions
//
//- (void)connectBluetoothDeviceSwitchTriggered:(id)sender
//{
//	if([_connectBluetoothDeviceSwitch isOn] == [bluetoothDevice connected])
//		return;
//	
//	NSLog(@"connectBluetoothDeviceSwitchTriggered: %d", [_connectBluetoothDeviceSwitch isOn]);
//	
//	
//	
//	if([_connectBluetoothDeviceSwitch isOn])
//	{
//		[bluetoothDevice connect];
//	}
//	else
//	{
//		[bluetoothDevice disconnect];
//	}
//	[self configureView];
//}
//
//- (void)sleepRequested:(id)sender
//{
//	[_robot sleep];
//}
//
//
//
//
//#pragma mark - Table view data source
//
//- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
//{
//    return 1;
//}
//
//- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
//{
//    return [_properties count];
//}
//
////- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
////{
////}
//
////- (nullable NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
////{
////}
//
//- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
//{
//	return NO;
//}
//
//- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
//{
//	return NO;
//}
//
//- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:SPHERO_PROPERTY_CELL forIndexPath:indexPath];
//	
//	PropertyRow *item = [_properties objectAtIndex:indexPath.row];
//	cell.textLabel.text = [item name];
//	cell.detailTextLabel.text = [item value];
//	
//	return cell;
//}
//
//
///*
//- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
//    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
//    
//    // Configure the cell...
//    
//    return cell;
//}
//*/
//
///*
//// Override to support conditional editing of the table view.
//- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
//    // Return NO if you do not want the specified item to be editable.
//    return YES;
//}
//*/
//
///*
//// Override to support editing the table view.
//- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
//    if (editingStyle == UITableViewCellEditingStyleDelete) {
//        // Delete the row from the data source
//        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
//    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
//        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
//    }   
//}
//*/
//
///*
//// Override to support rearranging the table view.
//- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
//}
//*/
//
///*
//// Override to support conditional rearranging of the table view.
//- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
//    // Return NO if you do not want the item to be re-orderable.
//    return YES;
//}
//*/
//
///*
//#pragma mark - Navigation
//
//// In a storyboard-based application, you will often want to do a little preparation before navigation
//- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
//    // Get the new view controller using [segue destinationViewController].
//    // Pass the selected object to the new view controller.
//}
//*/
//
//@end
