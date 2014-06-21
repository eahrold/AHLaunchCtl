//  AHLaunchCtlHelper.m
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

#import "AHLaunchCtlHelper.h"
#import "AHAuthorizedLaunchCtl.h"
#import "AHAuthorizer.h"

static const NSTimeInterval kHelperCheckInterval = 1.0; // how often to check whether to quit

#pragma mark - AHLaunchCtl Extension;
@interface AHLaunchCtl ()
- (BOOL)writeJobToFile:(AHLaunchJob*)job
              inDomain:(AHLaunchDomain)domain
                 error:(NSError**)error;
- (BOOL)removeJobFileWithLabel:(NSString*)label
                        domain:(AHLaunchDomain)domain
                         error:(NSError**)error;
@end

#pragma mark - AHLaunchCtlListener
@interface AHLaunchCtlXPCListener () <NSXPCListenerDelegate, AHLaunchCtlHelper> {
@private
    __weak NSXPCConnection* _timerConnection;
    __weak NSXPCConnection* _statusUpdateConnection;

    __strong AHAuthorizer* _timer;
    BOOL _authorizedForSession;
}

@property (atomic, strong, readwrite) NSXPCListener* listener;
@property (nonatomic, assign) BOOL helperToolShouldQuit;
@property (weak) NSXPCConnection* connection;
@end

@implementation AHLaunchCtlXPCListener

- (instancetype)init
{
    self = [super init];
    if (self) {
        self->_listener =
            [[NSXPCListener alloc] initWithMachServiceName:kAHLaunchCtlHelperTool];
        self->_listener.delegate = self;
    }
    return self;
}

- (void)run
{
    [self.listener resume];
    while (!self.helperToolShouldQuit) {
        [[NSRunLoop currentRunLoop]
            runUntilDate:[NSDate
                             dateWithTimeIntervalSinceNow:kHelperCheckInterval]];
    }
}

#pragma mark - AHLaunchCtlHelper Protocol
- (void)addJob:(AHLaunchJob*)job
      toDomain:(AHLaunchDomain)domain
      authData:(NSData*)authData
         reply:(void (^)(NSError*))reply
{
    NSError* error;
    AHLaunchCtl* controller = [AHLaunchCtl new];
    job = [AHLaunchJob jobFromDictionary:job.dictionary];

    if (!_authorizedForSession)
        error = [AHAuthorizer checkAuthorization:authData command:_cmd];

    if (!error) {
        [controller writeJobToFile:job inDomain:domain error:&error];

        if (domain >= kAHSystemLaunchAgent && !error) {
            [controller load:job inDomain:domain error:&error];
        }
    }
    reply(error);
}

- (void)removeJob:(NSString*)label
       fromDomain:(AHLaunchDomain)domain
         authData:(NSData*)authData
            reply:(void (^)(NSError*))reply
{
    AHLaunchCtl* controller = [AHLaunchCtl new];
    NSError* error;

    if (!_authorizedForSession)
        error = [AHAuthorizer checkAuthorization:authData command:_cmd];

    if (!error) {
        [controller removeJobFileWithLabel:label domain:domain error:&error];

        if (domain >= kAHSystemLaunchAgent) {
            [controller unload:label inDomain:domain error:&error];
        }
    }
    reply(error);
}

- (void)startJob:(NSString*)label
        inDomain:(AHLaunchDomain)domain
        authData:(NSData*)authData
           reply:(void (^)(NSError* error))reply
{
    AHLaunchCtl* controller = [AHLaunchCtl new];
    NSError* error;

    if (!_authorizedForSession)
        error = [AHAuthorizer checkAuthorization:authData command:_cmd];

    if (!error)
        [controller start:label inDomain:domain error:&error];

    reply(error);
}

- (void)stopJob:(NSString*)label
       inDomain:(AHLaunchDomain)domain
       authData:(NSData*)authData
          reply:(void (^)(NSError* error))reply
{
    AHLaunchCtl* controller = [AHLaunchCtl new];
    NSError* error;

    if (!_authorizedForSession)
        error = [AHAuthorizer checkAuthorization:authData command:_cmd];

    if (!error)
        [controller stop:label inDomain:domain error:&error];

    reply(error);
}

- (void)restartJob:(NSString*)label
          inDomain:(AHLaunchDomain)domain
          authData:(NSData*)authData
             reply:(void (^)(NSError* error))reply
{
    AHLaunchCtl* controller = [AHLaunchCtl new];
    NSError* error;

    if (!_authorizedForSession)
        error = [AHAuthorizer checkAuthorization:authData command:_cmd];

    if (!error)
        [controller restart:label inDomain:domain error:&error];

    reply(error);
}

- (void)authorizeSessionFor:(NSInteger)seconds
                   authData:(NSData*)authData
                      reply:(void (^)(NSError* error))reply
{
    NSError* error;
    _authorizedForSession = NO;

    [_timer stopTimer];

    error = [AHAuthorizer checkAuthorization:authData command:_cmd];
    if (error) {
        reply(error);
        return;
    }

    _authorizedForSession = YES;
    _timerConnection = _connection;

    if (!_timer)
        _timer = [[AHAuthorizer alloc] init];

    NSOperationQueue* timerQueue = [NSOperationQueue new];
    [timerQueue addOperationWithBlock:^{
      [_timer countDownFrom:seconds
              timeRemaining:^(NSInteger timer) {
                  [[_timerConnection remoteObjectProxy] countdown:timer];
                  if (timer <= 0) {
                    _authorizedForSession = NO;
                    [_timerConnection invalidate];
                    _timerConnection = nil;
                  }
              }];
    }];
    reply(error);
}

- (void)deAuthorizeSession:(void (^)(NSError*))reply
{
    NSError* error;
    _authorizedForSession = NO;
    if (_timer)
        [_timer stopTimer];

    reply(error);
}

- (void)uninstallHelper:(NSString*)label
               authData:(NSData*)authData
                  reply:(void (^)(NSError*))reply
{
    NSError* error;
    error = [AHAuthorizer checkAuthorization:authData command:_cmd];
    if (!error) {
        reply(error);
        [AHLaunchCtl uninstallHelper:label error:&error];
    }
}

- (void)quitHelper
{
    self.helperToolShouldQuit = YES;
}

#pragma mark NSXPC Delegate
//----------------------------------------
// Set up the one method of NSXPClistener
//----------------------------------------
- (BOOL)listener:(NSXPCListener*)listener
    shouldAcceptNewConnection:(NSXPCConnection*)newConnection
{
    assert(listener == self.listener);

    newConnection.exportedInterface =
        [NSXPCInterface interfaceWithProtocol:@protocol(AHLaunchCtlHelper)];
    newConnection.remoteObjectInterface =
        [NSXPCInterface interfaceWithProtocol:@protocol(AHLaunchCtlProgress)];
    newConnection.exportedObject = self;

    [newConnection resume];

    self.connection = newConnection;
    return YES;
}

@end