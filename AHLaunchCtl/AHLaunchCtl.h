//  AHLaunchCtl.h
//
//  Copyright (c) 2014 Eldon Ahrold ( https://github.com/eahrold/AHLaunchCtl )
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <Foundation/Foundation.h>
#import "AHLaunchJob.h"

extern NSString* const kAHLaunchCtlHelperName;

typedef int AHlaunchDomain;

enum AHLaunchlDomains {
    kAHUserLaunchAgent    = 1001,
    kAHGlobalLaunchAgent  = 2001,
    kAHSystemLaunchAgent,
    kAHGlobalLaunchDaemon = 3001,
    kAHSystemLaunchDaemon,
    kAHSearchDomain       = 4001,
};

@interface AHLaunchCtl : NSObject

+(AHLaunchCtl *)sharedControler;

/**
 Create an authorized session for a specified amount of time.  Calling this allows for multiple jobs that require Elevated Priviledges to
 @param seconds NSInterger in seconds that the session should be authorized for;
 @param error A block object to be executed when the request operation finishes. This block has no return value and takes one argument: NSError.
 @param timeExpired A block object to be executed when the authorization timer expires. This block has no return value and takes one argument: BOOL.
*/
-(void)authorizeSessionFor:(NSInteger)seconds
                     error:(void (^)(NSError *error))error
             timeRemaining:(void (^)(NSInteger time))timeRemaining;

/**
 Deauthorize an authorized session.
 @param error A block object to be executed when the request operation finishes. This block has no return value and takes one argument: NSError.
*/
-(void)deAuthorizeSession:(void (^)(NSError *error))reply;

/**
 Creates a launchd.plist and loads the starts the Job
 @param job AHLaunchJob Object, Label and Program keys required.
 @param domain Cooresponding LCLaunchDomain
 @param reply A block object to be executed when the request operation finishes. This block has no return value and takes one argument: NSError.
 */
-(void)add:(AHLaunchJob*)job toDomain:(AHlaunchDomain)domain reply:(void (^)(NSError* error))reply;

/**
 Unloads a launchd job and removes the associated launchd.plist
 @param label Name of the running launchctl job.
 @param error Populated should an error occur.
 @param domain Cooresponding LCLaunchDomain
 @param reply A block object to be executed when the request operation finishes. This block has no return value and takes one argument: NSError.
 */
-(void)remove:(NSString*)label fromDomain:(AHlaunchDomain)domain reply:(void (^)(NSError* error))reply;

/**
 Creates a launchd.plist and loads the starts the Job
 @param job AHLaunchJob Object, Label and Program keys required.
 @param domain Cooresponding LCLaunchDomain
 @param error Populated should an error occur.
 
 @return Returns `YES` on success, or `NO` on failure.
 */
-(BOOL)add:(AHLaunchJob*)job toDomain:(AHlaunchDomain)domain error:(NSError**)error;

/**
 Removes a launchd job and the associated plist.
 This must be called as root, such as when used with a command line tool or helper.
 For general purposes user remove:fromDomain:reply:
 
 @param job AHLaunchJob Object, Label and Program keys required.
 @param domain Cooresponding LCLaunchDomain
 @param error Populated should an error occur.
 @return Returns `YES` on success, or `NO` on failure.
 */
-(BOOL)remove:(NSString*)label fromDomain:(AHlaunchDomain)domain error:(NSError**)error;

/**
 enables a launchd job (equivelant to launchctl load -w)
 @param job AHLaunchJob Object, Label and Program keys required.
 @param domain Cooresponding LCLaunchDomain

 @return Returns `YES` on success, or `NO` on failure.
 */
-(BOOL)load:(AHLaunchJob*)job inDomain:(AHlaunchDomain)domain error:(NSError**)error;

/**
 disables a launchd job (equivelant to launchctl unload -w)
 @param error Populated should an error occur.
 @param domain Cooresponding LCLaunchDomain
 @return Returns `YES` on success, or `NO` on failure.
 */
-(BOOL)unload:(NSString*)label inDomain:(AHlaunchDomain)domain error:(NSError**)error;

/**
 loads and existing launchd.plist
 @param label Name of the launchctl file.
 @param domain Cooresponding LCLaunchDomain
 @param error Populated should an error occur.
 
 @return Returns `YES` on success, or `NO` on failure.
 */
-(BOOL)start:(NSString*)label inDomain:(AHlaunchDomain)domain error:(NSError**)error;

/**
 unloads a running launchd job
 @param label Name of the running launchctl job.
 @param error Populated should an error occur.
 @param domain Cooresponding LCLaunchDomain
 @return Returns `YES` on success, or `NO` on failure.
 */
-(BOOL)stop:(NSString*)label inDomain:(AHlaunchDomain)domain error:(NSError**)error;

/**
 Restarts a launchd job.  If it's not running will just start it.
 @param label Name of the running launchctl job.
 @param domain Cooresponding LCLaunchDomain
 @param error Populated should an error occur.
 @return Returns `YES` on success, or `NO` on failure.
 */
-(BOOL)restart:(NSString*)label inDomain:(AHlaunchDomain)domain error:(NSError**)error;

#pragma mark - Class Methods
/**
 launch an application at login.  
 @param app Path to the Application
 @param launch YES to launch, NO to stop launching
 @param global YES to launch for all users, NO to launch for current user.
 @param keepAlive YES to relaunch in the event of a crash or an attempt to quit
 @param error Populated should an error occur.

 @return Returns `YES` on success, or `NO` on failure.
 */
+(BOOL)launchAtLogin:(NSString *)app launch:(BOOL)launch global:(BOOL)global keepAlive:(BOOL)keepAlive error:(NSError **)error;

/**
 Schedule a LaunchD Job to run at an interval.
 @param label uniquely identifier for launchd.  This should be in the form a a reverse domain
 @param program Path to the executable to run
 @param interval How often in seconds to run.
 @param domain Cooresponding LCLaunchDomain
 @param error Populated should an error occur.
 
 @return Returns `YES` on success, or `NO` on failure.
 */
+(BOOL)scheduleJob:(NSString*)label program:(NSString*)program interval:(int)seconds domain:(AHlaunchDomain)domain error:(NSError**)error;

/**
 Schedule a LaunchD Job to run at an interval.
 @param label uniquely identifier for launchd.  This should be in the form a a reverse domain
 @param program Path to the executable to run
 @param programArguments Array of arguments to pass to the executable.
 @param interval How often in seconds to run.
 @param domain Cooresponding LCLaunchDomain
 @param error Populated should an error occur.
 
 @return Returns `YES` on success, or `NO` on failure.
 */
+(BOOL)scheduleJob:(NSString*)label program:(NSString*)program programArguments:(NSArray*)programArguments interval:(int)seconds domain:(AHlaunchDomain)domain error:(NSError **)error;

/**
 Unload a LaunchD Job and remove it's associated launchd.plist file.
 @param label uniquely identifier for launchd.  This should be in the form a a reverse domain
 @param domain Cooresponding LCLaunchDomain  WARNING: you can pass NULL and all matching launchd jobs will be removed
 @param error Populated should an error occur.
 
 @return Returns `YES` on success, or `NO` on failure.
 */
+(BOOL)removeJob:(NSString*)label type:(AHlaunchDomain)type error:(NSError**)error;

/**
 Restart a LaunchD Job with matching label
 @param label uniquely identifier for launchd.  This should be in the form a a reverse domain
 @return Returns `YES` on success, or `NO` on failure.
 */
+(BOOL)restartJobWithLabel:(NSString *)label domain:(AHlaunchDomain)domain;
/**
 Restart a LaunchD Job with matching Label, or Program keys
 @param match Label or Program key to match
 @param restartAll Setting NO will cause failure if more than one match is found.  YES to restart all jobs that match.
 @return Returns `YES` on success, or `NO` on failure.
 */
+(BOOL)restartJobMatching:(NSString*)match restartAll:(BOOL)restart;

+(AHLaunchJob*)jobFromFileNamed:(NSString*)label inDomain:(AHlaunchDomain)domain;
+(NSArray*)allJobsFromFilesMatching:(NSString*)match;

+(NSArray*)allRunningJobsMatching:(NSString*)label;
+(NSArray*)runningJobMatching:(NSString*)label inDomain:(AHlaunchDomain)domain;
+(AHLaunchJob*)runningJobWithLabel:(NSString*)label inDomain:(AHlaunchDomain)domain;

+(BOOL)installHelper:(NSString *)label prompt:(NSString*)prompt error:(NSError**)error;
+(void)uninstallHelper:(NSString *)label reply:(void (^)(NSError *))reply;

+(void)quitHelper;
@end
