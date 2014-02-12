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
@class AHLaunchJob;

@protocol AHLaunchCtlHelper

-(void)addJob:(AHLaunchJob*)job toDomain:(AHlaunchDomain)domain authData:(NSData*)authData reply:(void (^)(NSError* error))reply;

-(void)removeJob:(NSString*)label fromDomain:(AHlaunchDomain)domain authData:(NSData*)authData reply:(void (^)(NSError* error))reply;

-(void)authorizeSessionFor:(NSInteger)seconds authData:(NSData *)authData reply:(void (^)(NSError *error))reply;

-(void)deAuthorizeSession:(void (^)(NSError* error))reply;

-(void)quitHelper;
-(void)uninstallHelper:(NSString *)label authData:(NSData *)authData reply:(void (^)(NSError *))reply;
@end

@interface AHLaunchCtlXPCListener : NSXPCListener <NSXPCListenerDelegate,AHLaunchCtlHelper>
@property (weak) NSXPCConnection *connection;
@property (nonatomic, assign) BOOL helperToolShouldQuit;

-(instancetype)initConnection;

@end
