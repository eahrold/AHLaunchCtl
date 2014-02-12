#AHLaunchCtl
An objective-c Library for building a Cocoa App to manager Launch Daemons / Launch Agents.
It's coded for easy implamentation of an NSXPC Helper Tool to handel management of LaunchD's 
that run in a priviledged context.

###Usage
####Add Job

```objective-c
	AHLaunchJob _job = [AHLaunchJob new];
	job.Label = @"com.eeaapps.echo";
	job.Program = @"/bin/echo";
	job.ProgramArguments = @[@"hello world"];
	job.StartInterval = 10;
    job.StandardOutPath = @"/tmp/echo-test.txt";
	job.RunAtLoad = YES;
	
	[[AHLaunchCtl sharedControler]add:job toDomain:kAHGlobalLaunchDaemon reply:^(NSError *error) {
        if(error){
            NSLog(@"error: %@",error.localizedDescription);
        }else{
            NSLog(@"added job");
        }
	}];
```

####Remove Job

```objective-c
	[[AHLaunchCtl sharedControler]remove:@"com.eeaapps.echo" fromDomain:kAHGlobalLaunchDaemon reply:^(NSError *error) {
        if(error){
            NSLog(@"error: %@",error.localizedDescription);
        }else{
            NSLog(@"removed job");
        }
    }];
```

####Load Job

```objective-c
```

####Unload Job

```objective-c
```

####Install Helper
This uses the SMJobBless to install a helper tool.

```objective-c
```
####Remove Helper

```objective-c
```

####It also comes bundled with an Session Authorizer

```objective-c
	AHLaunchCtl *controller = [AHLaunchCtl new];
    [controller authorizeSessionFor:10 error:^(NSError *error) {
        NSLog(@"error: %@",error.localizedDescription);
    } timeRemaining:^(NSInteger time) {
        NSLog(@"Time Remaining: %ld",time);
    }];
```


####The helper tool can be implamented in just a few lines of code
```objective-c
#import <Foundation/Foundation.h>
#import "AHLaunchCtlHelper.h"

static const NSTimeInterval kHelperCheckInterval = 1.0; // how often to check whether to quit

int main(int argc, const char * argv[])
{
    AHLaunchCtlXPCListener *helper = [[AHLaunchCtlXPCListener alloc]initConnection];
    
    NSRunLoop * helperLoop = [NSRunLoop currentRunLoop];
    while (!helper.helperToolShouldQuit)
    {
        [helperLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:kHelperCheckInterval]];
    }

    return 0;

}
```