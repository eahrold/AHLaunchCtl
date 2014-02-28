#AHLaunchCtl An objective-c Library for building a Cocoa App to manager Launch
Daemons / Launch Agents. It's coded for easy implamentation of an NSXPC Helper
Tool to handel management of LaunchD's  that run in a priviledged context.

###Usage ####Add Job

```objective-c

AHLaunchJob _job = [AHLaunchJob new]; 	job.Label = @"com.eeaapps.echo";
job.ProgramArguments = @[@"/bin/echo",@"hello world"]; 	job.StartInterval = 10;
job.StandardOutPath = @"/tmp/echo-test.txt"; 	job.RunAtLoad = YES;
[[AHLaunchCtl sharedControler]add:job toDomain:kAHGlobalLaunchDaemon
reply:^(NSError \*error) { if(error){ NSLog(@"error:
%@",error.localizedDescription); }else{ NSLog(@"added job"); } 	}]; 	

 ```

####Remove Job

```objective-c

[[AHLaunchCtl sharedControler]remove:@"com.eeaapps.echo"
fromDomain:kAHGlobalLaunchDaemon reply:^(NSError \*error) { if(error){
NSLog(@"error: %@",error.localizedDescription); }else{ NSLog(@"removed job"); }
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

    [AHLaunchCtl installHelper:kAHLaunchCtlHelperTool prompt:@"Install Helper?"
    error:&error]; if(error){ NSLog(@"error: %@",error.localizedDescription);
    
```

####Remove Helper this uses the helper tool to uninstall itself;

```objective-c

    [AHLaunchCtl uninstallHelper:kAHLaunchCtlHelperTool reply:^(NSError \*error)
    { if(error){ NSLog(@"error: %@",error.localizedDescription); }else{
    NSLog(@"Helper And Associated files removed"); } }];

```

####It also comes bundled with an Session Authorizer for the Helper

```objective-c

AHLaunchCtl *controller = [AHLaunchCtl new]; [controller
authorizeSessionForNumberOfSeconds:10 timeRemaining:^(NSInteger time) {
NSLog(@"Time Remaining: %ld",time); } error:^(NSError *error) { NSLog(@"error:
%@",error.localizedDescription); }]; ```

####The helper tool can be implemented in just a few lines of code

```objective-c

#import <Foundation/Foundation.h> #import "AHLaunchCtlHelper.h"

int main(int argc, const char * argv[]) { @autoreleasepool {
AHLaunchCtlXPCListener *helper = [[AHLaunchCtlXPCListener alloc]init]; [helper
run]; } 	return 0; }

```
