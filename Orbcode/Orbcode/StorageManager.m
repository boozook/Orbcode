//
//  StorageManager.m
//  Orbcode
//
//  Created by Alexander Kozlovskij on 01/03/17.
//  Copyright © 2017 FZZR. All rights reserved.
//

#import "StorageManager.h"
#import "orb/NSError+OrbError.h"
#import <Foundation/Foundation.h>


@interface StorageManager ()
{
}
@end



@implementation StorageManager

+ (StorageManager *)sharedStorageManager
{
	static StorageManager *sharedStorageManager;

	@synchronized(self)
	{
		if(!sharedStorageManager)
			sharedStorageManager = [[StorageManager alloc] init];

		return sharedStorageManager;
	}
}


static NSURL * _applicationDocumentsDirectory = nil;
// iOS 8 and newer, this is the recommended method
+ (NSURL *)applicationDocumentsDirectory
{
	return _applicationDocumentsDirectory ? _applicationDocumentsDirectory : [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

// support iOS 7 or earlier
//+ (NSString *) applicationDocumentsDirectory
//{
//	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//	NSString *basePath = paths.firstObject;
//	return basePath;
//}


- (nullable NSURL *)applicationDocumentsDirectory
{
	return [StorageManager applicationDocumentsDirectory];
}


- (nullable NSArray<NSString *> *)getListingOf:(NSURL *)directory
{
	NSError *error = nil;
	NSArray<NSString *> *filenames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[directory path] error:&error];
	return (error == nil ? filenames : @[]);
}


#pragma mark - Managing the Builds directory


static NSString *const BUILDS_DIRECTORY_NAME = @"builds";
static NSURL * _buildsDirectory = nil;

- (nullable NSURL *)buildsDirectory
{
	return _buildsDirectory ? _buildsDirectory : [self getBuildsDirectory:YES];
}

- (nullable NSURL *)getBuildsDirectory
{
	return [self getBuildsDirectory:YES];
}

- (nullable NSURL *)getBuildsDirectory:(BOOL)createIfNeed
{
	return [self getBuildsDirectory:YES error:nil];
}

- (nullable NSURL *)getBuildsDirectory:(BOOL)createIfNeed error:(NSError **)error
{
	if(_buildsDirectory != nil)
		return _buildsDirectory;
	
	NSURL *root = [StorageManager applicationDocumentsDirectory];
	NSURL *path = [root URLByAppendingPathComponent:BUILDS_DIRECTORY_NAME isDirectory:YES];
	
	if([path checkResourceIsReachableAndReturnError:nil])
		return path;
	NSLog(@"creating dir");
	
	[[NSFileManager defaultManager] createDirectoryAtPath:path.path withIntermediateDirectories:YES attributes:nil error:error];
	
	if(error != nil)
	{
		NSLog(@"Projects directory ERROR: %@", *error);
		return nil;
	}
	
	_buildsDirectory = path;
	return path;
}

- (nonnull NSURL *)getBuildFileURI:(NSString *)fullname
{
	return [self getBuildFileURI:fullname addExt:NO];
}

- (nonnull NSURL *)getBuildFileURI:(NSString *)fullname addExt:(BOOL)ext
{
	if(ext)
		return [[self buildsDirectory] URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.orbbas", fullname]];
	else
		return [[self buildsDirectory] URLByAppendingPathComponent:fullname];
}

- (nonnull NSString *)getBuildFileName:(NSString *)name
{
	return [NSString stringWithFormat:@"%@.orbbas", name];
}



#pragma mark - Managing the Projects directory


static NSString *const PROJECTS_DIRECTORY_NAME = @"projects";
static NSURL * _projectsDirectory = nil;

- (nullable NSURL *)projectsDirectory
{
	return _projectsDirectory ? _projectsDirectory : [self getProjectsDirectory:YES];
}

- (nullable NSURL *)getProjectsDirectory
{
	return [self getProjectsDirectory:YES];
}

- (nullable NSURL *)getProjectsDirectory:(BOOL)createIfNeed
{
	return [self getProjectsDirectory:YES error:nil];
}

- (nullable NSURL *)getProjectsDirectory:(BOOL)createIfNeed error:(NSError **)error
{
	if(_projectsDirectory != nil)
		return _projectsDirectory;
	
	NSURL *root = [StorageManager applicationDocumentsDirectory];
	NSURL *path = [root URLByAppendingPathComponent:PROJECTS_DIRECTORY_NAME isDirectory:YES];

	if([path checkResourceIsReachableAndReturnError:nil])
		return path;
	NSLog(@"creating dir");

	[[NSFileManager defaultManager] createDirectoryAtPath:path.path withIntermediateDirectories:YES attributes:nil error:error];

	if(error != nil)
	{
		NSLog(@"Projects directory ERROR: %@", *error);
		return nil;
	}
	
	_projectsDirectory = path;
	return path;
}


#pragma mark - Managing the Projects directory content


- (nullable NSMutableArray<ProjectModel *> *)getProjects
{
	return [self getProjectsIn:[self projectsDirectory]];
}

- (nullable NSMutableArray<ProjectModel *> *)getProjectsIn:(NSURL *)directory
{
	NSArray<NSString *> *filenames = [self getListingOf:directory];
	NSMutableArray<ProjectModel *> *list = [NSMutableArray<ProjectModel *> arrayWithCapacity:filenames.count];

	for(NSString *filename in filenames)
	{
		ProjectModel *item = [[ProjectModel alloc] initWithFileName:filename inDirectory:directory];
		[list addObject:item];
	}

	return list;
}


#pragma mark - creating / deleting files


- (BOOL)createFileIsPossible:(NSURL *)uri
{
	return ![[NSFileManager defaultManager] fileExistsAtPath:[uri path]];
}

- (void)createFile:(NSURL *)uri
{
	return [self createFile:uri withData:nil];
}

- (void)createFile:(NSURL *)uri withData:(nullable NSString *)data
{
	return [self createFile:uri withData:data error:nil];
}

- (void)createFile:(NSURL *)uri withData:(nullable NSString *)data error:(NSError **)error
{
	[[NSFileManager defaultManager] createFileAtPath:uri.path contents:nil attributes:nil];
	[data writeToURL:uri atomically:YES encoding:NSUTF8StringEncoding error:error];
	// return (error == nil && *error == nil);
}

- (void)writeFile:(NSURL *)uri data:(nonnull NSString *)data error:(NSError **)error
{
	[data writeToURL:uri atomically:YES encoding:NSUTF8StringEncoding error:error];
}


- (void)deleteFile:(NSURL *)uri
{
	return [self deleteFile:uri error:nil];
}

- (void)deleteFile:(NSURL *)uri error:(NSError **)error
{
	if([[NSFileManager defaultManager] fileExistsAtPath:[uri path]])
		[[NSFileManager defaultManager] removeItemAtPath:[uri path] error:error];

	if(error != nil)
		NSLog(@"remove file ERROR: %@", *error);
}


- (nonnull NSURL *)getProjectFileURI:(NSString *)fullname
{
	return [[self projectsDirectory] URLByAppendingPathComponent:fullname];
}


- (void)createProjectFile:(ProjectModel *)model
{
	return [self createProjectFile:model withData:nil];
}

- (void)createProjectFile:(ProjectModel *)model withData:(nullable NSString *)data
{
	return [self createProjectFile:model withData:data error:nil];
}

- (void)createProjectFile:(ProjectModel *)model withData:(nullable NSString *)data error:(NSError **)error
{
	return [self createFile:[model filepath] withData:data error:error];
}

- (void)deleteProjectFile:(ProjectModel *)model
{
	return [self deleteProjectFile:model error:nil];
}

- (void)deleteProjectFile:(ProjectModel *)model error:(NSError **)error
{
	return [self deleteFile:[model filepath] error:error];
}


#pragma mark - loading files


- (nullable NSString *) getFileSource:(nonnull NSURL *)uri error:(NSError **)error
{
	return [NSString stringWithContentsOfURL:uri encoding:NSUTF8StringEncoding error:error];
}

- (nullable NSString *) getProjectSource:(nonnull ProjectModel *)model error:(NSError **)error
{
	return [self getFileSource:[model filepath] error:error];
}


@end
