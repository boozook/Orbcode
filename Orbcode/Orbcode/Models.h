//
//  models.h
//  Orbcode
//
//  Created by Alexander Kozlovskij on 27/02/17.
//  Copyright © 2017 FZZR. All rights reserved.
//

//#ifndef models_h
//#define models_h

#import <Foundation/Foundation.h>

@interface ProjectModel : NSObject

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *filename;
@property (nonatomic, strong) NSURL *filepath;

- (id)initWithTitle:(NSString *)title filename:(NSString *)filename filepath:(NSURL *)filepath;
- (id)initWithPath:(NSURL *)path;
- (id)initWithFileName:(NSString *)fullname inDirectory:(NSURL *)path;


@end

//#endif /* models_h */
