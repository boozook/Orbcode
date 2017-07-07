//
//  OrbEditorViewController.m
//  Orbcode
//
//  Created by Alexander Kozlovskij on 24/02/17.
//  Copyright © 2017 FZZR. All rights reserved.
//

// #import "Models.h"
#import "OrbEditorViewController.h"
#import "StorageManager.h"
#import "OrbcodeExecutor.h"
#import "orb/ctrl/OrbBlockyWorkbenchController.h"
#import <Blockly/Blockly-Swift.h>
#import <Blockly/Blockly.h>


@interface OrbEditorViewController ()

@property (strong, nonatomic) OrbBlockyWorkbenchController *orblocks;
//@property (strong, nonatomic) BKYWorkbenchViewController *workbench OBJC_DEPRECATED("Already in OrbBlocky");
@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;
@property (strong, nonatomic) UIBarButtonItem *undo;
@property (strong, nonatomic) UIBarButtonItem *redo;
@property (strong, nonatomic) UIBarButtonItem *help;
@property (strong, nonatomic) UIBarButtonItem *executeButton;

@property (strong, nonatomic) NSArray<UIBarButtonItem *> *editBarButtonItems;
@property (strong, nonatomic) NSArray<UIBarButtonItem *> *runBarButtonItems;

@end


@implementation OrbEditorViewController

@synthesize orblocks;
@synthesize editBarButtonItems;
@synthesize runBarButtonItems;

- (void)preconfigureView
{
	// Setup view bars:
	if(!self.extendedLayoutIncludesOpaqueBars)
		self.edgesForExtendedLayout = UIRectEdgeNone;

	// self.navigationItem.leftBarButtonItem = self.editButtonItem;
	_help = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"info"]
											 style:UIBarButtonItemStylePlain target:self action:@selector(onSwitchHelpStateRequested:)];
	_undo = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemUndo target:self action:@selector(onUndoRequested:)];
	_redo = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRedo target:self action:@selector(onRedoRequested:)];
	UIBarButtonItem *buildButton = [[UIBarButtonItem alloc] initWithTitle:@"Compile" style:UIBarButtonItemStyleDone
																   target:self action:@selector(onBuildRequested:)];
	_executeButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(onExecuteRequested:)];
	_executeButton.enabled = NO;
	// UIBarButtonItem *shareButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(onActionButton:)];
	
	editBarButtonItems = @[ _executeButton, buildButton, _redo, _undo, _help ];
//	runBarButtonItems = @[ _executeButton, breakButton, _redo, _undo, _help ];
	
	
	self.navigationItem.rightBarButtonItems = @[ _executeButton, buildButton, _redo, _undo, _help ];
	
	
}

- (void)configureView
{
	//	NSLog(@"%@", [NSThread currentThread]);
	if(self.detailItem && self.orblocks && self.orblocks.viewLoaded)
	{
		self.title = [self.detailItem title];
		[[self.orblocks view] setHidden:NO];
		[self setEnabledRightBarButtonItem:YES];
	}
	else
	{
		self.title = @"...";
		self.detailDescriptionLabel.text = @"plz select the project and have fun";
		[[self.orblocks view] setHidden:YES];
		[self setEnabledRightBarButtonItem:NO];
	}
	
	// History btns update:
	if(orblocks)
		[orblocks updateAvailabilityUndo:_undo redo:_redo];
	else
	{
		[_undo setEnabled:NO];
		[_redo setEnabled:NO];
	}
}

- (void)setEnabledRightBarButtonItem:(BOOL)to
{
	NSLog(@"setting Details Right Bar enable to: %hhd", to);

	if(self.navigationItem.rightBarButtonItems)
		for(UIBarButtonItem *item in self.navigationItem.rightBarButtonItems)
		{
			[item setEnabled:to];
		}
	else
		[self.navigationItem.rightBarButtonItem setEnabled:to];
}


- (void)viewDidLoad
{
	NSLog(@"Detail::viewDidLoad");

	[super viewDidLoad];

	// setup orb + blocks:
	orblocks = [[OrbBlockyWorkbenchController alloc] init];
	

	// setup view, bars, tabs:
	[self preconfigureView];
	[orblocks setSharedUndoDelegate:[self undo]];
	[orblocks setSharedRedoDelegate:[self redo]];
	[orblocks updateAvailabilityHistory];
	
	
	[self configureView];

	// load prefered from model:
	[self openCurrentProject];
}


- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}



- (void)onSwitchHelpStateRequested:(id)sender
{
	[[self orblocks] getFirstTouchedBlock];
}


- (void)onUndoRequested:(id)sender
{
	[[self orblocks] undo:sender];
}

- (void)onRedoRequested:(id)sender
{
	[[self orblocks] redo:sender];
}

- (void)onBuildRequested:(id)sender
{
	[self saveCurrentProject];
	NSLog(@"BUILD");
	NSError *error = nil;
	BOOL success = [[self orblocks] buildCurrentProject:&error];
	
	[_executeButton setEnabled:success && [[OrbcodeExecutor sharedExecutor] hasRobot]];

	NSLog(@"BUILD %@", (success ? @"SUCCESS" : @"ERROR"));
}

- (void)onExecuteRequested:(id)sender
{
	NSLog(@"RUN");
	NSError *error = nil;
	BOOL success = [[self orblocks] runCurrentProject:&error];
	NSLog(@"RUN %@", (success ? @"SUCCESS" : @"ERROR"));
}


// #pragma mark - Managing the Blockly


#pragma mark - Managing the Project

- (void)openCurrentProjectAndReconfigureView:(BOOL)shouldReconfigureView
{
	[self openCurrentProject];
	// finally refresh view, bars, etc..
	if(shouldReconfigureView)
		[self configureView];
}

- (void)openCurrentProject
{
	if(!self.detailItem) return;

	NSLog(@"openCurrentProject");
	[[self orblocks] openProject:[self detailItem]];
	[[self orblocks] attachWorkbenchToViewController:self];
}

- (void)saveCurrentProject
{
	if([self detailItem] == nil) return;

	NSLog(@"saveCurrentProject");
	NSError *error = nil;
	NSString *src = [[self orblocks] getWorkspaceSourceWithError:&error];
	if(error)
	{
		NSLog(@"Could not export/serialize project '%@', error: %@", [self.detailItem filename], error);
		return;
	}

	NSLog(@"source: \n%@", src);

	//	NSError *error = nil;
	//	NSString *src = [[_workbench workspace] toXMLWithError:&error];
	//	NSLog(@"workspace: %@ \n\n", src);

	[[StorageManager sharedStorageManager] writeFile:[self.detailItem filepath] data:src error:&error];
	if(error)
	{
		NSLog(@"Could not write project '%@', error: %@", [self.detailItem filename], error);
		return;
	}
}

- (void)closeCurrentProject
{
	NSLog(@"closeCurrentProject...");
	if([self detailItem] == nil) return;
	// if([_workbench workspace] == nil) return;

	NSLog(@"closeCurrentProject");
	[self saveCurrentProject];
}

#pragma mark - spesial things

- (void)prepareForAlertInput
{
	//	[[self orblocks] detachWorkbenchFromViewController:self];
}

- (void)cancelForAlertInput
{
	//	[[self orblocks] attachWorkbenchToViewController:self];
}

#pragma mark - Managing the detail item


- (void)setDetailItem:(ProjectModel *)newDetailItem
{
	NSLog(@"T: %@", [NSThread currentThread]);

	if(_detailItem != nil)
	{
		[self saveCurrentProject];
		[self closeCurrentProject];
	}

	if(_detailItem != newDetailItem)
	{
		_detailItem = newDetailItem;

		if(_detailItem != nil && [self viewIfLoaded] != nil)
			[self openCurrentProjectAndReconfigureView:YES];
	}
}

- (nullable ProjectModel *)getDetailItem
{
	return _detailItem;
}


@end
