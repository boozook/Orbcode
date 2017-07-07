//
//  BTViewController.h
//  Orbcode
//
//  Created by Alexander Kozlovskij on 14.03.17.
//  Copyright © 2017 FZZR. All rights reserved.
//

#import <UIKit/UIKit.h>

#if TARGET_IPHONE_SIMULATOR
#endif
#if TARGET_OS_IPHONE
// TODO: here link private frameworks BT
#import "BluetoothManager.h"
#import "BluetoothDevice.h"
#endif


@interface BTViewController : UITableViewController

- (BluetoothDevice *)spheroBluetoothDevice:(BOOL)refresh;
- (BOOL)spheroIsConnected:(BOOL)refresh;

@end
