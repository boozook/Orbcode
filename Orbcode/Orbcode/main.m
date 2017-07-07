//
//  main.m
//  Orbcode
//
//  Created by Alexander Kozlovskij on 24/02/17.
//  Copyright © 2017 FZZR. All rights reserved.
//


// ICONS:
// guid: https://developer.apple.com/ios/human-interface-guidelines/graphics/system-icons/
// robot: http://www.flaticon.com/free-icon/robot-of-short-spherical-shape_48716


#import "AppDelegate.h"
#import <UIKit/UIKit.h>
#import <OrbcodeCompiler/OrbcodeCompiler.h>


int main(int argc, char* argv[])
{
	@autoreleasepool {
		[OrbcodeCompiler initLibrary];
		return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
	}
}
