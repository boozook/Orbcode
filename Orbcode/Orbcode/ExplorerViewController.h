//
//  MasterViewController.h
//  Orbcode
//
//  Created by Alexander Kozlovskij on 24/02/17.
//  Copyright © 2017 FZZR. All rights reserved.
//

#import <UIKit/UIKit.h>


@class OrbEditorViewController;

@interface ExplorerViewController : UITableViewController

@property (strong, nonatomic) OrbEditorViewController *editorViewController;

@end
