//  AHAuthorizer.h
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

@interface AHAuthorizer : NSObject
/**
 *  reply A block object to be excuted every second for the duration of the
 * timer. This block has no return value and takes one argument: NSInteger.
 */
//@property (copy) void(^timeRemainingReply)(NSInteger timeRemaining);

/**
 *  Authorization timer Singleton
 *
 *  @return Allocated AHAuthorizer object
 */
+ (AHAuthorizer*)timer;

/**
 *  Authorize a Session
 *
 *  @param time          Number of seconds to authorize session for
 *  @param timeRemaining A block object to be excuted every second for the
 *duration of the  timer. This block has no return value and takes one argument:
 *NSInteger
 */
- (void)countDownFrom:(NSInteger)time
        timeRemaining:(void (^)(NSInteger))timeRemaining;

/**
 *  Stop authorization timer
 */
- (void)stopTimer;

/**
 *  create and external form for authorizing helper tool
 *
 *  @return NSData representation of external form
 */
+ (NSData*)authorizeHelper;

/**
 *  Used by the helpertool to check the authorization data against the command
 *dictionary
 *
 *  @param authData authorization data
 *  @param command  the selector requested by the main app
 *
 *  @return Populated NSError object on failure.
 */
+ (NSError*)checkAuthorization:(NSData*)authData command:(SEL)command;

/**
 *  Prompt for authorization to the System Daemon
 *
 *  @param prompt string to include in the prompt dialog
 *
 *  @return AuthorizationRef
 */
+ (AuthorizationRef)authorizeSystemDaemonWithPrompt:(NSString*)prompt;

/**
 *  Prompt for authorization to the Service Management system
 *
 *  @param prompt string to include in the prompt dialog
 *
 *  @return AuthorizationRef
 */
+ (AuthorizationRef)authorizeSMJobBlessWithPrompt:(NSString*)prompt;

/**
 *  Free the AuthorizationRef object
 *
 *  @param authRef the AuthorizationRef to be freed
 */
+ (void)authoriztionFree:(AuthorizationRef)authRef;

@end
