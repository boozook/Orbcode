//
//  OrbEditorViewController.h
//  Orbcode
//
//  Created by Alexander Kozlovskij on 24/02/17.
//  Copyright © 2017 FZZR. All rights reserved.
//

#import "Models.h"
#import "orb/ctrl/OrbBlockyWorkbenchController.h"
#import <UIKit/UIKit.h>


@interface OrbEditorViewController : UIViewController

@property (strong, nonatomic) ProjectModel *detailItem;
 
//- (void)openRequestedProject:(ProjectModel *)model;
- (void)closeCurrentProject;

- (void)prepareForAlertInput;
- (void)cancelForAlertInput;

@end
