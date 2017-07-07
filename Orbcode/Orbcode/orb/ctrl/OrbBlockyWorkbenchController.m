//
//  OrbBlockyWorkbenchController.m
//  Orbcode
//
//  Created by Alexander Kozlovskij on 03/03/17.
//  Copyright © 2017 FZZR. All rights reserved.
//

#import "OrbBlockyWorkbenchController.h"
#import "OrbInfoViewController.h"
#import "StorageManager.h"
#import "Orbcode-Swift.h"
#import "OrbcodeExecutor.h"
#import <OrbcodeCompiler/OrbcodeCompiler.h>



@interface OrbBlockyWorkbenchController ()
{
}

+ (nullable BKYBlockFactory *)sharedBlockFactory;
+ (void)setSharedBlockFactory:(BKYBlockFactory *)newSharedBlockFactory;
//+ (void)initSharedBlockFactory;

@property (strong, nonatomic, nullable) BKYWorkbenchViewController *workbench;
@property (strong, nonatomic, nullable) BKYToolbox *toolbox;
@property (strong, nonatomic, nullable) ProjectModel *model;

- (void)initToolbox;
- (void)initBlockFactory:(BKYBlockFactory *)factory;

@end


@implementation OrbBlockyWorkbenchController

#pragma mark - static props

static BKYBlockFactory *_sharedBlockFactory = nil;

+ (BKYBlockFactory *)sharedBlockFactory
{
	return _sharedBlockFactory;
}

+ (void)setSharedBlockFactory:(BKYBlockFactory *)newSharedBlockFactory
{
	if(_sharedBlockFactory != newSharedBlockFactory)
		_sharedBlockFactory = newSharedBlockFactory;
}

#pragma mark - initializers

- (nonnull instancetype)init
{
	NSLog(@"INIT OrbBlockyWorkbenchController");
	if(self = [super init])
	{
		[self initWorkbench];
		// if(!_sharedBlockFactory)
		// [OrbBlockyWorkbenchController initSharedBlockFactory];
		[self initBlockFactory:[_workbench blockFactory]];
		[self initToolbox];
	}
	return self;
}

- (nonnull instancetype)initWithViewController:(nonnull UIViewController *)vctrl
{
	if((self = [[OrbBlockyWorkbenchController alloc] init]) && [self workbench] != nil)
	{
		[self attachWorkbenchToViewController:vctrl];
	}
	return self;
}


#pragma mark - local props


@synthesize toolbox;
@synthesize sharedUndoDelegate;
@synthesize sharedRedoDelegate;


#pragma mark - Block engine initializers & configurators


//+ (void)initSharedBlockFactory
//{
//	NSError *error = nil;
//	BKYBlockFactory *factory = [[BKYBlockFactory alloc] init];
//	[factory loadFromDefaultFiles:BKYBlockJSONFileAllDefault];
//
//	// loadBlocksJsonData:
//	[factory loadFromJSONPaths:@[ @"blocks.json" ] bundle:nil error:&error];
//
//	if(error)
//	{
//		NSLog(@"Error loading 'blocks.json' into block factory: %@", error);
//		return;
//	}
//
//	_sharedBlockFactory = factory;
//}


- (void)initBlockFactory:(BKYBlockFactory *)factory
{
	NSError *error = nil;
	[factory loadFromDefaultFiles:BKYBlockJSONFileAllDefault];
	[self initMutatorsWithFactory:factory];
	
	
	// load *.json:
	NSArray<NSString *> *list = @[
								  @"top.json",
								  @"math.json",
								  @"loops.json",
								  @"logic.json",
								  @"branch.json",
								  @"colours.json",
								  @"function.json",
								  @"accessors.json",
								  ];
	[factory loadFromJSONPaths:list bundle:nil error:&error];
	if(error)
	{
		NSLog(@"Error loading jsons into block factory: %@", error);
		return;
	}
	
	_sharedBlockFactory = factory;
}


- (void)initMutatorsWithFactory:(BKYBlockFactory *)factory
{
	// Register mutators:
	[OrbMutatorRegister updateBlockExtensionsInBlockFactory:factory];
	NSLog(@"mutators:: %@", [factory blockExtensions]);
	
	// Register layouts for mutators:
	[OrbMutatorRegister registerLayoutsInBuilder:[_workbench layoutBuilder] andFactory:[_workbench viewFactory]];
	
	// Register listeners for mutators:
	[OrbMutatorRegister registerWorkbenchListenerWithWorkbench:_workbench];
}


- (void)initToolbox
{
	/*
	 // Create a new toolbox with a "Sound" category
	 BKYToolbox *toolbox = [[BKYToolbox alloc] init];
	 // [toolbox addCategoryWithName:@"Empty" color:[UIColor redColor]];
	 BKYToolboxCategory *soundCategory = [toolbox addCategoryWithName:@"Sound" color:[UIColor yellowColor]];

	 // Create a sound block and add it to the "Sound" category
	 NSError *makeBlockError = nil;
	 BKYBlock *soundBlock = [blockFactory makeBlockWithName:@"play_sound" error:&makeBlockError];
	 if (makeBlockError) {
		NSLog(@"Error creating 'play_sound' block: %@", makeBlockError);
		return;
	 }
	 NSError *addBlockError = nil;
	 [soundCategory addBlockTree:soundBlock error:&addBlockError];
	 if (addBlockError) {
		NSLog(@"Error adding soundBlock to category: %@", addBlockError);
		return;
	 }
	 */


	// Load the XML from `toolbox.xml`
	NSError *error = nil;
	NSString *path = [[NSBundle mainBundle] pathForResource:@"toolbox" ofType:@"xml"];
	NSString *src = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
	if(error)
	{
		NSLog(@"Could not load 'toolbox.xml'");
		return;
	}

	// Create a toolbox from the XML, using the blockFactory to create blocks declared in the XML
	BKYToolbox *toolset = [BKYToolbox makeToolboxWithXmlString:src factory:_sharedBlockFactory error:&error];
	if(error)
	{
		NSLog(@"Error creating toolbox from XML: %@", error);
		return;
	}

	[self setToolbox:toolset];
	
	
	// Add custom category:
//	BKYToolboxCategory *mainCat = [toolset addCategoryWithName:@"Main" color:[UIColor grayColor] icon:[UIImage imageNamed:@"settings"]];
	// Set icon for `Main` category:
//	[toolset categories][0].icon = [UIImage imageNamed:@"settings"];

//		_workbench.delegate

	if(!_workbench) return;

	// Load the toolbox into the workbench
	error = nil;
	[_workbench loadToolbox:toolbox error:&error];
	// [_workbench loadToolbox:toolbox blockFactory:_sharedBlockFactory error:&error];
	if(error)
	{
		NSLog(@"Error attaching/building toolbox into the workbench: %@\n Workbench is %@.", error, _workbench);
		return;
	}
}

- (void)initWorkbench
{
	_workbench = [[BKYWorkbenchViewController alloc] initWithStyle:BKYWorkbenchViewControllerStyleDefaultStyle];
	[_workbench setDelegate:self];
//	NSLog(@"::: [_workbench workspaceViewController] delegate..: %@", [[_workbench workspaceViewController] delegate]);
//	[[_workbench workspaceViewController] setDelegate:self];
	
//	[_workbench addCoordinatorWithCoordinator:[[OrbWorkbenchListener alloc] initWithWorkbench:_workbench]];
	
//	[_workbench setToolboxDrawerStaysOpen:YES];
	
	// Enable the BlockStartHat feature:
	[_workbench.engine.config setBool:YES for:BKYDefaultLayoutConfig.BlockStartHat];
	
	// Setup history buttons listening:
	[self initCustomHistoryCtrl];
	
	// TODO: listen any events and call updateAvailabilityHistory(Handler)
//	[[BKYEventManager sharedInstance] addObserver:self forKeyPath:<#(nonnull NSString *)#> options:<#(NSKeyValueObservingOptions)#> context:<#(nullable void *)#>]
//	[[BKYEventManager sharedInstance] addListener:nil];
	
}

- (void)attachWorkbenchToViewController:(nonnull UIViewController *)vctrl
{
	NSLog(@"attach");

	// Add editor to this view controller:
	// ISSUE: dismising any Alert!!!! FUCK!
	// [vctrl addChildViewController:_workbench];
	[vctrl.view addSubview:_workbench.view];
	_workbench.view.frame = vctrl.view.bounds;
	_workbench.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[_workbench didMoveToParentViewController:vctrl];

	// Set styles to editor:
	[_workbench.view setBackgroundColor:[UIColor whiteColor]];
}

- (void)detachWorkbenchFromViewController:(nonnull UIViewController *)vctrl
{
	NSLog(@"DEtach");

	// [_workbench removeFromParentViewController];
	// [_workbench.view removeFromSuperview];
}


#pragma mark - Managing the Project


- (BOOL)openProject:(nonnull ProjectModel *)model
{
	NSLog(@"LOAD: %@", [model filename]);

	NSError *error = nil;
	// load file src:
	NSString *src = [[StorageManager sharedStorageManager] getProjectSource:model error:&error];
	if(error != nil)
		NSLog(@"Error loading project from file: %@", error);

	// NOTE: If the connectionManager is nill => touches will not work.
	// [_workbench loadWorkspace:workspace connectionManager:nil error:&error];
	BOOL success = [[_workbench workspace] loadBlocksFromXMLString:src factory:_sharedBlockFactory error:&error];
	NSLog(@"SUCCESS: %hhd", success);
	
	if(!success || error != nil)
		NSLog(@"error: %@", error);
	else
	{
		_model = model;
	}
	
	[OrbWorkbenchHelper markUndeletableBlocksInWorkbench:_workbench];

	return success;
}


- (BOOL)buildCurrentProject:(NSError *_Nullable *_Nullable)error
{
	// set mode :: BUILD
	
	
	if(_model == nil)
		return NO;
	
	
	@autoreleasepool
	{
		[_workbench unhighlightAllBlocks];
		[OrbWorkbenchHelper resetBlockErrors];
		[OrbWorkbenchHelper resetBlockInfos];
		[OrbWorkbenchHelper markAllBlocksAsValidInWorkbench:_workbench];
		[OrbWorkbenchHelper enableAllBlocksInWorkbench:_workbench];
		
		
		NSError *error = nil;
		NSString *source = [[_workbench workspace] toXMLWithError:&error];
		
		if(error == nil)
		{
			CompilerResult *build = [OrbcodeCompiler build:source];
			BOOL success = [[build errors] count] == 0;
			
			if(success)
			{
				NSLog(@"out represented in str:\n%@", [build output]);
				NSString *output = [build output];
				
				//				output = @"10 A = 3\n20 data 1,2,3\n30 read D\n40 print D\n50 A = A - 1\n60 if A>0 then goto 30";
//				output = @"20 A = 3\n30 data 1,2,3\n40 read D\n50 print D\n60 A = A - 1\n70 if A>0 then goto 40";
//				output = [NSString stringWithFormat:@"%@\n%@\n%@\n%@\n%@\n%@",
//						  @"30 RGB 204,51,204",
//						  @"40 locate 0,0",
//						  @"50 delay 100",
//						  @"60 R = sqrt (xpos*xpos+ypos*ypos)",
//						  @"70 if R < 20 then LEDC 1 else LEDC 2",
//						  @"80 goto 30"];
				
				
				NSString *fname = [[StorageManager sharedStorageManager] getBuildFileName:[_model title]];
				NSURL *uri = [[StorageManager sharedStorageManager] getBuildFileURI:fname];
				NSURL *dir = [[StorageManager sharedStorageManager] buildsDirectory];
				[[StorageManager sharedStorageManager] createFile:uri withData:output];
//				NSLog(@"saved to %@, SRC:\n%@", uri, [[StorageManager sharedStorageManager] getFileSource:uri error:nil]);
//				NSLog(@"fs path rep: %s", [uri fileSystemRepresentation]);
//				NSLog(@"rel path: %@", [uri relativePath]);
//				NSLog(@"path: %@", [uri path]);
//				NSLog(@"abs path: %@", [uri absoluteString]);
				
//				OrbcodeExecutor ->>>
				NSError *errorRKO = nil;
//				RKOrbBasicProgram *prog =
				id prog = [[OrbcodeExecutor sharedExecutor] compile:fname directory:[dir path] error:&errorRKO];
//				[prog setStartLineNumber:20];
				[[OrbcodeExecutor sharedExecutor] setProgram:prog];
				
				if(prog == nil || errorRKO != nil)
				{
					success = NO;
					NSLog(@"Compilation fail: %@", errorRKO);
				}
				else
					NSLog(@"Compilation success: %@", prog);
				
				// notify the Robot Ctrl View from here
				OrbInfoViewController *roboview = [[OrbcodeExecutor sharedExecutor] view];
				[roboview refreshView];
			}
			
			// anyway show validation-results:
			for(NSString *uuid in [build errors])
			{
				NSString *message = [[build errors] objectForKey:uuid];
				[OrbWorkbenchHelper markBlockAsInvalidInWorkbench:_workbench uuid:uuid];
				[OrbWorkbenchHelper addBlockErrorWithUuid:uuid message:message];
			}
			
			for(NSString *uuid in [build ignores])
			{
				[OrbWorkbenchHelper disableBlockAsIgnoredInWorkbench:_workbench uuid:uuid];
				[OrbWorkbenchHelper addBlockInfoWithUuid:uuid message:@"Instruction ignored because its can be used only inside kernel or function."];
			}
			
			for(NSString *cinfo in [build c_infos])
			{
				
			}
			
			for(NSString *cerr in [build c_errors])
			{
				
			}
			
			return success;
		}
		
		return NO;
		
//		NSArray<BKYBlock *> *tops = [[_workbench workspace] topLevelBlocks];
//		// https://realm.io/news/nspredicate-cheatsheet/
//		NSArray<BKYBlock *> *kernels = [tops filteredArrayUsingPredicate:
////										[NSPredicate predicateWithFormat:@"SELF.name contains[cd] %@", @"orb_block_kernel"]];
//		                                [NSPredicate predicateWithFormat:@"name == %@", @"orb_block_kernel"]];
//		
//		NSLog(@"TOPS: %lu  <>  %lu KERNELS FILTERED", (unsigned long)[tops count], (unsigned long)[kernels count]);
//		
////		[OrbCodeGen buildKernels:kernels withError:&error];
//		[OrbCodeGen buildKernelsWithRoots:kernels];
//		
//		[OrbcodeExecutor sharedExecutor];
//		
//		return YES;
	}
}

- (BOOL)runCurrentProject:(NSError *_Nullable *_Nullable)error
{
	[[OrbcodeExecutor sharedExecutor] uploadProgram];
	return [[OrbcodeExecutor sharedExecutor] executeProgram];
}


#pragma mark - history control

- (void)initCustomHistoryCtrl
{
	[[_workbench undoButton] setHidden:YES];
	[[_workbench redoButton] setHidden:YES];
	
	// Setup history buttons listening:
	[[_workbench undoButton] addTarget:self action:@selector(updateAvailabilityHistoryHandler:) forControlEvents:UIControlEventTouchUpInside];
	[[_workbench redoButton] addTarget:self action:@selector(updateAvailabilityHistoryHandler:) forControlEvents:UIControlEventTouchUpInside];
}


- (void)undo:(nullable id)sender
{
	[[_workbench undoButton] sendActionsForControlEvents:UIControlEventTouchUpInside];
}

- (void)redo:(nullable id)sender
{
	[[_workbench redoButton] sendActionsForControlEvents:UIControlEventTouchUpInside];
}


- (void)updateAvailabilityHistory
{
	[self updateAvailabilityUndo:sharedUndoDelegate redo:sharedRedoDelegate];
}

- (void)updateAvailabilityHistoryHandler:(id)sender
{
	[self updateAvailabilityHistory];
}

- (void)updateAvailabilityUndo:(UIBarButtonItem *)undoBtn redo:(UIBarButtonItem *)redoBtn
{
	if(!undoBtn || !redoBtn) return;
	
	[undoBtn setEnabled:[[_workbench undoButton] isEnabled]];
	[redoBtn setEnabled:[[_workbench redoButton] isEnabled]];
//	[undoBtn setEnabled:[[_workbench undoManager] canUndo]];
//	[redoBtn setEnabled:[[_workbench undoManager] canRedo]];
}


#pragma mark - export tools


- (nullable NSString *)getWorkspaceSource
{
	return [[_workbench workspace] toXMLWithError:nil];
}

- (nullable NSString *)getWorkspaceSourceWithError:(NSError **)error
{
	return [[_workbench workspace] toXMLWithError:error];
}


#pragma mark - BKYWorkbenchViewControllerDelegate implementation


BOOL onDidUpdateStatePropagateTouchedBlock = NO;

- (void)workbenchViewController:(BKYWorkbenchViewController *)workbenchViewController didUpdateState:(BKYWorkbenchViewControllerUIState)state
{
	NSLog(@"WB.didUpdateState: %lu", (unsigned long)state);
	[self updateAvailabilityHistory];
	
	if(onDidUpdateStatePropagateTouchedBlock)
	{
		switch(state)
		{
			case BKYWorkbenchViewControllerUIStateDidTapWorkspace:
			{
				// empty space tap
				break;
			}
			case BKYWorkbenchViewControllerUIStateDraggingBlock:
			{
				NSLog(@"TODO: (DraggingBlock) Here show INFO View.");
				break;
			}
			default: break;
		}
	}
}


#pragma mark - ctrl+view compositions & implementations

- (nullable UIView *)view
{
	return [_workbench view];
}

- (BOOL)viewLoaded
{
	return [_workbench isViewLoaded];
}

- (void)getFirstTouchedBlock
{
	onDidUpdateStatePropagateTouchedBlock = YES;
//	[[[[_workbench workspace] allBlocks] objectForKey:@""] position]
//	[[_workbench workspaceViewController] didDT]
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
