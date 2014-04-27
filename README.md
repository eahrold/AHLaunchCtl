#AHLaunchCtl 
Objective-C library for managing launchd
Daemons / Agents. It's coded for easy implamentation of an NSXPC Helper
Tool to handel management of LaunchD's that run in a priviledged context.

##Usage 
####Add Job

```objective-c
AHLaunchJob* job = [AHLaunchJob new];
job.Program = @"/bin/echo";
job.Label = @"com.eeaapps.echo";
job.ProgramArguments = @[@"hello"];
job.StandardOutPath = @"/tmp/hello.txt";
job.RunAtLoad = YES;
job.StartCalendarInterval = [AHLaunchJobSchedule dailyRunAtHour:2 minute:00];

[[AHLaunchCtl sharedControler] add:job
                          toDomain:kAHUserLaunchAgent
                         overwrite:YES
                             reply:^(NSError *error) {
                                 if(error)
                                    NSLog(@"%@",error);
                                 else
                                 	NSLog(@"Added Job %@",job)
                                   
}];  
```

####Remove Job

```Objective-C
[[AHLaunchCtl sharedControler] remove:@"com.eeaapps.echo"
						   fromDomain:kAHGlobalLaunchDaemon 
                          	    reply:^(NSError *error){
                                	if(error)
                                    	NSLog(@"%@",error);
                                 	else
                                 		NSLog(@"Added Job %@",job)
}]; 	 
```

####Load Job

```objective-c

```

####Unload Job

```objective-c

```

####Install Helper This uses the SMJobBless to install a helper tool.

```objective-c
	NSError *error;
    [AHLaunchCtl installHelper:kAHLaunchCtlHelperTool
    					prompt:@"Install Helper?"
   						 error:&error]; 
    if(error)
    	NSLog(@"error: %@",error);
    
```

####Remove Helper this uses the helper tool to uninstall itself;

```objective-c
[AHLaunchCtl uninstallHelper:kAHLaunchCtlHelperTool
                     reply:^(NSError *error){
                         if(error){
                             NSLog(@"error: %@",error); }
                         else{
                             NSLog(@"Helper And Associated files removed");
                         }
                     }];

```

####It also comes bundled with an Session Authorizer for the Helper

```objective-c
AHLaunchCtl *controller = [AHLaunchCtl new];
[controller authorizeSessionForNumberOfSeconds:10
                                 timeRemaining:^(NSInteger time) {
                                     NSLog(@"Time Remaining: %ld",time);}
                                         reply:^(NSError *error) {
                                             NSLog(@"error:%@",error);
                                         }];
```

####The helper tool can be implemented in just a few lines of code

```objective-c
#import <Foundation/Foundation.h>
#import "AHLaunchCtlHelper.h"

int main(int argc, const char * argv[])
{
    @autoreleasepool {
        AHLaunchCtlXPCListener *helper = [[AHLaunchCtlXPCListener alloc]init];
        [helper run];
    }
	return 0;
}

```
