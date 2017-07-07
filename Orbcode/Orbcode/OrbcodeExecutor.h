//
//  OrbcodeExecutor.h
//  Orbcode
//
//  Created by Alexander Kozlovskij on 16.03.17.
//  Copyright © 2017 FZZR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OrbInfoViewController.h"
#if !TARGET_IPHONE_SIMULATOR
#import <RobotKit/RobotKit.h>
#import <RobotUIKit/RobotUIKit.h>
//#import <RobotCommandKit/RobotCommandKit.h>
#import <RobotKitClassic/RobotKitClassic.h>


@interface OrbcodeExecutor : NSObject <RKResponseObserver>
#else
@interface OrbcodeExecutor : NSObject
#endif

#if TARGET_OS_IPHONE && !TARGET_IPHONE_SIMULATOR

- (nullable RKConvenienceRobot *)sharedRobot;
//+ (RKRobotClassic *)sharedRobot;

//@property (strong, nonatomic) RKConvenienceRobot *robot;
//@property (strong, nonatomic) RUICalibrateGestureHandler *calibrateHandler;
//@property (strong, nonatomic) RKOrbBasicProgram *orbBasicProgram;


- (nullable RKOrbBasicProgram *)compile:(nonnull NSString *) file directory:(nonnull NSString *) dir error:(NSError *_Nullable *_Nullable) error;

- (void)setProgram:(nonnull RKOrbBasicProgram *) program;


#else

- (nullable NSObject *)sharedRobot;

- (nullable NSObject *)compile:(nonnull NSString *) file directory:(nonnull NSString *) dir error:(NSError *_Nullable *_Nullable) error;

- (void)setProgram:(nonnull NSObject *) program;

#endif


+ (nonnull OrbcodeExecutor *)sharedExecutor;

-(void)refreshRobot;

- (BOOL)uploadProgram;
- (BOOL)executeProgram;

- (BOOL)hasRobot;
- (BOOL)hasProgram;

@property (strong, nonatomic, nullable) OrbInfoViewController *view;
- (void)setViewForCalibrateHandler:(UIView *)cview;

@end

