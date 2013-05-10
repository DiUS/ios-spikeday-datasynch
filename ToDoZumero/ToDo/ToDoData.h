#import <Zumero/Zumero.h>
@class Task;

@interface ToDoData : NSObject

- (void) initialiseStore;
- (NSArray *) retrieveTasks;
- (void) insertTask:(Task *) task;
- (void) updateTask:(Task *) task;

@end
