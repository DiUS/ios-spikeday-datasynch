
#import <Foundation/Foundation.h>
#import "Document.h"

@class PTKMetadata;
@class DBPath;


@interface DropBoxDocument : NSObject<Document>

- (id)initWithPath:(DBPath *)path;

- (void)saveDocument;

- (void)loadDocument;

// Data
- (UIImage *)photo;
- (void)setPhoto:(UIImage *)photo;

// Metadata
@property (nonatomic, strong) PTKMetadata * metadata;
- (NSString *) description;

@end