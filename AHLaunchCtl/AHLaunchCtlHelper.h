//  AHLaunchCtlHelper.h
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
#import "AHLaunchCtl.h"
/**
 *  Exported Object for NSXPC Connection
 */
@protocol AHLaunchCtlHelper

/**
 *  Creates a launchd.plist and loads the starts the Job
 *  @param job AHLaunchJob Object, Label and either Program or Program Arguments
 * keys required.
 *  @param domain Cooresponding AHLaunchDomain
 *  @param overwrite YES will automatically overwrite a job with the same label,
 * NO will prompt for confirmation
 *  @param reply A block object to be executed when the request operation
 * finishes. This block has no return value and takes one argument: NSError.
 */
- (void)addJob:(AHLaunchJob*)job
      toDomain:(AHLaunchDomain)domain
      authData:(NSData*)authData
         reply:(void (^)(NSError* error))reply;

/**
 *  Unloads a launchd job and removes the associated launchd.plist
 *  @param label Name of the running launchctl job.
 *  @param error Populated should an error occur.
 *  @param domain Cooresponding LCLaunchDomain
 *  @param reply A block object to be executed when the request operation
 * finishes. This block has no return value and takes one argument: NSError.
 */
- (void)removeJob:(NSString*)label
       fromDomain:(AHLaunchDomain)domain
         authData:(NSData*)authData
            reply:(void (^)(NSError* error))reply;

/**
 *  Starts a launchd job using a launchd.plist
 *  @param label Name of the launchctl file.
 *  @param domain Cooresponding LCLaunchDomain
 *  @param error Populated should an error occur.
 *  @param reply A block object to be executed when the request operation
 * finishes. This block has no return value and takes one argument: NSError.
 */
- (void)startJob:(NSString*)label
        inDomain:(AHLaunchDomain)domain
        authData:(NSData*)authData
           reply:(void (^)(NSError* error))reply;

/**
 *  unloads a running launchd job.  Identical to unload:inDomain:error, but
 * exists for to keep with naming conventions.
 *  @param label Name of the running launchctl job.
 *  @param domain Cooresponding LCLaunchDomain
 *  @param reply A block object to be executed when the request operation
 * finishes. This block has no return value and takes one argument: NSError.
 */
- (void)stopJob:(NSString*)label
       inDomain:(AHLaunchDomain)domain
       authData:(NSData*)authData
          reply:(void (^)(NSError* error))reply;

/**
 *  Restarts a launchd job.  If it's not running will just start it.
 *  @param label Name of the running launchctl job.
 *  @param domain Cooresponding LCLaunchDomain
 *  @param status A block object to be executed when the status of the request
 * changes. This block has no return value and takes one argument: NSString.
 *  @param reply A block object to be executed when the request operation
 * finishes. This block has no return value and takes one argument: NSError.
 */
- (void)restartJob:(NSString*)label
          inDomain:(AHLaunchDomain)domain
          authData:(NSData*)authData
             reply:(void (^)(NSError* error))reply;

/**
 *  Create an authorized session for a specified amount of time.  Calling this
 * allows for multiple jobs that require Elevated Priviledges to
 *  @param seconds NSInterger in seconds that the session should be authorized
 * for;
 *  @param timeExpired A block object to be executed when the authorization
 * timer expires. This block has no return value and takes one argument: BOOL.
 *  @param reply A block object to be executed when the request operation
 * finishes. This block has no return value and takes one argument: NSError.
 */
- (void)authorizeSessionFor:(NSInteger)seconds
                   authData:(NSData*)authData
                      reply:(void (^)(NSError* error))reply;

/**
 *  Deauthorize an authorized session.
 *  @param error A block object to be executed when the request operation
 * finishes. This block has no return value and takes one argument: NSError.
 */
- (void)deAuthorizeSession:(void (^)(NSError* error))reply;

/**
 *  quit the AHLaunchCtl Helper tool.
 */
- (void)quitHelper;

/**
 *  uninstalls HelperTool with specified label.
 *
 *  @param label  label of the Helper Tool
 *  @param reply A block object to be executed when the request operation
 *finishes.  This block has no return value and takes one argument: NSError.
 */
- (void)uninstallHelper:(NSString*)label
               authData:(NSData*)authData
                  reply:(void (^)(NSError*))reply;
@end

@interface AHLaunchCtlXPCListener : NSObject
- (void)run;
- (instancetype)init;
@end
