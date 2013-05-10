//
//  PTKMasterViewController.m
//  PhotoKeeper
//
//  Created by Ray Wenderlich on 4/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Dropbox/Dropbox.h>
#import "PTKMasterViewController.h"
#import "PTKDetailViewController.h"
#import "PTKDocument.h"
#import "Document.h"
#import "NSDate+FormattedStrings.h"
#import "PTKEntry.h"
#import "PTKMetadata.h"
#import "PTKEntryCell.h"
#import "DropBoxDocument.h"

@interface PTKMasterViewController () {
  NSMutableArray *_objects;
  NSURL *_localRoot;
  id <Document> _selDocument;
  UITextField *_activeTextField;
}

@property(nonatomic, strong) DBAccount *account;

@end

@implementation PTKMasterViewController

#pragma mark Helpers

- (BOOL)iCloudOn {
  return NO;
}

- (NSURL *)localRoot {
  if (_localRoot != nil) {
    return _localRoot;
  }

  NSArray *paths = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
  _localRoot = [paths objectAtIndex:0];
  return _localRoot;
}

- (NSURL *)getDocURL:(NSString *)filename {
  if ([self iCloudOn]) {
    // TODO
    return nil;
  } else {
    return [self.localRoot URLByAppendingPathComponent:filename];
  }
}

- (BOOL)docNameExistsInObjects:(NSString *)docName {
  BOOL nameExists = NO;
  for (PTKEntry *entry in _objects) {
    if ([[entry.fileURL lastPathComponent] isEqualToString:docName]) {
      nameExists = YES;
      break;
    }
  }
  return nameExists;
}

- (NSString *)getDocFilename:(NSString *)prefix uniqueInObjects:(BOOL)uniqueInObjects {
  NSInteger docCount = 0;
  NSString *newDocName = nil;

  // At this point, the document list should be up-to-date.
  BOOL done = NO;
  BOOL first = YES;
  while (!done) {
    if (first) {
      first = NO;
      newDocName = [NSString stringWithFormat:@"%@.%@",
                                              prefix, PTK_EXTENSION];
    } else {
      newDocName = [NSString stringWithFormat:@"%@%d.%@",
                                              prefix, docCount, PTK_EXTENSION];
    }

    // Look for an existing document with the same name. If one is
    // found, increment the docCount value and try again.
    BOOL nameExists;
    if (uniqueInObjects) {
      nameExists = [self docNameExistsInObjects:newDocName];
    } else {
      // TODO
      return nil;
    }
    if (!nameExists) {
      break;
    } else {
      docCount++;
    }

  }

  return newDocName;
}

#pragma mark Entry management methods

- (int)indexOfEntryWithFileURL:(NSString *)fileURL {
  __block int retval = -1;
  [_objects enumerateObjectsUsingBlock:^(PTKEntry *entry, NSUInteger idx, BOOL *stop) {
//      if([entry.fileURL isKindOfClass:[NSURL class]]) {
//        NSLog(@"why?????");
//      }

    if ([entry.fileURL isEqualToString:fileURL]) {
      retval = idx;
      *stop = YES;
    }
  }];
  return retval;
}

- (void)addOrUpdateEntryWithURL:(NSString *)fileURL metadata:(PTKMetadata *)metadata state:(UIDocumentState)state version:(NSFileVersion *)version {

  int index = [self indexOfEntryWithFileURL:fileURL];

  // Not found, so add
  if (index == -1) {

    PTKEntry *entry = [[PTKEntry alloc] initWithFileURL:fileURL metadata:metadata state:state version:version];

    [_objects addObject:entry];
    [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:(_objects.count - 1) inSection:0]] withRowAnimation:UITableViewRowAnimationRight];

  }

          // Found, so edit
  else {

    PTKEntry *entry = [_objects objectAtIndex:index];
    entry.metadata = metadata;
    entry.state = state;
    entry.version = version;

    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationNone];

  }

}

- (BOOL)renameEntry:(PTKEntry *)entry to:(NSString *)filename {

  // Bail if not actually renaming
  if ([entry.description isEqualToString:filename]) {
    return YES;
  }

  // Check if can rename file
  NSString *newDocFilename = [NSString stringWithFormat:@"%@.%@",
                                                        filename, PTK_EXTENSION];
  if ([self docNameExistsInObjects:newDocFilename]) {
    NSString *message = [NSString stringWithFormat:@"\"%@\" is already taken.  Please choose a different name.", filename];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
    [alertView show];
    return NO;
  }

  NSURL *newDocURL = [self getDocURL:newDocFilename];
  NSLog(@"Moving %@ to %@", entry.fileURL, newDocURL);

  // Simple renaming to start
  NSFileManager *fileManager = [[NSFileManager alloc] init];
  NSError *error;
  BOOL success = [fileManager moveItemAtURL:[NSURL URLWithString:entry.fileURL] toURL:newDocURL error:&error];
  if (!success) {
    NSLog(@"Failed to move file: %@", error.localizedDescription);
    return NO;
  }

  // Fix up entry
  entry.fileURL = newDocURL.absoluteString;
  entry.version = [NSFileVersion currentVersionOfItemAtURL:[NSURL URLWithString:entry.fileURL]];
  int index = [self indexOfEntryWithFileURL:entry.fileURL];
  [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationNone];

  return YES;

}

- (void)removeEntryWithURL:(NSString *)fileURL {
  int index = [self indexOfEntryWithFileURL:fileURL];
  [_objects removeObjectAtIndex:index];
  [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationLeft];
}

#pragma mark File management methods

- (void)loadDocAtURL:(NSURL *)fileURL {

  // Open doc so we can read metadata
  PTKDocument *doc = [[PTKDocument alloc] initWithFileURL:fileURL];
  [doc openWithCompletionHandler:^(BOOL success) {

    // Check status
    if (!success) {
      NSLog(@"Failed to open %@", fileURL);
      return;
    }

    // Preload metadata on background thread
    PTKMetadata *metadata = doc.metadata;
    NSURL *fileURL = doc.fileURL;
    UIDocumentState state = doc.documentState;
    NSFileVersion *version = [NSFileVersion currentVersionOfItemAtURL:fileURL];
    NSLog(@"Loaded File URL: %@", [doc.fileURL lastPathComponent]);

    // Close since we're done with it
    [doc closeWithCompletionHandler:^(BOOL success) {

      // Check status
      if (!success) {
        NSLog(@"Failed to close %@", fileURL);
        // Continue anyway...
      }

      // Add to the list of files on main thread
      dispatch_async(dispatch_get_main_queue(), ^{
        [self addOrUpdateEntryWithURL:fileURL.absoluteString metadata:metadata state:state version:version];
      });
    }];
  }];

}

- (void)deleteEntry:(PTKEntry *)entry {

  // Simple delete to start
  NSFileManager *fileManager = [[NSFileManager alloc] init];
  [fileManager removeItemAtURL:[NSURL URLWithString:entry.fileURL] error:nil];

  // Fixup view
  [self removeEntryWithURL:entry.fileURL];

}

#pragma mark Refresh Methods

- (void)loadLocal {

  if (self.account) {
    NSArray *immContents = [[DBFilesystem sharedFilesystem] listFolder:[DBPath root] error:nil];

    if (immContents) {
      for (DBFileInfo *info in immContents) {
        if ([info.path.stringValue hasSuffix:PTK_EXTENSION]) {
          DropBoxDocument *document = [[DropBoxDocument alloc] initWithPath:info.path];
          [document loadDocument];

          // Add to the list of files on main thread
          dispatch_async(dispatch_get_main_queue(), ^{
            [self addOrUpdateEntryWithURL:info.path.stringValue metadata:document.metadata state:nil version:nil];
          });

        }
      }
    }
  } else {
    NSArray *localDocuments = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:self.localRoot includingPropertiesForKeys:nil options:0 error:nil];

    NSLog(@"Found %d local files.", localDocuments.count);
    for (int i = 0; i < localDocuments.count; i++) {

      NSURL *fileURL = [localDocuments objectAtIndex:i];
      if ([[fileURL pathExtension] isEqualToString:PTK_EXTENSION]) {
        NSLog(@"Found local file: %@", fileURL);
        [self loadDocAtURL:fileURL];


      }
    }
  }

  self.navigationItem.rightBarButtonItem.enabled = YES;
}

- (void)refresh {

  [_objects removeAllObjects];
  [self.tableView reloadData];

  if (![self iCloudOn]) {
    [self loadLocal];
  }
}

#pragma mark PTKDetailViewControllerDelegate

- (void)detailViewControllerDidClose:(PTKDetailViewController *)detailViewController {
  [self.navigationController popViewControllerAnimated:YES];
  if (self.account) {
    DropBoxDocument *doc = (DropBoxDocument *) detailViewController.doc;
    [self addOrUpdateEntryWithURL:doc.description metadata:doc.metadata state:nil version:nil];
  } else {
    PTKDocument *doc = (PTKDocument *) detailViewController.doc;
    NSFileVersion *version = [NSFileVersion currentVersionOfItemAtURL:doc.fileURL];
    [self addOrUpdateEntryWithURL:doc.fileURL.absoluteString metadata:doc.metadata state:doc.documentState version:version];
  }
}

#pragma mark Text Views

- (void)keyboardWillShow:(NSNotification *)note {
  // Get the keyboard size
  CGRect keyboardBounds;
  [[note.userInfo valueForKey:UIKeyboardFrameBeginUserInfoKey] getValue:&keyboardBounds];

  // Detect orientation
  UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
  CGRect frame = self.tableView.frame;

  // Start animation
  [UIView beginAnimations:nil context:NULL];
  [UIView setAnimationBeginsFromCurrentState:YES];
  [UIView setAnimationDuration:0.3f];

  // Reduce size of the Table view
  if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
    frame.size.height -= keyboardBounds.size.height;
  else
    frame.size.height -= keyboardBounds.size.width;

  // Apply new size of table view
  self.tableView.frame = frame;

  // Scroll the table view to see the TextField just above the keyboard
  if (_activeTextField) {
    CGRect textFieldRect = [self.tableView convertRect:_activeTextField.superview.bounds fromView:_activeTextField.superview];
    [self.tableView scrollRectToVisible:textFieldRect animated:NO];
  }

  [UIView commitAnimations];
}

- (void)keyboardWillHide:(NSNotification *)note {
  // Get the keyboard size
  CGRect keyboardBounds;
  [[note.userInfo valueForKey:UIKeyboardFrameBeginUserInfoKey] getValue:&keyboardBounds];

  // Detect orientation
  UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
  CGRect frame = self.tableView.frame;

  [UIView beginAnimations:nil context:NULL];
  [UIView setAnimationBeginsFromCurrentState:YES];
  [UIView setAnimationDuration:0.3f];

  // Reduce size of the Table view
  if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
    frame.size.height += keyboardBounds.size.height;
  else
    frame.size.height += keyboardBounds.size.width;

  // Apply new size of table view
  self.tableView.frame = frame;

  [UIView commitAnimations];
}

- (IBAction)textFieldDidBeginEditing:(UITextField *)textField {
  _activeTextField = textField;
}

- (IBAction)textFieldDidEndEditing:(UITextField *)textField {
  _activeTextField = nil;
}

- (void)textChanged:(UITextField *)textField {
  UIView *view = textField.superview;
  while (![view isKindOfClass:[PTKEntryCell class]]) {
    view = view.superview;
  }
  PTKEntryCell *cell = (PTKEntryCell *) view;
  NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
  PTKEntry *entry = [_objects objectAtIndex:indexPath.row];
  NSLog(@"Want to rename %@ to %@", entry.description, textField.text);
  [self renameEntry:entry to:textField.text];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  [textField resignFirstResponder];
  [self textChanged:textField];
  return YES;
}


#pragma mark View lifecycle

- (void)awakeFromNib {
  [super awakeFromNib];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view, typically from a nib.
  self.account = [DBAccountManager sharedManager].linkedAccount;

//  [DBAccountManager sharedManager]
  if (self.account) {
    DBFilesystem *filesystem = [[DBFilesystem alloc] initWithAccount:self.account];
    [DBFilesystem setSharedFilesystem:filesystem];
  }


  self.navigationItem.leftBarButtonItem = self.editButtonItem;

  UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject:)];
  self.navigationItem.rightBarButtonItem = addButton;

  UIBarButtonItem *settingsButton = [[UIBarButtonItem alloc] initWithTitle:@"Link to DropBox"
                                                                     style:UIBarButtonItemStyleBordered target:self action:@selector(linkDropBox:)];
  [self setToolbarItems:@[settingsButton] animated:NO];

  _objects = [[NSMutableArray alloc] init];
  [self refresh];

  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];


}

- (void)linkDropBox:(id)linkDropBox {
  [[DBAccountManager sharedManager] linkFromController:self];
}

- (void)viewDidUnload {
  [super viewDidUnload];
  // Release any retained subviews of the main view.

  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)insertNewObject:(id)sender {
  // Determine a unique filename to create
  NSURL *fileURL = [self getDocURL:[self getDocFilename:@"Photo" uniqueInObjects:YES]];
  NSLog(@"Want to create file at %@", fileURL);

  if (self.account) {
    [self createDropBoxDocument];

  } else {

    // Create new document and save to the filename
    PTKDocument *doc = [[PTKDocument alloc] initWithFileURL:fileURL];
    [doc saveToURL:fileURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {

      if (!success) {
        NSLog(@"Failed to create file at %@", fileURL);
        return;
      }

      NSLog(@"File created at %@", fileURL);
      PTKMetadata *metadata = doc.metadata;
      NSURL *fileURL = doc.fileURL;
      UIDocumentState state = doc.documentState;
      NSFileVersion *version = [NSFileVersion currentVersionOfItemAtURL:fileURL];

      // Add on the main thread and perform the segue
      _selDocument = doc;
      dispatch_async(dispatch_get_main_queue(), ^{
        [self addOrUpdateEntryWithURL:fileURL.absoluteString metadata:metadata state:state version:version];
        [self performSegueWithIdentifier:@"showDetail" sender:self];
      });

    }];
  }
}

- (void)createDropBoxDocument {
  NSString *fileName = [self getDocFilename:@"Photo" uniqueInObjects:YES];
  DBPath *path = [[DBPath root] childPath:fileName];
  DropBoxDocument *newDoc = [[DropBoxDocument alloc] initWithPath:path];
  _selDocument = newDoc;

  dispatch_async(dispatch_get_main_queue(), ^{
    [self addOrUpdateEntryWithURL:newDoc.description metadata:newDoc.metadata state:nil version:nil];
    [self performSegueWithIdentifier:@"showDetail" sender:self];
  });
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return _objects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  PTKEntryCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];

  PTKEntry *entry = [_objects objectAtIndex:indexPath.row];

  cell.titleTextField.text = entry.description;
  cell.titleTextField.delegate = self;
  if (entry.metadata && entry.metadata.thumbnail) {
    cell.photoImageView.image = entry.metadata.thumbnail;
  } else {
    cell.photoImageView.image = nil;
  }
  if (entry.version) {
    cell.subtitleLabel.text = [entry.version.modificationDate mediumString];
  } else {
    cell.subtitleLabel.text = @"";
  }

  return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
  // Return NO if you do not want the specified item to be editable.
  return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
  if (editingStyle == UITableViewCellEditingStyleDelete) {
    PTKEntry *entry = [_objects objectAtIndex:indexPath.row];
    [self deleteEntry:entry];
  }
}

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

  PTKEntry *entry = [_objects objectAtIndex:indexPath.row];
  [self.tableView deselectRowAtIndexPath:indexPath animated:YES];

  if (self.account) {
    DBPath *path = [[DBPath root] childPath:entry.fileURL];
    DropBoxDocument *doc = [[DropBoxDocument alloc] initWithPath:path];
    _selDocument = doc;
    [doc loadDocument];
    dispatch_async(dispatch_get_main_queue(), ^{
      [self performSegueWithIdentifier:@"showDetail" sender:self];
    });

  } else {
    PTKDocument *doc = [[PTKDocument alloc] initWithFileURL:[NSURL URLWithString:entry.fileURL]];
    _selDocument = doc;
    [doc openWithCompletionHandler:^(BOOL success) {
      dispatch_async(dispatch_get_main_queue(), ^{
        [self performSegueWithIdentifier:@"showDetail" sender:self];
      });
    }];
  }

}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  if ([[segue identifier] isEqualToString:@"showDetail"]) {
    [[segue destinationViewController] setDelegate:self];
    [[segue destinationViewController] setDoc:_selDocument];
  }
}

@end
