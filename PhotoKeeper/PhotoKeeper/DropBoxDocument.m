#import <Dropbox/Dropbox.h>
#import "DropBoxDocument.h"
#import "PTKMetadata.h"
#import "PTKData.h"
#import "UIImageExtras.h"
#import "JSONDecoder.h"
#import "JSONEncoder.h"


#define METADATA_FILENAME   @"photo.metadata"
#define DATA_FILENAME       @"photo.data"

@interface DropBoxDocument ()
@property (nonatomic, strong) PTKData * data;
@property (nonatomic, strong) DBPath *path;
@end

@implementation DropBoxDocument

- (id)initWithPath:(DBPath *)path {
  if (self = [super init]) {
    self.path = path;
    self.data = [[PTKData alloc] init];
    self.metadata = [[PTKMetadata alloc] init];
  }
  return self;
}

- (void)saveDocument {
  DBPath *metaDataPath = [self.path childPath:METADATA_FILENAME];
  DBPath *fullFilePath = [self.path childPath:DATA_FILENAME];
  DBError *error;

  JSONEncoder *encoder = [[JSONEncoder alloc] init];
  [encoder encodeObject:self.metadata];
  NSData *metadataData = [encoder jsonAsData];
  DBFile *metadataFile = [[DBFilesystem sharedFilesystem] openFile:metaDataPath error:&error];
  if(!metadataFile) {
    metadataFile = [[DBFilesystem sharedFilesystem] createFile:metaDataPath error:&error];
  }
  [metadataFile writeData:metadataData error:&error];

  JSONEncoder *dataEncoder = [[JSONEncoder alloc] init];
  [dataEncoder encodeObject:self.data];
  NSData *dataData = [dataEncoder jsonAsData];
  DBFile *dataFile = [[DBFilesystem sharedFilesystem] openFile:fullFilePath error:&error];
  if(!dataFile) {
    dataFile = [[DBFilesystem sharedFilesystem] createFile:fullFilePath error:&error];
  }
  [dataFile writeData:dataData error:&error];
}

- (void)loadDocument { // TODO: add completion handler
  DBPath *metaDataPath = [self.path childPath:METADATA_FILENAME];
  DBPath *fullFilePath = [self.path childPath:DATA_FILENAME];
  DBFile *metadataFile = [[DBFilesystem sharedFilesystem] openFile:metaDataPath error:nil];
  DBFile *fullFile = [[DBFilesystem sharedFilesystem] openFile:fullFilePath error:nil];
  DBError *error;

  if(metadataFile)
    self.metadata = [JSONDecoder decodeWithData:[metadataFile readData:&error]];
  if(fullFile)
    self.data = [JSONDecoder decodeWithData:[fullFile readData:&error]];
}

- (UIImage *)photo {
  return self.data.photo;
}

- (void)setPhoto:(UIImage *)photo {

  if ([self.data.photo isEqual:photo]) return;

//  UIImage * oldPhoto = self.data.photo;
  self.data.photo = photo;
  self.metadata.thumbnail = [self.data.photo imageByScalingAndCroppingForSize:CGSizeMake(145, 145)];

}

- (NSString *)description {
  return self.path.stringValue;
}

@end
