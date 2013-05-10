

@interface Task : NSObject

@property NSString *text;
@property NSDate *completedAt;
@property NSNumber *id;

@property (nonatomic, getter = isCompleted) BOOL completed;

@end
