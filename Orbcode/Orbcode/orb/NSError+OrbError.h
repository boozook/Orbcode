//
//  NSError+OrbError.h
//  Orbcode
//
//  Created by Alexander Kozlovskij on 02/03/17.
//  Copyright © 2017 FZZR. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, OrbErrorCode) {
	OrbErrorCodeFileAlreadyExisting = -6004,
	OrbErrorCodeFileAlreadyExisting1 = -6005,
	OrbErrorCodeFileAlreadyExisting2 = -6006,
};


@interface NSError (OrbError)

- (nullable NSString *)userDescription;

- (nonnull instancetype)initWithCode:(OrbErrorCode)code description:(nullable NSString *)message;
+ (nonnull instancetype)errorWithCode:(OrbErrorCode)code description:(nullable NSString *)message;

@end
