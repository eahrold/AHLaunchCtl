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

extern NSString* const kAHLaunchCtlHelperTool;

@interface AHLaunchCtl : NSObject

+ (AHLaunchCtl*)sharedControler;
#pragma mark - Public Methods
/**
 *  Creates a launchd.plist and loads the starts the Job
 *  @param job AHLaunchJob Object, Label and either Program or Program Arguments keys required.
 *  @param domain Cooresponding AHLaunchDomain
 *  @param overwrite YES will automatically overwrite a job with the same label, NO will prompt for confirmation
 *  @param reply A block object to be executed when the request operation finishes. This block has no return value and takes one argument: NSError.
 */
- (void)add:(AHLaunchJob*)job toDomain:(AHLaunchDomain)domain overwrite:(BOOL)overwright reply:(void (^)(NSError* error))reply;

/**
 *  Unloads a launchd job and removes the associated launchd.plist
 *  @param label Name of the running launchctl job.
 *  @param error Populated should an error occur.
 *  @param domain Cooresponding LCLaunchDomain
 *  @param reply A block object to be executed when the request operation finishes. This block has no return value and takes one argument: NSError.
 */
- (void)remove:(NSString*)label fromDomain:(AHLaunchDomain)domain reply:(void (^)(NSError* error))reply;

/**
 *  Starts a launchd job using a launchd.plist
 *  @param label Name of the launchctl file.
 *  @param domain Cooresponding LCLaunchDomain
 *  @param error Populated should an error occur.
 *  @param reply A block object to be executed when the request operation finishes. This block has no return value and takes one argument: NSError.
 */
- (void)start:(NSString*)label inDomain:(AHLaunchDomain)domain reply:(void (^)(NSError* error))reply;

/**
 *  unloads a running launchd job.  Identical to unload:inDomain:error, but exists for to keep with naming conventions.
 *  @param label Name of the running launchctl job.
 *  @param domain Cooresponding LCLaunchDomain
 *  @param reply A block object to be executed when the request operation finishes. This block has no return value and takes one argument: NSError.
 */
- (void)stop:(NSString*)label inDomain:(AHLaunchDomain)domain reply:(void (^)(NSError* error))reply;

/**
 *  Restarts a launchd job.  If it's not running will just start it.
 *  @param label Name of the running launchctl job.
 *  @param domain Cooresponding LCLaunchDomain
 *  @param status A block object to be executed when the status of the request changes. This block has no return value and takes one argument: NSString.
 *  @param reply A block object to be executed when the request operation finishes. This block has no return value and takes one argument: NSError.
 */
- (void)restart:(NSString*)label
       inDomain:(AHLaunchDomain)domain
         status:(void (^)(NSString* message))status
          reply:(void (^)(NSError* error))reply;

/**
 *  Create an authorized session for a specified amount of time.  Calling this allows for multiple jobs that require Elevated Priviledges to
 *  @param seconds NSInterger in seconds that the session should be authorized for;
 *  @param timeExpired A block object to be executed when the authorization timer expires. This block has no return value and takes one argument: BOOL.
 *  @param reply A block object to be executed when the request operation finishes. This block has no return value and takes one argument: NSError.
 */
- (void)authorizeSessionForNumberOfSeconds:(NSInteger)seconds
                             timeRemaining:(void (^)(NSInteger time))timeRemaining
                                     reply:(void (^)(NSError* error))reply;

/**
 *  Deauthorize an authorized session.
 *  @param error A block object to be executed when the request operation finishes. This block has no return value and takes one argument: NSError.
 */
- (void)deAuthorizeSession:(void (^)(NSError* error))reply;

#pragma mark - For Use When No Helper Tool is avaliable;
/**
 *  Write the launchd.plist and load the job into context
 *
 *  @param label Name of the running launchctl job.
 *  @param domain Cooresponding LCLaunchDomain
 *  @param error Populated should an error occur.
 *
 *  @return Returns `YES` on success, or `NO` on failure.
 */
- (BOOL)add:(AHLaunchJob*)job toDomain:(AHLaunchDomain)domain error:(NSError**)error;

/**
 *  Remove launchd.plist and unload the job
 *
 *  @param label Name of the running launchctl job.
 *  @param domain Cooresponding LCLaunchDomain
 *  @param error Populated should an error occur.
 *
 *  @return Returns `YES` on success, or `NO` on failure.
 */
- (BOOL)remove:(NSString*)label fromDomain:(AHLaunchDomain)domain error:(NSError**)error;

/**
 *  Loads launchd job (Only User when not including helper tool)
 *  @param job AHLaunchJob Object, Label and Program keys required.
 *  @param domain Cooresponding LCLaunchDomain
 *
 *  @return Returns `YES` on success, or `NO` on failure.
 */
- (BOOL)load:(AHLaunchJob*)job inDomain:(AHLaunchDomain)domain error:(NSError**)error;

/**
 *  Unloads a launchd job (Only User when not including helper tool)
 *  @param error Populated should an error occur.
 *  @param domain Cooresponding LCLaunchDomain
 *
 *  @return Returns `YES` on success, or `NO` on failure.
 */
- (BOOL)unload:(NSString*)label inDomain:(AHLaunchDomain)domain error:(NSError**)error;

/**
 *  Loads and existing launchd.plist (Only User when not including helper tool)
 *  @param label Name of the launchctl file.
 *  @param domain Cooresponding LCLaunchDomain
 *  @param error Populated should an error occur.
 *
 *  @return Returns `YES` on success, or `NO` on failure.
 */
- (BOOL)start:(NSString*)label inDomain:(AHLaunchDomain)domain error:(NSError**)error;

/**
 *  Stops a running launchd job (Only User when not including helper tool)
 *  @param label Name of the running launchctl job.
 *  @param error Populated should an error occur.
 *  @param domain Cooresponding LCLaunchDomain
 *
 *  @return Returns `YES` on success, or `NO` on failure.
 */
- (BOOL)stop:(NSString*)label inDomain:(AHLaunchDomain)domain error:(NSError**)error;

/**
 *  Restarts a launchd job. (Only User when not including helper tool)
 *  @param label Name of the running launchctl job.
 *  @param domain Cooresponding LCLaunchDomain
 *  @param error Populated should an error occur.
 *
 *  @return Returns `YES` on success, or `NO` on failure.
 */
- (BOOL)restart:(NSString*)label inDomain:(AHLaunchDomain)domain error:(NSError**)error;

#pragma mark - Class Methods
/**
 *  Launch an application at login.
 *  @param app Path to the Application
 *  @param launch YES to launch, NO to stop launching
 *  @param global YES to launch for all users, NO to launch for current user.
 *  @param keepAlive YES to relaunch in the event of a crash or an attempt to quit
 *  @param error Populated should an error occur.
 *
 *  @return Returns `YES` on success, or `NO` on failure.
 */
+ (BOOL)launchAtLogin:(NSString*)app launch:(BOOL)launch global:(BOOL)global keepAlive:(BOOL)keepAlive error:(NSError**)error;

/**
 Schedule a LaunchD Job to run at an interval.
 *  @param label uniquely identifier for launchd.  This should be in the form a a reverse domain
 *  @param program Path to the executable to run
 *  @param interval How often in seconds to run.
 *  @param domain Cooresponding LCLaunchDomain
 *  @param error Populated should an error occur.
 *
 *  @return Returns `YES` on success, or `NO` on failure.
 */
+ (void)scheduleJob:(NSString*)label
            program:(NSString*)program
           interval:(int)seconds
             domain:(AHLaunchDomain)domain
              reply:(void (^)(NSError* error))reply;
/**
 *  Schedule a LaunchD Job to run at an interval.
 *  @param label uniquely identifier for launchd.  This should be in the form a a reverse domain
 *  @param program Path to the executable to run
 *  @param programArguments Array of arguments to pass to the executable.
 *  @param interval How often in seconds to run.
 *  @param domain Cooresponding LCLaunchDomain
 *  @param error Populated should an error occur.
 *
 *  @return Returns `YES` on success, or `NO` on failure.
 */
+ (void)scheduleJob:(NSString*)label
             program:(NSString*)program
    programArguments:(NSArray*)programArguments
            interval:(int)seconds
              domain:(AHLaunchDomain)domain
               reply:(void (^)(NSError* error))reply;

/**
 *  Create a job object based on a launchd.plist file
 *  @param label uniquely identifier for launchd.  This should be in the form a a reverse domain
 *  @param domain Cooresponding LCLaunchDomain
 *
 *  @return an allocated AHLaunchJob with the cooresponding keys
 */
+ (AHLaunchJob*)jobFromFileNamed:(NSString*)label
                        inDomain:(AHLaunchDomain)domain;

/**
 *  Create a job object based on currently running Launchd Job
 *  @param label uniquely identifier for launchd.  This should be in the form a a reverse domain
 *  @param domain Cooresponding LCLaunchDomain
 *
 *  @return an allocated AHLaunchJob with the cooresponding keys
 */
+ (AHLaunchJob*)runningJobWithLabel:(NSString*)label
                           inDomain:(AHLaunchDomain)domain;

/**
 *  List with all Jobs avaliable based of files in the specified domain
 *  @param domain Cooresponding LCLaunchDomain
 *
 *  @return Array of allocated AHLaunchJob with the cooresponding keys
 */
+ (NSArray*)allJobsFromFilesInDomain:(AHLaunchDomain)domain;

/**
 *  List with all currently running jobs in the specified domain
 *  @param domain Cooresponding LCLaunchDomain
 *
 *  @return Array of allocated AHLaunchJob with the cooresponding keys
 */
+ (NSArray*)allRunningJobsInDomain:(AHLaunchDomain)domain;

/**
 *  List of running Jobs based on criteria
 *
 *  @param match  string to match.
 *  @param domain AHLaunchDomain
 *
 *  @return Array of allocated AHLaunchJob with the cooresponding keys
 */
+ (NSArray*)runningJobsMatching:(NSString*)match
                       inDomain:(AHLaunchDomain)domain;

/**
 *  installs a privileged helper tool with the specified label.
 *
 *  @param label  label of the Helper Tool
 *  @param prompt String to include for the authorization prompt
 *  @param error  populated should error occur
 *
 *  @return YES for success NO on failure;
 *  @warning Must be code singed properly, and located in the applications MainBundle/Library/LaunchServices
 */
+ (BOOL)installHelper:(NSString*)label
               prompt:(NSString*)prompt
                error:(NSError**)error;

/**
 *  uninstalls HelperTool with specified label.
 *
 *  @param label  label of the Helper Tool
 *  @param reply A block object to be executed when the request operation finishes.  This block has no return value and takes one argument: NSError.
 */

+ (BOOL)uninstallHelper:(NSString*)label
                  error:(NSError* __autoreleasing*)error;

/**
 *  uninstalls The AHLaunchCtl HelperTool with specified label.
 *
 *  @param reply A block object to be executed when the request operation finishes.  This block has no return value and takes one argument: NSError.
 */
+ (void)uninstallAHLaunchCtlHelper:(void (^)(NSError*))reply;

/**
 *  quit the AHLaunchCtl Helper tool.
 */
+ (void)quitHelper;

#pragma mark - Utility
+ (BOOL)version:(NSString*)versionA isGreaterThanVersion:(NSString*)versionB;
#pragma mark - Domain Error
/**
 *  Convience Method for populating an NSError using message and code.  It also can be used to provide a return value for escaping another method. eg on filure of a previous condition you could do "return [AHLaunchCtl errorWithMessage:@"your message" andCode:1 error:error]" and you'll get escaped out, if method return you're using on has BOOL return and error is alreay an __autoreleasing error pointer
 *
 *  @param message Human readable error message
 *  @param code    error Code
 *  @param error   error pointer
 *
 *  @return YES if error code passed is 0, NO on all other error codes passed into;
 */
+ (BOOL)errorWithMessage:(NSString*)message andCode:(NSInteger)code error:(NSError**)error;

@end
