//  AHAuthorizedLaunchCtl.h
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


@protocol AHLaunchCtlProgress
/**
 *  countdown timer
 *
 *  @param time seconds remaining
 */
-(void)countdown:(NSInteger)time;
/**
 *  status message sent from helper tool
 *
 *  @param message status message
 */
-(void)statusMessage:(NSString*)message;
@end

@interface AHAuthorizedLaunchCtl : NSObject
/**
 *  connection Connection to the helper tool
 */
@property (atomic, strong, readonly) NSXPCConnection * connection;

/**
 *  <#Description#>
 *
 *  @param timeReply <#timeReply description#>
 *
 *  @return <#return value description#>
 */
-(instancetype)initWithTimeReplyBlock:(void (^)(NSInteger time))timeReply;

/**
 *  <#Description#>
 *
 *  @param statusMessage <#statusMessage description#>
 *
 *  @return <#return value description#>
 */
-(instancetype)initWithStatusMessageBlock:(void (^)(NSString *message))statusMessage;

/**
 *  <#Description#>
 */
-(void)connectToHelper;

@end



