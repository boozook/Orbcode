//
//  OrbcodeCompiler.m
//  OrbcodeCompiler
//
//  Created by Alexander Kozlovskij on 13.04.17.
//  Copyright © 2017 FZZR. All rights reserved.
//

#import "OrbcodeCompiler.h"
#import <hxcpp.h>
#import <haxe/ds/IntMap.h>
//#import <haxe/ds/StringMap.h>
#import "KernelBuildResult.h"
#import "KernelBuilder.h"



@implementation CompilerResult

@synthesize output;
@synthesize errors;
@synthesize lines;
@synthesize ignores;
@synthesize c_infos;
@synthesize c_errors;

@end



@implementation OrbcodeCompiler

+ (void)initLibrary
{
	HX_TOP_OF_STACK hx::Boot(); __boot_all();
}


+ (CompilerResult *)build:(NSString *)workspace
{
	fzzr::comp::KernelBuildResult res = nil;
	try
	{
		res = ::fzzr::comp::KernelBuilder_obj::build(workspace);
	}
	catch (NSException *error)
	{
		return [[CompilerResult alloc] init];
	}
	
	CompilerResult *build = [[CompilerResult alloc] init];
	[build setOutput:res->src];
	
	[build setErrors:[NSMutableDictionary<NSString *, NSString *> dictionary]];
	for (int i = 0; i < res->errors->length; i += 2)
		[[build errors] setObject:res->errors[i + 1] forKey:res->errors[i]];
	
	[build setLines:[NSMutableDictionary<NSNumber *, NSString *> dictionary]];
	for (int i = 0; i < res->lines->length; i += 2)
		[[build lines] setObject:res->lines[i + 1] forKey:[NSNumber numberWithInteger:[(NSString *)(res->lines[i]) integerValue]]];
	
	// ignores:
	NSMutableArray<NSString *> *ignores = [[NSMutableArray alloc] initWithCapacity:res->ignores->length];
	for (int i = 0; i < res->ignores->length; i++)
		ignores[i] = (NSString *)(res->ignores[i]);
	
	// cinfos:
	NSMutableArray<NSString *> *cinfos = [[NSMutableArray alloc] initWithCapacity:res->cinfos->length];
	for (int i = 0; i < res->cinfos->length; i++)
		cinfos[i] = (NSString *)(res->cinfos[i]);
	
	// cerrors:
	NSMutableArray<NSString *> *cerrors = [[NSMutableArray alloc] initWithCapacity:res->cerrors->length];
	for (int i = 0; i < res->cerrors->length; i++)
		cerrors[i] = (NSString *)(res->cerrors[i]);
	
	[build setIgnores:ignores];
	[build setC_infos:cinfos];
	[build setC_errors:cerrors];
	
	return build;
}

@end

