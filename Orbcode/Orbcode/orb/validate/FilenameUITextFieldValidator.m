//
//  NSObject+FilenameUITextFieldValidator.m
//  Orbcode
//
//  Created by Alexander Kozlovskij on 03/03/17.
//  Copyright © 2017 FZZR. All rights reserved.
//

#import "FilenameUITextFieldValidator.h"

@implementation FilenameUITextFieldValidator

@synthesize fileExt;
@synthesize actor;

+ (instancetype)validatorWithExt:(NSString *)ext andActor:(nullable UIAlertAction *)disablable
{
	return [[FilenameUITextFieldValidator alloc] initWithExt:ext andActor:disablable];
}

- (instancetype)initWithExt:(NSString *)ext andActor:(nullable UIAlertAction *)disablable
{
	if(self = [super init])
	{
		self.fileExt = ext;
		self.actor = disablable;
	}
	return self;
}


- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
	
  // verify the text field you wanna validate
	if (textField != nil)
	{
			// do not allow the first character to be space | do not allow more than one space
		if ([string isEqualToString:@" "])
		{
			if (!textField.text.length)
			{
				[[self actor] setEnabled:NO];
				return NO;
			}
				
			if ([[textField.text stringByReplacingCharactersInRange:range withString:string] rangeOfString:@"  "].length)
			{
				[[self actor] setEnabled:NO];
				return NO;
			}
		}
		
			// allow backspace
		if ([textField.text stringByReplacingCharactersInRange:range withString:string].length < textField.text.length)
		{
//			return YES;
		}
		
			// in case you need to limit the max number of characters
		if ([textField.text stringByReplacingCharactersInRange:range withString:string].length > 30)
		{
			[[self actor] setEnabled:NO];
			return NO;
		}
		
			// limit the input to only the stuff in this character set, so no emoji or cirylic or any other insane characters
		NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890 "];
		
		if ([string rangeOfCharacterFromSet:set].location == NSNotFound)
		{
			[[self actor] setEnabled:NO];
			return NO;
		}
	}
	
	@autoreleasepool
	{
		StorageManager *fs = [StorageManager sharedStorageManager];
		NSString *filename = [NSString stringWithFormat:@"%@.orbcode", textField.text];
		BOOL result = [fs createFileIsPossible:[fs getProjectFileURI:filename]];
		[[self actor] setEnabled:result];
		return result;
	}
	
//	return YES;
}


@end
