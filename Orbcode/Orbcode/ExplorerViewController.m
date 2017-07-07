//
//  MasterViewController.m
//  Orbcode
//
//  Created by Alexander Kozlovskij on 24/02/17.
//  Copyright © 2017 FZZR. All rights reserved.
//

#import "ExplorerViewController.h"
#import "OrbEditorViewController.h"
#import "FilenameUITextFieldValidator.h"
#import "Models.h"
#import "StorageManager.h"

@interface ExplorerViewController ()

@property StorageManager *fs;
@property NSMutableArray<ProjectModel *> *objects;

@end

@implementation ExplorerViewController

#define SEGUE_SHOW_EDITOR @"showProjectEditor"

- (void)viewDidLoad
{
	[super viewDidLoad];

	_fs = [StorageManager sharedStorageManager];

	// Get ProjectViewController:
	self.editorViewController = (OrbEditorViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
	// Set custom edit-button-bar:
	self.navigationItem.leftBarButtonItem = self.editButtonItem;

	// Add "+" button:
	UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(createNewButton:)];
	self.navigationItem.rightBarButtonItem = addButton;

	[self refreshListOfProjects];
}

- (void)refreshListOfProjects
{
	// Get list of projects:
	NSLog(@"projects files: %@", [_fs getListingOf:[_fs projectsDirectory]]);
	NSMutableArray<ProjectModel *> *models = [_fs getProjects];
	NSLog(@"projects models: %@", models);

	// Remove each old:
	for(ProjectModel *item in [self objects])
		[self removeProject:item immediately:YES andFile:NO];

	// Add each to view:
	for(ProjectModel *item in models)
		[self addProject:item immediately:YES andFile:NO];
}


- (void)viewWillAppear:(BOOL)animated
{
	// self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed;
	[super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// TODO: Dispose of any resources that can be recreated.
}

- (nonnull NSString *)getNextProjectName
{
	if(!self.objects)
		self.objects = [[NSMutableArray alloc] init];

	NSString *projname = [NSString stringWithFormat:@"prog_%lu", (unsigned long)([self.objects count] + 1)];
	return projname;
}

- (void)newProjectRequested
{
	[[self editorViewController] prepareForAlertInput];

	@autoreleasepool
	{
		UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"New Project"
		                                                               message:@"type the name of your new neat project here:"
		                                                        preferredStyle:UIAlertControllerStyleAlert];

		UIAlertAction *actCancel = [UIAlertAction actionWithTitle:@"Cancel"
		                                                    style:UIAlertActionStyleCancel
		                                                  handler:^(UIAlertAction *action) {
			                                                  NSLog(@"Cancel");
			                                                  [[self editorViewController] cancelForAlertInput];
			                                              }];

		UIAlertAction *actCreate = [UIAlertAction actionWithTitle:@"Create"
		                                                    style:UIAlertActionStyleDefault
		                                                  handler:^(UIAlertAction *action) {
			                                                  NSString *shortname = [[[alert textFields] firstObject] text];
			                                                  NSString *filename = [NSString stringWithFormat:@"%@.orbcode", shortname];
			                                                  NSURL *uri = [_fs getProjectFileURI:filename];

			                                                  // check:
			                                                  if([_fs createFileIsPossible:uri])
			                                                  {
				                                                  // create Model:
				                                                  ProjectModel *item = [[ProjectModel alloc] initWithTitle:shortname filename:filename filepath:uri];

				                                                  // add the Model:
				                                                  [self addProject:item immediately:NO template:YES];
				                                                  [self selectProjectModelInTableView:item immediately:NO];
			                                                  }
			                                              }];

		FilenameUITextFieldValidator *validator = [FilenameUITextFieldValidator validatorWithExt:@".orbcode" andActor:actCreate];


		[alert addAction:actCancel];
		[alert addAction:actCreate];

		[alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
			textField.placeholder = @"NameOfProject";
			textField.text = [self getNextProjectName];
			[textField setDelegate:validator];
		}];

		[self.splitViewController presentViewController:alert animated:YES completion:nil];
	}
}

- (void)selectProjectModelInTableView:(ProjectModel *)item immediately:(BOOL)immediately
{
	NSUInteger index = [self.objects indexOfObject:item];
	if(index == NSNotFound)
	{
		NSLog(@"Whats a fucking happenning?");
		return;
	}

	// Select new project:
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
	[self.tableView selectRowAtIndexPath:indexPath animated:!immediately scrollPosition:UITableViewScrollPositionMiddle];
	[self performSegueWithIdentifier:SEGUE_SHOW_EDITOR sender:nil];
}

- (void)addProject:(ProjectModel *)item immediately:(BOOL)immediately andFile:(BOOL)fileShouldCreate
{
	if(!self.objects)
		self.objects = [[NSMutableArray alloc] init];

	// add to Model:
	[self.objects insertObject:item atIndex:0];

	// add to View:
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
	[self.tableView insertRowsAtIndexPaths:@[ indexPath ]
	                      withRowAnimation:(immediately ? UITableViewRowAnimationNone : UITableViewRowAnimationAutomatic)];

	// add to FS:
	if(fileShouldCreate)
		[_fs createProjectFile:item];
}

- (void)addProject:(ProjectModel *)item immediately:(BOOL)immediately template:(BOOL)fileShouldCreateFromTemplate
{
	[self addProject:item immediately:immediately andFile:NO];
	// add to FS:
	if(fileShouldCreateFromTemplate)
	{
		// Load the XML from `toolbox.xml`
		NSError *error = nil;
		NSString *path = [[NSBundle mainBundle] pathForResource:@"workspace" ofType:@"xml.mtt"];
		NSString *src = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
		if(error)
		{
			NSLog(@"Could not load 'workspace.xml.mtt', error: %@", error);
			return;
		}

		[_fs createProjectFile:item withData:src error:&error];
		if(error)
		{
			NSLog(@"Could not write project '%@', error: %@", [item filename], error);
			return;
		}
	}
}


- (void)removeProject:(ProjectModel *)item immediately:(BOOL)immediately andFile:(BOOL)fileShouldDelete
{
	if(!self.objects)
		self.objects = [[NSMutableArray alloc] init];

	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[_objects indexOfObject:item] inSection:0];
	return [self removeProject:item forRowAtIndexPath:indexPath immediately:immediately andFile:fileShouldDelete];
}

- (void)removeProject:(ProjectModel *)item forRowAtIndexPath:(NSIndexPath *)indexPath immediately:(BOOL)immediately andFile:(BOOL)fileShouldDelete
{
	if(!self.objects)
		return;

	[self.objects removeObjectAtIndex:indexPath.row];
	[[self tableView] deleteRowsAtIndexPaths:@[ indexPath ]
	                        withRowAnimation:(immediately ? UITableViewRowAnimationNone : UITableViewRowAnimationFade)];

	if([self.objects count] == 0 && [[self tableView] isEditing])
		[self setEditing:NO animated:YES];

	if(fileShouldDelete)
		[_fs deleteProjectFile:item];
}


- (OrbEditorViewController *)getOrbEditorViewController
{
	return (OrbEditorViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
}


#pragma mark - TopBar Buttons


- (void)createNewButton:(id)sender
{
	[self newProjectRequested];
}


#pragma mark - Segues


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if([[segue identifier] isEqualToString:SEGUE_SHOW_EDITOR])
	{
		NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
		ProjectModel *item = self.objects[indexPath.row];

		OrbEditorViewController *controller = (OrbEditorViewController *)[[segue destinationViewController] topViewController];
		[controller setDetailItem:item];
		// [controller openRequestedProject:item];

		// NSLog(@"DTVC next %@", [controller detailItem]);
		// NSLog(@"DTVC prev %@", [[self getOrbEditorViewController] detailItem]);

		// finish, save & close old project:
		[[self getOrbEditorViewController] closeCurrentProject];

		controller.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
		controller.navigationItem.leftItemsSupplementBackButton = YES;
	}
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
	if([identifier isEqualToString:SEGUE_SHOW_EDITOR])
	{
		NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
		ProjectModel *item = self.objects[indexPath.row];
		return ![[[self getOrbEditorViewController] detailItem] isEqual:item];
	}
	return YES;
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return self.objects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ProjectFileCell" forIndexPath:indexPath];

	ProjectModel *item = self.objects[indexPath.row];
	cell.textLabel.text = [item title];
	return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
	return [[self getOrbEditorViewController] detailItem] != [self.objects objectAtIndex:indexPath.row];
	// return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(editingStyle == UITableViewCellEditingStyleDelete)
	{
		ProjectModel *projm = [self.objects objectAtIndex:indexPath.row];
		[self removeProject:projm forRowAtIndexPath:indexPath immediately:NO andFile:YES];
	}
	else if(editingStyle == UITableViewCellEditingStyleInsert)
		// Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
		@throw @"not implmntd.";
}

@end
