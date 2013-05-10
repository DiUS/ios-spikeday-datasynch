#import <UIKit/UIKit.h>

@interface TasksViewController : UITableViewController <UITextFieldDelegate>


@property IBOutlet UITextField *taskTextField;
- (IBAction)recreateDB:(id)sender;

@end
