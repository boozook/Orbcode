//
//  NSObject+FilenameUITextFieldValidator.h
//  Orbcode
//
//  Created by Alexander Kozlovskij on 03/03/17.
//  Copyright © 2017 FZZR. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "StorageManager.h"

@interface FilenameUITextFieldValidator : NSObject <UITextFieldDelegate>

@property (strong, nonatomic) NSString * _Nonnull fileExt;
@property (strong, nonatomic) UIAlertAction * _Nullable actor;

- (nonnull instancetype)initWithExt:(nonnull NSString *)ext andActor:(nullable UIAlertAction *)disablable;
+ (nonnull instancetype)validatorWithExt:(nonnull NSString *)ext andActor:(nullable UIAlertAction *)disablable;

- (BOOL)textField:(nonnull UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(nullable NSString *)string;

@end
