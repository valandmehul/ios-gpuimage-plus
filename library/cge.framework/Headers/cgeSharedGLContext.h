/*
 * cgeSharedGLContext.h
 *
 *  Created on: 2015-7-11
 *      Author: Wang Yang
 *        Mail: admin@wysaid.org
 */

#ifndef cge_cgeInterfaces_h
#define cge_cgeInterfaces_h

#import <Foundation/Foundation.h>
#import <OpenGLES/EAGL.h>
#import "cgeProcessingContext.h"

@interface CGESharedGLContext : CGEProcessingContext

@property(nonatomic,strong) EAGLContext *context;

- (void)makeCurrent;

/////////////////////////////////////////////

+ (instancetype)globalGLContext;

+ (void)useGlobalGLContext;
+ (void)clearGlobalGLContext;

+ (void)globalSyncProcessingQueue:(void (^)(void))block;
+ (void)globalAsyncProcessingQueue:(void (^)(void))block;

+(instancetype)createSharedContext:(CGESharedGLContext*)sharedContext;
+(instancetype)createGlobalSharedContext;


@end

#endif
