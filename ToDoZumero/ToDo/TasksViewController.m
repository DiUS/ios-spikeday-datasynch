#import "TasksViewController.h"
#import "ToDoData.h"
#import "Task.h"

@interface TasksViewController()
  @property (nonatomic, strong) ToDoData *dataObject;
  @property (nonatomic, strong) NSArray *toDoData;
@end

@implementation TasksViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    UIRefreshControl *refresh = [[UIRefreshControl alloc] init];
    refresh.attributedTitle = [[NSAttributedString alloc]
          initWithString:@"Pull to Refresh"];
    [refresh addTarget:self action:@selector(refreshView) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refresh;

    self.dataObject = [[ToDoData alloc] init];
    
    self.title = NSLocalizedString(@"ToDo", nil);

    self.toDoData = [self.dataObject retrieveTasks];
    [self.tableView reloadData];

}

- (void) refreshView {
  self.toDoData = [self.dataObject retrieveTasks];
  [self.tableView reloadData];
  [self.refreshControl endRefreshing];
}

- (IBAction)recreateDB:(id)sender {
    [self.dataObject initialiseStore];
}

- (IBAction)syncDB:(id)sender {
    [self.dataObject synchroniseToRemote];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return [self.toDoData count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    [self configureCell:cell forRowAtIndexPath:indexPath];
    
    return cell;
}

- (void)configureCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    Task *task = [self.toDoData objectAtIndex:indexPath.row];
    cell.textLabel.text = task.text;
    cell.textLabel.textColor = [task isCompleted] ? [UIColor lightGrayColor] : [UIColor blackColor];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
//    [self.managedObjectContext performBlock:^{
//        Task *task = [self.fetchedResultsController objectAtIndexPath:indexPath];
//        task.completed = !task.completed;
//        [self.managedObjectContext save:nil];
//    }];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}




#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    NSString *text = [textField.text copy];
    textField.text = nil;
    [textField resignFirstResponder];
    Task *task = [[Task alloc] init];
    task.text = text;
    [self.dataObject insertTask:task];

//    [self.managedObjectContext performBlock:^{
//        NSManagedObject *managedObject = [NSEntityDescription insertNewObjectForEntityForName:@"Task" inManagedObjectContext:self.managedObjectContext];
//        [managedObject setValue:text forKey:@"text"];
//        [self.managedObjectContext save:nil];
//    }];
    
    return YES;
}

@end
