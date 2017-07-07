#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wvisibility"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wvisibility"

////
////  BluetoothManager.h
////
//
////#ifndef BluetoothManager_h
////#define BluetoothManager_h
//
////#include "CDStructures.h"
//
///* Generated by RuntimeBrowser
// Image: /System/Library/PrivateFrameworks/BluetoothManager.framework/BluetoothManager
// */
//
//@interface BluetoothManager : NSObject {
////	struct BTAccessoryManagerImpl { } *_accessoryManager;
//	BOOL _audioConnected;
//	int _available;
//	NSMutableDictionary *_btAddrDict;
//	NSMutableDictionary *_btDeviceDict;
//	struct BTDiscoveryAgentImpl { } *_discoveryAgent;
//	struct BTLocalDeviceImpl { } *_localDevice;
//	struct BTPairingAgentImpl { } *_pairingAgent;
//	BOOL _scanningEnabled;
//	BOOL _scanningInProgress;
//	unsigned int _scanningServiceMask;
//	struct BTSessionImpl { } *_session;
//}
//
//// Image: /System/Library/PrivateFrameworks/BluetoothManager.framework/BluetoothManager
//
//+ (int)lastInitError;
//+ (void)setSharedInstanceQueue:(id)arg1;
//+ (id)sharedInstance;
//
//- (struct BTAccessoryManagerImpl { }*)_accessoryManager;
//- (void)_advertisingChanged;
//- (BOOL)_attach:(id)arg1;
//- (void)_cleanup:(BOOL)arg1;
//- (void)_connectabilityChanged;
//- (void)_connectedStatusChanged;
//- (void)_discoveryStateChanged;
//- (BOOL)_onlySensorsConnected;
//- (void)_postNotification:(id)arg1;
//- (void)_postNotificationWithArray:(id)arg1;
//- (void)_powerChanged;
//- (void)_removeDevice:(id)arg1;
//- (void)_restartScan;
//- (void)_scanForServices:(unsigned int)arg1 withMode:(int)arg2;
//- (void)_setScanState:(int)arg1;
//- (BOOL)_setup:(struct BTSessionImpl { }*)arg1;
//- (void)acceptSSP:(int)arg1 forDevice:(id)arg2;
//- (id)addDeviceIfNeeded:(struct BTDeviceImpl { }*)arg1;
//- (BOOL)audioConnected;
//- (BOOL)available;
//- (void)cancelPairing;
//- (void)connectDevice:(id)arg1;
//- (void)connectDevice:(id)arg1 withServices:(unsigned int)arg2;
//- (BOOL)connectable;
//- (BOOL)connected;
//- (id)connectedDevices;
//- (id)connectingDevices;
//- (void)dealloc;
//- (BOOL)devicePairingEnabled;
//- (BOOL)deviceScanningEnabled;
//- (BOOL)deviceScanningInProgress;
//- (void)disconnectDevice:(id)arg1;
//- (void)enableTestMode;
//- (BOOL)enabled;
//- (void)endVoiceCommand:(id)arg1;
//- (id)init;
//- (BOOL)isAnyoneAdvertising;
//- (BOOL)isAnyoneScanning;
//- (BOOL)isDiscoverable;
//- (BOOL)isServiceSupported:(unsigned int)arg1;
//- (id)localAddress;
//- (id)pairedDevices;
//- (void)postNotification:(id)arg1;
//- (void)postNotificationName:(id)arg1 object:(id)arg2;
//- (void)postNotificationName:(id)arg1 object:(id)arg2 error:(id)arg3;
//- (int)powerState;
//- (BOOL)powered;
//- (void)resetDeviceScanning;
//- (void)scanForConnectableDevices:(unsigned int)arg1;
//- (void)scanForServices:(unsigned int)arg1;
//- (void)setAudioConnected:(BOOL)arg1;
//- (void)setConnectable:(BOOL)arg1;
//- (void)setDevicePairingEnabled:(BOOL)arg1;
//- (void)setDeviceScanningEnabled:(BOOL)arg1;
//- (void)setDiscoverable:(BOOL)arg1;
//- (BOOL)setEnabled:(BOOL)arg1;
//- (void)setPincode:(id)arg1 forDevice:(id)arg2;
//- (BOOL)setPowered:(BOOL)arg1;
//- (void)showPowerPrompt;
//- (void)startVoiceCommand:(id)arg1;
//- (void)unpairDevice:(id)arg1;
//- (BOOL)wasDeviceDiscovered:(id)arg1;
//
//// Image: /System/Library/PrivateFrameworks/GameKitServices.framework/GameKitServices
//
//- (int)localDeviceSupportsService:(unsigned int)arg1;
//
//@end
//
////#endif /* BluetoothManager_h */


/*
 *     Generated by class-dump 3.1.1.
 *
 *     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2006 by Steve Nygard.
 */

//#import "NSObject.h"

@class BluetoothAudioJack, NSMutableArray;

@interface BluetoothManager : NSObject
{
	struct BTHandsfreeServiceImpl *_handsfreeService;
	struct BTLocalDeviceImpl *_localDevice;
	struct BTSessionImpl *_session;
	BOOL _audioConnected;
	BOOL _scanningEnabled;
	BOOL _pairingEnabled;
	int _powerState;
	struct BTDiscoveryAgentImpl *_discoveryAgent;
	struct BTPairingAgentImpl *_pairingAgent;
	struct BTAccessoryManagerImpl *_accessoryManager;
	NSMutableArray *_devices;
	BluetoothAudioJack *_audioJack;
}

+ (void)initialize;	// IMP=0x322709a4
+ (id)sharedInstance;	// IMP=0x32270378
- (id)_existingWrapperForDevice:(struct BTDeviceImpl *)fp8;	// IMP=0x32270fd0
- (void)_postNotification:(id)fp8;	// IMP=0x32270638
- (void)_postNotificationWithArray:(id)fp8;	// IMP=0x32270590
- (void)_powerChanged:(BOOL)fp8;	// IMP=0x32270d24
- (void)_setup;	// IMP=0x322709f4
- (void)_setupAccessoryManager;	// IMP=0x32270930
- (void)_setupHandsfreeService;	// IMP=0x322708a0
- (void)_setupLocalDevice;	// IMP=0x32270828
- (void)_setupSession;	// IMP=0x32270730
- (id)addDeviceIfNeeded:(struct BTDeviceImpl *)fp8;	// IMP=0x32271068
- (BOOL)audioConnected;	// IMP=0x32270fb0
- (id)audioJack;	// IMP=0x32271f20
- (BOOL)canBeConnected;	// IMP=0x32271c3c
- (void)cleanup;	// IMP=0x322703e0
- (void)connectDevice:(id)fp8;	// IMP=0x32271a90
- (BOOL)connectable;	// IMP=0x32271e9c
- (id)connectableDevices;	// IMP=0x32271c98
- (BOOL)connected;	// IMP=0x32270c08
- (void)dealloc;	// IMP=0x3227053c
- (BOOL)devicePairingEnabled;	// IMP=0x32271688
- (BOOL)deviceScanningEnabled;	// IMP=0x32271374
- (void)enableTestMode;	// IMP=0x32271fa4
- (BOOL)enabled;	// IMP=0x32270ea8
- (id)init;	// IMP=0x32270b74
- (BOOL)isDiscoverable;	// IMP=0x32271e14
- (void)pairDevice:(id)fp8;	// IMP=0x32271b14
- (id)pairedDevices;	// IMP=0x32271cc4
- (void)postNotification:(id)fp8;	// IMP=0x32270680
- (void)postNotificationName:(id)fp8 object:(id)fp12;	// IMP=0x322706bc
- (BOOL)powered;	// IMP=0x32270c58
- (void)serverTerminated;	// IMP=0x32270abc
- (void)setAirplaneMode:(BOOL)fp8;	// IMP=0x32270e68
- (void)setAudioConnected:(BOOL)fp8;	// IMP=0x32270fb8
- (void)setConnectable:(BOOL)fp8;	// IMP=0x32271ee4
- (void)setDevicePairingEnabled:(BOOL)fp8;	// IMP=0x3227158c
- (void)setDeviceScanningEnabled:(BOOL)fp8;	// IMP=0x32271258
- (void)setDiscoverable:(BOOL)fp8;	// IMP=0x32271e60
- (BOOL)setEnabled:(BOOL)fp8;	// IMP=0x32270ec8
- (void)setPincode:(id)fp8 forDevice:(id)fp12;	// IMP=0x32271690
- (BOOL)setPowered:(BOOL)fp8;	// IMP=0x32270d88
- (void)unpairDevice:(id)fp8;	// IMP=0x32271dbc

@end


#pragma GCC diagnostic pop
#pragma clang diagnostic pop