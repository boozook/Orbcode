//
//  StorageManager.h
//  Orbcode
//
//  Created by Alexander Kozlovskij on 01/03/17.
//  Copyright © 2017 FZZR. All rights reserved.
//

#import "Models.h"
#import <Foundation/Foundation.h>

@interface StorageManager : NSObject

- (nullable NSURL *)applicationDocumentsDirectory;

- (nullable NSURL *)buildsDirectory;
- (nullable NSURL *)getBuildsDirectory;
- (nullable NSURL *)getBuildsDirectory:(BOOL)createIfNeed;
- (nullable NSURL *)getBuildsDirectory:(BOOL)createIfNeed error:(NSError *_Nullable *_Nullable)error;
- (nonnull NSURL *)getBuildFileURI:(nonnull NSString *)fullname;
- (nonnull NSURL *)getBuildFileURI:(nonnull NSString *)fullname addExt:(BOOL)ext;
- (nonnull NSString *)getBuildFileName:(nonnull NSString *)name;


- (nullable NSURL *)projectsDirectory;
- (nullable NSURL *)getProjectsDirectory;
- (nullable NSURL *)getProjectsDirectory:(BOOL)createIfNeed;
- (nullable NSURL *)getProjectsDirectory:(BOOL)createIfNeed error:(NSError *_Nullable *_Nullable)error;

- (nullable NSArray<NSString *> *)getListingOf:(nonnull NSURL *)directory;

- (nullable NSMutableArray<ProjectModel *> *)getProjects;
- (nullable NSMutableArray<ProjectModel *> *)getProjectsIn:(nonnull NSURL *)directory;


- (BOOL)createFileIsPossible:(NSURL *_Nonnull)uri;

- (void)createFile:(nonnull NSURL *)uri;
- (void)createFile:(nonnull NSURL *)uri withData:(nullable NSString *)data;
- (void)createFile:(nonnull NSURL *)uri withData:(nullable NSString *)data error:(NSError *_Nullable *_Nullable)error;

- (void)writeFile:(nonnull NSURL *)uri data:(nonnull NSString *)data error:(NSError *_Nullable *_Nullable)error;

- (void)deleteFile:(nonnull NSURL *)uri;
- (void)deleteFile:(nonnull NSURL *)uri error:(NSError *_Nullable *_Nullable)error;


- (nonnull NSURL *)getProjectFileURI:(nonnull NSString *)fullname;

- (void)createProjectFile:(nonnull ProjectModel *)model;
- (void)createProjectFile:(nonnull ProjectModel *)model withData:(nullable NSString *)data;
- (void)createProjectFile:(nonnull ProjectModel *)model withData:(nullable NSString *)data error:(NSError *_Nullable *_Nullable)error;

- (void)deleteProjectFile:(nonnull ProjectModel *)model;
- (void)deleteProjectFile:(nonnull ProjectModel *)model error:(NSError *_Nullable *_Nullable)error;


- (nullable NSString *) getFileSource:(nonnull NSURL *)uri error:(NSError *_Nullable *_Nullable)error;
- (nullable NSString *) getProjectSource:(nonnull ProjectModel *)model error:(NSError *_Nullable *_Nullable)error;


+ (nonnull StorageManager *)sharedStorageManager;
+ (nullable NSURL *)applicationDocumentsDirectory;

@end
