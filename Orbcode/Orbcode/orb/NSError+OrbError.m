//
//  NSError+OrbError.m
//  Orbcode
//
//  Created by Alexander Kozlovskij on 02/03/17.
//  Copyright © 2017 FZZR. All rights reserved.
//

#import "NSError+OrbError.h"
#import <Foundation/Foundation.h>

static NSString *const OrbErrorDomain = @"fzzr.OrbCode";


@implementation NSError (OrbError)

#define ERROR_KEY(code) [NSString stringWithFormat:@"%d", (int)code]
// #define ERROR_LOCALIZED_DESCRIPTION(code) NSLocalizedStringFromTable(ERROR_KEY(code), @"Errors", nil)


- (nonnull id)initWithCode:(OrbErrorCode)code description:(nullable NSString *)message
{
	NSDictionary *dict = @{ NSLocalizedDescriptionKey : (message == nil ? [NSError localizedDescriptionKeyByCode:code] : message) };
	return [self initWithDomain:OrbErrorDomain code:code userInfo:dict];
}

+ (nonnull instancetype)errorWithCode:(OrbErrorCode)code description:(nullable NSString *)message
{
	// NSDictionary *dict = (message == nil ? nil : @{ NSLocalizedDescriptionKey : message });
	NSDictionary *dict = @{ NSLocalizedDescriptionKey : (message == nil ? [NSError localizedDescriptionKeyByCode:code] : message) };
	return [NSError errorWithDomain:OrbErrorDomain code:code userInfo:dict];
}

- (NSString *)userDescription
{
	return [NSError localizedDescriptionKeyByCode:self.code];
}

+ (NSString *)localizedDescriptionKeyByCode:(OrbErrorCode)code
{
	NSString *errorDescrption = NSLocalizedStringFromTable(ERROR_KEY(code), @"Errors", nil);

	if(!errorDescrption || [errorDescrption isEqual:ERROR_KEY(code)])
		return NSLocalizedStringFromTable(@"Unknown error", @"Errors", nil);
	else
		return NSLocalizedStringFromTable(ERROR_KEY(code), @"Errors", nil);
	return nil;
}

@end
