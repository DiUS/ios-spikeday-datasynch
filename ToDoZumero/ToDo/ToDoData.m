
#import "ToDoData.h"
#import "Task.h"

@implementation ToDoData

NSString * const hostname = @"https://zinstb7d2536d793.s.zumero.net";
NSString * const databaseName = @"mydatabase";

- (void) initialiseStore{
    // error handling omitted for brevity
    NSError *err = nil;
    ZumeroDB *z = [[ZumeroDB alloc] initWithName:databaseName
                                          folder:nil host:hostname];
    BOOL ok = [z createDB:&err];
    // our columns, including a sync-safe primary key
    NSDictionary *fields = @{
                             @"id": @{ @"type": @"unique",
                                       @"not_null" : [NSNumber numberWithBool:TRUE],
                                       @"primary_key": [NSNumber numberWithBool:TRUE] },
                             @"text": @{ @"type":@"text" },
                             @"completedBy": @{ @"type":@"text" }
                             };
    ok = [z beginTX:&err];
    ok = [z defineTable:@"tasks" fields:fields error:&err];
    ok = [z commitTX:&err];
    // we'll want the value of the generated unique ID
}

- (NSArray *) retrieveTasks{
    ZumeroDB *z = [[ZumeroDB alloc] initWithName:databaseName
                                          folder:nil host:hostname];
    NSArray *rows = nil;
    NSArray *err = nil;
    NSMutableArray *tasks = [[NSMutableArray alloc] init];
    [z select:@"tasks" criteria:nil columns:@[@"text", @"completedBy"] orderby:nil rows:&rows error:&err];
    for (NSDictionary *row in rows){
      Task *task = [[Task alloc] init];
      task.completed = [row objectForKey:@"completedAt"];
      task.text = [row objectForKey:@"text"];
      [tasks addObject:task];
    }
    return [[NSArray alloc] initWithArray:tasks];
}

- (void) insertTask:(Task *) task {
    ZumeroDB *z = [[ZumeroDB alloc] initWithName:databaseName
                                          folder:nil host:hostname];
    
    NSMutableDictionary *inserted = [NSMutableDictionary dictionary];
    [inserted setObject:[NSNull null] forKey:@"id"];
    NSDictionary *vals = @{
                           @"text": task.text,
                           @"completedAt": task.completedAt
                           };

    NSError *err = nil;
    BOOL ok = [z beginTX:&err];
    ok = [z insertRecord:@"tasks" values:vals inserted:inserted error:&err];
    NSString *uid = [inserted objectForKey:@"id"];

    ok = [z commitTX:&err];
    task.id = uid;
}

- (void) updateTask:(Task *) task{
    ZumeroDB *z = [[ZumeroDB alloc] initWithName:databaseName
                                        folder:nil host:hostname];

    NSError *err = nil;
    BOOL ok = [z beginTX:&err];
    ok = [z update:@"folks"
          criteria:@{ @"id" : task.id }
          values:@{ @"text" : task.text,
                    @"completedAt" : task.completedAt}
           error:&err];
    ok = [z commitTX:&err];
}

- (void) synchroniseToRemote {
    ZumeroDB *z = [[ZumeroDB alloc] initWithName:databaseName
                                          folder:nil host:hostname];
    NSError *err = nil;
    // no auth scheme, no user, no password
    // (assuming the server is setup to allow this)
    BOOL ok = [z sync:nil user:nil password:nil error:&err];
}

@end
