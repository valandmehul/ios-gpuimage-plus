/*
 * cgeProcessingContext.h
 *
 *  Created on: 2015-9-17
 *      Author: Wang Yang
 *        Mail: admin@wysaid.org
 */


#import <Foundation/Foundation.h>

@interface CGEProcessingContext : NSObject


- (void)syncProcessingQueue:(void (^)(void))block;
- (void)asyncProcessingQueue:(void (^)(void))block;
- (dispatch_queue_t)contextQueue;
- (void *)contextKey;

/////////////////////////////////////////////


+ (void)mainSyncProcessingQueue:(void (^)(void))block;
+ (void)mainASyncProcessingQueue:(void (^)(void))block;

@end
