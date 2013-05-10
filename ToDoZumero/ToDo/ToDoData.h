#import <Zumero/Zumero.h>
@class Task;

@interface ToDoData : NSObject <ZumeroDBDelegate>
@property ZumeroDB *z;

- (void) initialiseStore;
- (NSArray *) retrieveTasks;
- (void) insertTask:(Task *) task;
- (void) updateTask:(Task *) task;
- (void) synchroniseToRemote;





@end
