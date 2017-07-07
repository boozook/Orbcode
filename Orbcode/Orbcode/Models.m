//
//  NSObject+Models.m
//  Orbcode
//
//  Created by Alexander Kozlovskij on 27/02/17.
//  Copyright © 2017 FZZR. All rights reserved.
//

#import "Models.h"

@implementation ProjectModel

@synthesize title;
@synthesize filename;
@synthesize filepath;

- (id)initWithTitle:(NSString *)name filename:(NSString *)fname filepath:(NSURL *)fpath
{
	if(self = [super init])
	{
		self.title = name;
		self.filename = fname;
		self.filepath = fpath;
	}
	return self;
}

- (id)initWithPath:(NSURL *)path
{
	NSString *fullname = [path lastPathComponent];
	NSString *shortname = [fullname stringByDeletingPathExtension];
	// NSURL *directory = [path URLByDeletingLastPathComponent];
	// self = [self initWithFileName:fullname inDirectory:directory];
	return [self initWithTitle:shortname filename:fullname filepath:path];
}

- (id)initWithFileName:(NSString *)fullname inDirectory:(NSURL *)path
{
	if(self = [super init])
	{
		NSString *shortname = [fullname stringByDeletingPathExtension];
		self = [self initWithTitle:shortname
		                  filename:fullname
		                  filepath:[path URLByAppendingPathComponent:fullname isDirectory:YES]];
	}
	return self;
}

@end
