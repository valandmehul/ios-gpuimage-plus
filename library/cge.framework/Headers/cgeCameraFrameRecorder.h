/*
 * cgeCameraFrameRecorder.h
 *
 *  Created on: 2015-8-31
 *      Author: Wang Yang
 *        Mail: admin@wysaid.org
 */

#ifndef __cge__cgeCameraFrameRecorder__
#define __cge__cgeCameraFrameRecorder__

#import <Foundation/Foundation.h>
#import "cgeCameraDevice.h"
#import "cgeFrameRecorder.h"

@interface CGECameraFrameRecorder : CGEFrameRecorder<CGECameraDeviceOutputDelegate>

@property(nonatomic, weak, setter=setProcessingDelegate:) id<CGEFrameProcessingDelegate> processingDelegate;

@property CGECameraDevice* cameraDevice;

@property(nonatomic) float maskAspectRatio;

#pragma mark - 初始化相关

- (id)initWithContext :(CGESharedGLContext*)sharedContext;

// 手动调用释放
- (void)clear;

#pragma mark - 相机相关接口

- (BOOL)setupCamera; //默认后置摄像头
- (BOOL)setupCamera :(NSString*)sessionPreset cameraPosition:(AVCaptureDevicePosition)cameraPosition isFrontCameraMirrored:(BOOL)isFrontCameraMirrored authorizationFailed:(void (^)(void))authorizationFailed;
- (BOOL)switchCamera :(BOOL)isFrontCameraMirrored; //注意， 调用此处 switchCamera 会自动判断如果为前置摄像头，则左右反向(镜像)

- (BOOL)focusPoint: (CGPoint)point; //对焦

#pragma mark - 拍照相关接口

- (void)setPictureHighResolution:(BOOL)useHightResolution;

- (void)takePicture :(void (^)(UIImage*))block filterConfig:(const char*)config filterIntensity:(float)intensity isFrontCameraMirrored:(BOOL)mirrored;

#pragma mark - 其他接口

- (void)setGlobalFilter :(const char*)config;
- (void)setGlobalFilterIntensity :(float)intensity;
- (BOOL)hasGlobalFilter;
- (float)globalFilterIntensity;


@end


#endif /* defined(__cge__cgeFrameRecorder__) */
