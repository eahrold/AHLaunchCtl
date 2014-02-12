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
#import <syslog.h>


#pragma mark Authorized LaunchCtl
@interface AHAuthorizedLaunchCtl()
@property NSInteger authorizedTimeRemaining;
@property (copy) void (^timerReply)(NSInteger time);
@end

@implementation AHAuthorizedLaunchCtl

-(instancetype)initConnection{
    self = [super initWithMachServiceName:kAHLaunchCtlHelperName options:NSXPCConnectionPrivileged];
    if (self) {
        self.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(AHLaunchCtlHelper)];
        self.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(AHLaunchCtlProgress)];
        self.exportedObject = self;
        [self resume];
    }
    return self;
}


#pragma mark Class Methods / Convience Accessors
+(void)addJob:(AHLaunchJob *)job toDomain:(AHlaunchDomain)domain reply:(void (^)(NSError *))reply{
    AHAuthorizedLaunchCtl *connection = [[AHAuthorizedLaunchCtl alloc]initConnection];
    NSData* authData = [ AHAuthorizer authorizeHelper];
    assert(authData != nil);
    
    [[connection remoteObjectProxyWithErrorHandler:^(NSError *error) {
        reply(error);
    }]addJob:job toDomain:domain authData:authData reply:^(NSError *error) {
        reply(error);
        [connection invalidate];
    }];
}

+(void)removeJob:(NSString *)label fromDomain:(AHlaunchDomain)domain reply:(void (^)(NSError *))reply{
    AHAuthorizedLaunchCtl *connection = [[AHAuthorizedLaunchCtl alloc]initConnection];
    NSData* authData = [AHAuthorizer authorizeHelper];
    assert(authData != nil);

    [[connection remoteObjectProxyWithErrorHandler:^(NSError *error) {
        reply(error);
    }]removeJob:label fromDomain:domain authData:authData reply:^(NSError *error) {
        reply(error);
        [connection invalidate];
    }];
}


+(void)authorizeSessionFor:(NSInteger)seconds
                      error:(void (^)(NSError* error))error
               timeRemaining:(void (^)(NSInteger time))timeRemaining

{
    AHAuthorizedLaunchCtl *connection = [[AHAuthorizedLaunchCtl alloc]initConnection];
    NSData* authData = [AHAuthorizer authorizeHelper];
    assert(authData != nil);
    connection.timerReply = timeRemaining;
    
    [[connection remoteObjectProxyWithErrorHandler:^(NSError *connectionError) {
        error(connectionError);
    }]authorizeSessionFor:seconds authData:authData reply:^(NSError *replyError) {
        error(replyError);
    }];
}

+(void)deAuthorizeSession:(void (^)(NSError *))reply{
    AHAuthorizedLaunchCtl *connection = [[AHAuthorizedLaunchCtl alloc]initConnection];
    connection.authorizedTimeRemaining = 0;
    [[connection remoteObjectProxyWithErrorHandler:^(NSError *error) {
        reply(error);
    }]deAuthorizeSession:^(NSError *error) {
        reply(error);
        [connection invalidate];
    }];
}

+(void)quitHelper{
    AHAuthorizedLaunchCtl *connection = [[AHAuthorizedLaunchCtl alloc]initConnection];
    [[connection remoteObjectProxyWithErrorHandler:^(NSError *error) {
        NSLog(@"Error: %@ ",error.debugDescription);
    }]quitHelper];
}

+(void)uninstallHelper:(NSString *)label reply:(void (^)(NSError* error))reply{
    AHAuthorizedLaunchCtl *controller = [[AHAuthorizedLaunchCtl alloc]initConnection];
    NSData* authData = [AHAuthorizer authorizeHelper];
    assert(authData != nil);
    [[controller remoteObjectProxy] uninstallHelper:label authData:authData reply:^(NSError *error) {
        reply(error);
    }];
}

#pragma mark  - AHLaunchCtlProgress
-(void)countdown:(NSInteger)time{
    self.timerReply(time);
    if(time <= 0){
        [self invalidate];
    }
}

@end
