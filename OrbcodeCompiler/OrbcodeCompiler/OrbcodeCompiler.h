//
//  OrbcodeCompiler.h
//  OrbcodeCompiler
//
//  Created by Alexander Kozlovskij on 13.04.17.
//  Copyright © 2017 FZZR. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>


//! Project version number for OrbcodeCompiler.
FOUNDATION_EXPORT double OrbcodeCompilerVersionNumber;

//! Project version string for OrbcodeCompiler.
FOUNDATION_EXPORT const unsigned char OrbcodeCompilerVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <OrbcodeCompiler/PublicHeader.h>


@interface CompilerResult : NSObject

@property (nonatomic, strong) NSString *output;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *errors;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSString *> *lines;
@property (nonatomic, strong) NSMutableArray<NSString *> *ignores;
@property (nonatomic, strong) NSMutableArray<NSString *> *c_infos;
@property (nonatomic, strong) NSMutableArray<NSString *> *c_errors;

@end



@interface OrbcodeCompiler : NSObject

+ (void)initLibrary;

+ (CompilerResult *)build:(NSString *)workspace;


@end


