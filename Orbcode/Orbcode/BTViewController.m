//
//  BTViewController.m
//  Orbcode
//
//  Created by Alexander Kozlovskij on 14.03.17.
//  Copyright © 2017 FZZR. All rights reserved.
//

#import "BTViewController.h"
#import "OrbInfoViewController.h"
#import "OrbcodeExecutor.h"

#if TARGET_IPHONE_SIMULATOR
#endif
#if TARGET_OS_IPHONE
#endif

@interface BTViewController ()
{
}

@property (strong, nonatomic) BluetoothManager *btm;

//@property (strong, nonatomic) UIBarButtonItem *connectBtn;
//@property (strong, nonatomic) UIBarButtonItem *undo;

@property (strong, nonatomic) NSMutableArray<BluetoothDevice *> *knownDevices;

@property (strong, nonatomic) UISwitch *enableBluetoothSwitch;
@property (strong, nonatomic) UISwitch *scanningBluetoothSwitch;

@end

@implementation BTViewController

//#define SEGUE_SHOW_BT_DEVICE_DETAILS @"showSpheroDeviceDetails"


- (void)preconfigureView
{
	// Setup view bars:
//	if(!self.extendedLayoutIncludesOpaqueBars)
//		self.edgesForExtendedLayout = UIRectEdgeNone;
	
	[self.refreshControl addTarget:self action:@selector(refreshListRequested) forControlEvents:UIControlEventValueChanged];
//	[self.refreshControl setAttributedTitle:[[NSAttributedString alloc] initWithString:@"pull to scan"]];
	
	_enableBluetoothSwitch = [[UISwitch alloc] init];
	[_enableBluetoothSwitch setOn:[_btm enabled]];
	[_enableBluetoothSwitch addTarget:self action:@selector(enableBluetoothSwitchTriggered:) forControlEvents:UIControlEventValueChanged];
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:_enableBluetoothSwitch];

	_scanningBluetoothSwitch = [[UISwitch alloc] init];
	[_scanningBluetoothSwitch setOn:[_btm deviceScanningEnabled]];
	[_scanningBluetoothSwitch addTarget:self action:@selector(scanningBluetoothSwitchTriggered:) forControlEvents:UIControlEventValueChanged];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:_scanningBluetoothSwitch];
}

- (void)configureView
{
	if([_btm connected])
		[self.navigationItem setPrompt:@"connected"];
	else if([_btm deviceScanningEnabled])
		[self.navigationItem setPrompt:@"scanning"];
	else if([_btm connectable])
		[self.navigationItem setPrompt:@"connectable"];
	else if([_btm powered])
		[self.navigationItem setPrompt:@"powered"];
	else if([_btm enabled])
		[self.navigationItem setPrompt:@"enabled"];
	else
		[self.navigationItem setPrompt:@"disabled"];
	
	
	if(self.refreshControl.refreshing)
		[self.refreshControl setAttributedTitle:[[NSAttributedString alloc] initWithString:@"scanning.."]];
	else
		[self.refreshControl setAttributedTitle:[[NSAttributedString alloc] initWithString:@"pull to scan"]];
	if(self.refreshControl.refreshing && ![_btm deviceScanningEnabled])
		[self.refreshControl endRefreshing];
	
	
	[_enableBluetoothSwitch setOn:[_btm enabled]];
	[_scanningBluetoothSwitch setEnabled:[_enableBluetoothSwitch isOn]];
	[_scanningBluetoothSwitch setOn:[_btm deviceScanningEnabled]];
	
	//	NSLog(@"%@", [NSThread currentThread]);
//	if(self.detailItem && self.orblocks && self.orblocks.viewLoaded)
//	{
//		self.title = [self.detailItem title];
//		[[self.orblocks view] setHidden:NO];
//		[self setEnabledRightBarButtonItem:YES];
//	}
//	else
//	{
//		self.title = @"...";
//		self.detailDescriptionLabel.text = @"plz select the project and have fun";
//		[[self.orblocks view] setHidden:YES];
//		[self setEnabledRightBarButtonItem:NO];
//	}
//	
//	// History btns update:
//	if(orblocks)
//		[orblocks updateAvailabilityUndo:_undo redo:_redo];
//	else
//	{
//		[_undo setEnabled:NO];
//		[_redo setEnabled:NO];
//	}
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
	
	
//	NSLog(@"Loading PrivateFrameworks...");
//	NSBundle *b = [NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/FTServices.framework"];
//	
//	BOOL success = [b load];
//	NSLog(@"NSBundle load success: %@", success ? @"true" : @"false");
//	
//	Class FTDeviceSupport = NSClassFromString(@"FTDeviceSupport");
//	id si = [FTDeviceSupport valueForKey:@"sharedInstance"];
//	NSLog(@"-- %@", [si valueForKey:@"deviceColor"]);
	
	
	[self setKnownDevices:[NSMutableArray<BluetoothDevice *> array]];
	
	[self preconfigureView];
	[self initBluetoothManager];
	[self configureView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Table view data source


- (void)initBluetoothManager
{
	NSBundle *bt = [NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/BluetoothManager.framework"];
	
	BOOL success = [bt load];
	NSLog(@"Bluetooth NSBundle load success: %@", success ? @"true" : @"false");
	
	if(!success) return;
	
	Class BluetoothDeviceClass = NSClassFromString(@"BluetoothDevice");
	Class BluetoothManagerClass = NSClassFromString(@"BluetoothManager");
	Class RemoteDeviceManagerClass = NSClassFromString(@"RemoteDeviceManager");
	NSLog(@"BluetoothDevice: %@", BluetoothDeviceClass);
	NSLog(@"BluetoothManager: %@", BluetoothManagerClass);
	NSLog(@"RemoteDeviceManager: %@", RemoteDeviceManagerClass);
	
	BluetoothManager *btm = [BluetoothManagerClass valueForKey:@"sharedInstance"];
	[self setBtm:btm];
	
	NSLog(@"BTM.sharedInstance: %@", btm);
	NSLog(@"bt enabled: %hhd", [btm enabled]);
	NSLog(@"bt powered: %hhd", [btm powered]);
//	NSLog(@"bt available: %@", [btm ava]);
	NSLog(@"bt connectable: %hhd", [btm connectable]);
//	NSLog(@"bt canBeConnected: %hhd", [btm canBeConnected]);
	NSLog(@"bt pairedDevices: %@", [btm pairedDevices]);
	NSLog(@"bt devicePairingEnabled: %hhd", [btm devicePairingEnabled]);
	NSLog(@"bt deviceScanningEnabled: %hhd", [btm deviceScanningEnabled]);
//	NSLog(@"bt deviceScanningInProgress: %@", [btm scann]);
	NSLog(@"bt isDiscoverable: %hhd", [btm isDiscoverable]);
	id localAddress = [btm valueForKey:@"localAddress"];
	NSLog(@"bt localAddress: %@", localAddress);
	
	
	// setup bluetooth notifications
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceDiscovered:)
												 name:@"BluetoothDeviceDiscoveredNotification" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bluetoothAvailabilityChanged:)
												 name:@"BluetoothAvailabilityChangedNotification" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bluetoothPowerChanged:)
												 name:@"BluetoothPowerChangedNotification" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bluetoothConnectabilityChanged:)
												 name:@"BluetoothConnectabilityChangedNotification" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bluetoothDeviceRemoved:)
												 name:@"BluetoothDeviceRemovedNotification" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bluetoothDiscoveryStateChanged:)
												 name:@"BluetoothDiscoveryStateChangedNotification" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bluetoothConnectionStatusChanged:)
												 name:@"BluetoothConnectionStatusChangedNotification" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bluetoothDiscoveryStopped:)
												 name:@"BluetoothDiscoveryStoppedNotification" object:nil];
	
	// TODO: listen device directly:
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bluetoothDeviceConnectFailed:)
												 name:@"BluetoothDeviceConnectFailedNotification" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bluetoothDeviceConnectSuccess:)
												 name:@"BluetoothDeviceConnectSuccessNotification" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bluetoothDeviceDisconnectFailed:)
												 name:@"BluetoothDeviceDisconnectFailedNotification" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bluetoothDeviceDisconnectSuccess:)
												 name:@"BluetoothDeviceDisconnectSuccessNotification" object:nil];
	
	
	// global notification explorer
	CFNotificationCenterAddObserver(CFNotificationCenterGetLocalCenter(), NULL, globalNotificationsCallBack, NULL, NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
	
	
	if([_btm enabled] || [_btm powered])
		[self refreshDevicesList];
}


// global notification callback
void globalNotificationsCallBack (CFNotificationCenterRef center, void *observer,CFStringRef _name, const void *object, CFDictionaryRef userInfo)
{
	NSString *name = (__bridge NSString *)_name;
	if([name containsString:@"Bluetooth"])
		NSLog(@"CFN Name:%@ Data:%@", _name, userInfo);
	
	
	NSArray<NSString *> *events = @[@"BluetoothDeviceConnectFailedNotification",
									@"BluetoothDeviceConnectSuccessNotification",
									@"BluetoothDeviceDisconnectFailedNotification",
									@"BluetoothDeviceDisconnectSuccessNotification"];
	if([events indexOfObject:name] != NSNotFound)
	{
		NSLog(@"EVENT!!! %@ %@", name, userInfo);
		// TODO: call refresh
//		[self refreshDevicesList];
//		[self configureView];
	}
}

/* Bluetooth notifications */
- (void)bluetoothPowerChanged:(NSNotification *)notification
{
	NSLog(@"NOTIFICATION:bluetoothPowerChanged called. BT State: %d ( with %@ )", [_btm powered], [notification object]);
	
	[self refreshDevicesList];
	[self configureView];
}

- (void)bluetoothDiscoveryStateChanged:(NSNotification *)notification
{
	NSLog(@"NOTIFICATION:bluetoothDiscoveryStateChanged called. BT Scanning: %d ( with %@ )", [_btm deviceScanningEnabled], [notification object]);
	
	[self configureView];
}

- (void)bluetoothDiscoveryStopped:(NSNotification *)notification
{
	NSLog(@"NOTIFICATION:bluetoothDiscoveryStopped called. Discoverable: %d, Scanning: %d, ( with %@ )", [_btm isDiscoverable], [_btm deviceScanningEnabled], [notification object]);
	
	[self configureView];
}

- (void)bluetoothConnectionStatusChanged:(NSNotification *)notification
{
	NSLog(@"NOTIFICATION:bluetoothConnectionStatusChanged called. BT Connected: %d ( with %@ )", [_btm connected], [notification object]);
	
	[self configureView];
}


- (void)bluetoothAvailabilityChanged:(NSNotification *)notification
{
	NSLog(@"NOTIFICATION:bluetoothAvailabilityChanged called. BT Availability: %d ( with %@ )", [_btm connectable], [notification object]);
	
	[self refreshDevicesList];
	[self configureView];
}

- (void)bluetoothConnectabilityChanged:(NSNotification *)notification
{
	NSLog(@"NOTIFICATION:bluetoothConnectabilityChanged called. BT Connectability: %d ( with %@ )", [_btm connectable], [notification object]);
	
//	[self refreshDevicesList];
	[self configureView];
}

- (void)bluetoothDeviceRemoved:(NSNotification *)notification
{
	NSLog(@"NOTIFICATION:bluetoothDeviceRemoved called. BT removed: %@", [notification object]);
	
	[self removeFromDevicesList:[notification object]];
	[self.tableView reloadData];
	[self configureView];
}


- (void)deviceDiscovered:(NSNotification *) notification
{
	BluetoothDevice *device = [notification object];
	NSLog(@"NOTIFICATION:deviceDiscovered: %@ %@", device.name, device.address);
	[self addToDevicesList:device];
	[self.tableView reloadData];
	[self configureView];
}


- (void)bluetoothDeviceConnectFailed:(NSNotification *) notification
{
//	BluetoothDevice *device = [notification object];
	NSLog(@"NOTIFICATION:device CONNECTION Failed: %@", [notification object]);
	[self refreshDevicesList];
	[self configureView];
}

- (void)bluetoothDeviceConnectSuccess:(NSNotification *) notification
{
//	BluetoothDevice *device = [notification object];
	NSLog(@"NOTIFICATION:device CONNECTION Success: %@", [notification object]);
	[self refreshDevicesList];
	[self configureView];
}

- (void)bluetoothDeviceDisconnectFailed:(NSNotification *) notification
{
	//	BluetoothDevice *device = [notification object];
	NSLog(@"NOTIFICATION:device CONNECTION Failed: %@", [notification object]);
	[self refreshDevicesList];
	[self configureView];
}

- (void)bluetoothDeviceDisconnectSuccess:(NSNotification *) notification
{
	//	BluetoothDevice *device = [notification object];
	NSLog(@"NOTIFICATION:device CONNECTION Success: %@", [notification object]);
	[self refreshDevicesList];
	[self configureView];
}



#pragma mark - Data Model works



- (void)addToDevicesList:(BluetoothDevice *)device
{
	BOOL existing = NO;
	
	for(BluetoothDevice *known in _knownDevices)
	{
		existing = existing || [self devicesIsEqual:known with:device];
		if(existing)
			break;
	}
	
	if(!existing)
	{
		NSLog(@"adding device: %@", device);
		[_knownDevices addObject:device];
	}
}

- (void)removeFromDevicesList:(BluetoothDevice *)device
{
	NSUInteger index = [_knownDevices indexOfObject:device];
	if(index != NSNotFound)
		[_knownDevices removeObject:device];
	else
		for(BluetoothDevice *known in _knownDevices)
		{
			BOOL eq = [self devicesIsEqual:known with:device];
			if(eq)
			{
				NSLog(@"removing device: %@", device);
				[_knownDevices removeObject:known];
			}
		}
//	[self.tableView reloadData];
}

- (BOOL)devicesIsEqual:(BluetoothDevice *)a with:(BluetoothDevice *)b
{
//	NSString *nameA = (__bridge NSString *)[a name];
//	NSString *nameB = (__bridge NSString *)[b name];
	
	BOOL names_eq = [[a name] isEqualToString:[b name]];
	BOOL addresses_eq = [[a address] isEqualToString:[b address]];
	NSLog(@"comparing %@ and %@ :: %d / %d", a, b, names_eq, addresses_eq);
	return names_eq && addresses_eq;
}


- (void)refreshDevicesList
{	
	NSMutableArray<BluetoothDevice *> *pairedDevices = [_btm pairedDevices];
//	_knownDevices = [NSMutableArray<BluetoothDevice *> arrayWithArray:(pairedDevices != nil ? pairedDevices : @[])];
	if(pairedDevices != nil)
		for(BluetoothDevice *item in pairedDevices)
			[self addToDevicesList:item];
	
//	@try {
//		NSMutableArray<BluetoothDevice *> *connectableDevices = [_btm connectableDevices];
//		if(connectableDevices != nil)
//			for (BluetoothDevice *item in connectableDevices)
//				[self addToDevicesList:item];
//	} @catch (NSException *exception) {
//		
//	} @finally {
//		
//	}
	
	for (BluetoothDevice *item in _knownDevices)
	{
		NSLog(@"Device: %@, %@, %d, %d, %@", [item name], [item address], [item paired], [item type], [item address]);
	}
	
	[self.tableView reloadData];
}

- (NSArray<BluetoothDevice *> *)getConnectedDevices
{
	NSPredicate *connectedDevicePredicate = [NSPredicate predicateWithFormat:@"connected = YES"];
	return [_knownDevices filteredArrayUsingPredicate:connectedDevicePredicate];
}


#pragma mark - Sphero detecting

static BluetoothDevice * _spheroBluetoothDevice = nil;

- (BOOL)spheroIsConnected:(BOOL)refresh
{
	return [[self spheroBluetoothDevice:refresh] connected];
}

- (BluetoothDevice *)spheroBluetoothDevice:(BOOL)refresh
{
	if(!refresh && _spheroBluetoothDevice != nil)
		return _spheroBluetoothDevice;
	
	// get connected devices
	NSArray<BluetoothDevice *> *devices = [self knownDevices];//[self getConnectedDevices];
//	NSLog(@"ConnectedDevices: %d %@", [devices count], devices);
	
	for (BluetoothDevice *device in devices)
	{
//		NSLog(@"connected %@", [device name]);
		if([self deviceIsSphero:device])
		{
			_spheroBluetoothDevice = device;
			break;
		}
	}
	
	return _spheroBluetoothDevice;
}

- (BOOL)deviceIsSphero:(BluetoothDevice *)device
{
	return [[device name] containsString:@"Sphero"];
}



#pragma mark - UITableView Delegate implementation


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
//	UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
//	cell.accessoryType = UITableViewCellAccessoryCheckmark;
	BluetoothDevice *device = [_knownDevices objectAtIndex:indexPath.row];
	BluetoothDevice *sphero = [self spheroBluetoothDevice:NO];
	
	if(sphero != nil && [self devicesIsEqual:sphero with:device] && [sphero connected])
	{
//		[self performSegueWithIdentifier:SEGUE_SHOW_BT_DEVICE_DETAILS sender:nil];
		[[[OrbcodeExecutor sharedExecutor] view] refreshView];
	}
//	else
	if(![device connected])
		[device connect];
	else
	{
//		NSLog(@"syncSettings:: %@", [device respondsToSelector:@selector(@"syncSettings")]);
		NSLog(@"syncSettings:: %@", [device valueForKey:@"syncGroups"]);
		NSLog(@"syncSettings:: %@", [device valueForKey:@"syncSettings"]);
		[device disconnect];
	}
}



#pragma mark - UI Reactions

- (void)enableBluetoothSwitchTriggered:(id)sender
{
	NSLog(@"enableBluetoothSwitchTriggered: %d", [_enableBluetoothSwitch isOn]);
	
	if([_enableBluetoothSwitch isOn])
	{
//		[_btm setPowered:YES];
		[_btm setEnabled:YES];
	}
	else
	{
//		[_btm setPowered:NO];
		[_btm setEnabled:NO];
	}
	
	[_scanningBluetoothSwitch setEnabled:[_enableBluetoothSwitch isOn]];
}

- (void)scanningBluetoothSwitchTriggered:(id)sender
{
	NSLog(@"scanningBluetoothSwitchTriggered: %d", [_scanningBluetoothSwitch isOn]);
	[_btm setDeviceScanningEnabled:[_scanningBluetoothSwitch isOn]];
	[self configureView];
	if([_scanningBluetoothSwitch isOn])
		[self.refreshControl beginRefreshing];
	else
		[self.refreshControl endRefreshing];
}


- (void)refreshListRequested
{
	if(![self.refreshControl isRefreshing])
		[self.refreshControl beginRefreshing];
	
//	if(![_btm powered])
//		[_btm setPowered:YES];
	
	if(![_btm enabled])
		[_btm setEnabled:YES];
	
	[_btm setDeviceScanningEnabled:YES];
	
//	if(![_btm connectable])
//		[_btm setConnectable:YES];
	
	[self refreshDevicesList];
	[self configureView];
}


#pragma mark - Table view data source


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_knownDevices count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"BluetoothDeviceCell" forIndexPath:indexPath];
    
	BluetoothDevice *item = [_knownDevices objectAtIndex:indexPath.row];
	cell.textLabel.text = [item name];
	cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %d", [item address], [item type]];
	
	if([item connected])
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
//	else if([item available])
//		cell.accessoryType = UITableViewCellAccessoryDetailButton;
	else
		cell.accessoryType = UITableViewCellAccessoryNone;
	return cell;
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark - Navigation: Segues


// TODO: use SEGUE_SHOW_BT_DEVICE_DETAILS


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	NSLog(@"prepare SEGUE: %@", [segue identifier]);
//	if([[segue identifier] isEqualToString:SEGUE_SHOW_BT_DEVICE_DETAILS])
//	{
//		NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
//		BluetoothDevice *item = self.knownDevices[indexPath.row];
//		//
//		NSLog(@"%@", [segue destinationViewController]);
//		NSLog(@"%@", [[segue destinationViewController] class]);
//		
////		NSLog(@"%@", [[segue destinationViewController] topViewController]);
////		NSLog(@"%@", [[[segue destinationViewController] topViewController] class]);
////		OrbInfoViewController *controller = (OrbInfoViewController *)[[segue destinationViewController] topViewController];
//		OrbInfoViewController *controller = (OrbInfoViewController *)[segue destinationViewController];
//		[controller setBluetoothDevice:item];
//
//		
//		controller.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
//		controller.navigationItem.leftItemsSupplementBackButton = YES;
//	}
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
	NSLog(@"should SEGUE: %@", identifier);
//	if([identifier isEqualToString:@"showDetail"])
//	{
//		NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
//		ProjectModel *item = self.objects[indexPath.row];
//		return ![[[self getOrbEditorViewController] detailItem] isEqual:item];
//	}
	return sender == nil;
}

@end
