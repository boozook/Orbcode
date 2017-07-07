//
//  KernelCompilerWrapper.h
//  Orbcode
//
//  Created by Alexander Kozlovskij on 30.03.17.
//  Copyright © 2017 FZZR. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import <Blockly/Blockly-Swift.h>
//#import <Blockly/Blockly.h>
//#import "Orbcode-Swift.h"

@interface KernelCompilerWrapper : NSObject

+ (void)build:(NSString *)workspace;

@end
