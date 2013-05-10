//#import "AFIncrementalStore.h"
//#import "AFRestClient.h"

//@interface ToDoAPIClient : AFRESTClient <AFIncrementalStoreHTTPClient>
@interface ToDoAPIClient : NSObject

+ (ToDoAPIClient *)sharedClient;

@end
