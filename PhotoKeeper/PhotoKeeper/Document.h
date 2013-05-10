//
// Created by Andrew Spinks on 9/05/13.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>

@class PTKMetadata;

@protocol Document <NSObject>

// Data
- (UIImage *)photo;
- (void)setPhoto:(UIImage *)photo;

- (PTKMetadata *) getMetadata;
- (NSString *) description;

@end