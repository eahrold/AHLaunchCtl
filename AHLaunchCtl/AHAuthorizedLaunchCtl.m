//  AHAuthorizedLaunchCtl.m
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

#import "AHAuthorizedLaunchCtl.h"
#import "AHLaunchCtlHelper.h"

#pragma mark Authorized LaunchCtl
@interface AHAuthorizedLaunchCtl () <AHLaunchCtlProgress>
@property (atomic, strong, readwrite) NSXPCConnection* connection;
@property (copy) void (^timerReply)(NSInteger time);
@property (copy) void (^statusMessage)(NSString* message);
@end

@implementation AHAuthorizedLaunchCtl

- (instancetype)initWithTimeReplyBlock:(void (^)(NSInteger time))timeReply
{
    self = [super init];
    if (self) {
        self->_timerReply = timeReply;
    }
    return self;
}

- (instancetype)initWithStatusMessageBlock:(void (^)(NSString*))statusMessage
{
    self = [super init];
    if (self) {
        self->_statusMessage = statusMessage;
    }
    return self;
}

- (void)connectToHelper
{
    assert([NSThread isMainThread]);
    if (self.connection == nil) {
        self.connection = [[NSXPCConnection alloc]
            initWithMachServiceName:kAHLaunchCtlHelperTool
                            options:NSXPCConnectionPrivileged];

        self.connection.remoteObjectInterface =
            [NSXPCInterface interfaceWithProtocol:@protocol(AHLaunchCtlHelper)];

        self.connection.exportedInterface =
            [NSXPCInterface interfaceWithProtocol:@protocol(AHLaunchCtlProgress)];

        self.connection.invalidationHandler = ^{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"
        self.connection.invalidationHandler = nil;
        [[NSOperationQueue mainQueue]
            addOperationWithBlock:^{ self.connection = nil; }];
        #pragma clang diagnostic pop
        };
        self.connection.exportedObject = self;

        [self.connection resume];
    }
}

#pragma mark - AHLaunchCtlProgress
- (void)countdown:(NSInteger)time
{
    self.timerReply(time);
    if (time <= 0) {
        [self.connection invalidate];
    }
}

- (void)statusMessage:(NSString*)message
{
    assert(message != nil);
    self.statusMessage(message);
}

@end
