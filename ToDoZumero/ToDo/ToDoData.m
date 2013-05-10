
#import "ToDoData.h"
#import "Task.h"

@implementation ToDoData

NSString * const hostname = @"https://zinstb7d2536d793.s.zumero.net";
NSString * const databaseName = @"mydatabase";


- (id)init {

  if (self = [super init]) {

    self.z = [[ZumeroDB alloc] initWithName:databaseName
                                        folder:nil host:hostname];

    self.z.delegate = self;
  }
  return self;

}

- (void) initialiseStore{
    // error handling omitted for brevity
    NSError *err = nil;


    BOOL ok = [self.z createDB:&err];
    // our columns, including a sync-safe primary key
    NSDictionary *fields = @{
                             @"id": @{ @"type": @"unique",
                                       @"not_null" : [NSNumber numberWithBool:TRUE],
                                       @"primary_key": [NSNumber numberWithBool:TRUE] },
                             @"text": @{ @"type":@"text" },
                             @"completedAt": @{ @"type":@"text" }
                             };
    ok = [self.z beginTX:&err];
    ok = [self.z defineTable:@"tasks" fields:fields error:&err];
    ok = [self.z commitTX:&err];
    // we'll want the value of the generated unique ID
}

- (NSArray *) retrieveTasks{

    NSArray *rows = nil;
    NSArray *err = nil;
    [self.z open:&err];
    NSMutableArray *tasks = [[NSMutableArray alloc] init];
    [self.z select:@"tasks" criteria:nil columns:@[@"text", @"completedBy"] orderby:nil rows:&rows error:&err];
    for (NSDictionary *row in rows){
      Task *task = [[Task alloc] init];
      task.completed = [row objectForKey:@"completedAt"];
      task.text = [row objectForKey:@"text"];
      [tasks addObject:task];
    }
    [self.z close];
    return [[NSArray alloc] initWithArray:tasks];
}

- (void) insertTask:(Task *) task {

    NSMutableDictionary *inserted = [NSMutableDictionary dictionary];
    [inserted setObject:[NSNull null] forKey:@"id"];
    NSDictionary *vals = @{
                           @"text": task.text,
                           @"completedAt": task.completedAt ?: @""
                           };

    NSError *err = nil;
    [self.z open:&err];
    BOOL ok = [self.z beginTX:&err];
    ok = [self.z insertRecord:@"tasks" values:vals inserted:inserted error:&err];
    NSString *uid = [inserted objectForKey:@"id"];

    ok = [self.z commitTX:&err];
    [self.z close];
    task.id = uid;
}

- (void) updateTask:(Task *) task{

    NSError *err = nil;
    [self.z open:&err];
    BOOL ok = [self.z beginTX:&err];
    ok = [self.z update:@"folks"
          criteria:@{ @"id" : task.id }
          values:@{ @"text" : task.text,
                    @"completedAt" : task.completedAt}
           error:&err];
    if (!ok) {
      NSLog(@"Zumero update error - %@", err);
    }
    ok = [self.z commitTX:&err];
    if (!ok) {
      NSLog(@"Zumero commit error - %@", err);
    }
    [self.z close];
}

- (void) synchroniseToRemote {

    NSError *err = nil;
    // no auth scheme, no user, no password
    // (assuming the server is setup to allow this)
    BOOL ok = [self.z sync:@{@"scheme_type": @"internal", @"dbfile" : @"zumero_users_admin"} user:@"admin" password:@"d1uszumero" error:&err];
    if (!ok) {
      NSLog(@"Zumero sync error - %@", err);
    }
}

- (void)syncSuccess:(NSString *)dbname {
  NSLog(@"Success sync for %@", dbname);

}

- (void)syncFail:(NSString *)dbname err:(NSError *)err {
  NSLog(@"Failed syncing for %@ with %@", dbname, err);
}


@end
