//
//  PTKEntry.h
//  PhotoKeeper
//
//  Created by Ray Wenderlich on 4/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PTKMetadata;

@interface PTKEntry : NSObject

@property (strong) NSString * fileURL;
@property (strong) PTKMetadata * metadata;
@property (assign) UIDocumentState state;
@property (strong) NSFileVersion * version;

- (id)initWithFileURL:(NSString *)fileURL metadata:(PTKMetadata *)metadata state:(UIDocumentState)state version:(NSFileVersion *)version;
- (NSString *) description;

@end
