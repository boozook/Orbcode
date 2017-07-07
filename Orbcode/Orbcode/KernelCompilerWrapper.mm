//
//  KernelCompilerWrapper.m
//  Orbcode
//
//  Created by Alexander Kozlovskij on 30.03.17.
//  Copyright © 2017 FZZR. All rights reserved.
//

#import "KernelCompilerWrapper.h"
#import <hxcpp.h>
#import "KernelCompiler.h"

@implementation KernelCompilerWrapper

+ (void)build:(NSString *)workspace
{
	fzzr::comp::KernelCompiler_obj::build(workspace);
}

@end
