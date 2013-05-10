#import <UIKit/UIKit.h>

@interface TasksViewController : UITableViewController <UITextFieldDelegate>


@property IBOutlet UITextField *taskTextField;
- (IBAction)recreateDB:(id)sender;
- (IBAction)syncDB:(id)sender;

@end
