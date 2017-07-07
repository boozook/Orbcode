//
//  OrbBlockyWorkbenchController.h
//  Orbcode
//
//  Created by Alexander Kozlovskij on 03/03/17.
//  Copyright © 2017 FZZR. All rights reserved.
//

#import "Models.h"
//#import <Blockly/Blockly-Swift.h>
#import <Blockly/Blockly.h>


@interface OrbBlockyWorkbenchController : NSObject<BKYWorkbenchViewControllerDelegate>

//+ (nullable BKYBlockFactory *) sharedBlockFactory;
//+ (nonnull instancetype)controllerWith:(nonnull BKYBlockFactory *)factory;
//+ (nonnull instancetype)controllerWith:(nonnull BKYBlockFactory *)factory toolbox:(nonnull BKYToolbox *)toolbox;


- (nonnull instancetype)initWithViewController:(nonnull UIViewController *)vctrl;
- (void)attachWorkbenchToViewController:(nonnull UIViewController *)vctrl;
- (void)detachWorkbenchFromViewController:(nonnull UIViewController *)vctrl;

- (BOOL)openProject:(nonnull ProjectModel *)model;
- (BOOL)buildCurrentProject:(NSError *_Nullable *_Nullable)error;
- (BOOL)runCurrentProject:(NSError *_Nullable *_Nullable)error;

- (nullable NSString *)getWorkspaceSource;
- (nullable NSString *)getWorkspaceSourceWithError:(NSError *_Nullable *_Nullable)error;

- (nullable UIView *)view;
- (BOOL)viewLoaded;

- (void)getFirstTouchedBlock;


// history //

@property (strong, nonatomic, nullable) UIBarButtonItem *sharedUndoDelegate;
@property (strong, nonatomic, nullable) UIBarButtonItem *sharedRedoDelegate;

- (void)undo:(nullable id)sender;
- (void)redo:(nullable id)sender;
- (void)updateAvailabilityHistory;
- (void)updateAvailabilityUndo:(nullable UIBarButtonItem *)undoBtn redo:(nullable UIBarButtonItem *)redoBtn;

@end
