/*
 * cgeUtilFunctions.h
 *
 *  Created on: 2015-7-10
 *      Author: Wang Yang
 *        Mail: admin@wysaid.org
 */


// 仅提供与安卓版一致的接口， 如需更佳的使用体验， 可直接调用C++代码！

#import <UIKit/UIKit.h>
#import "cgeSharedGLContext.h"

#ifdef __cplusplus
extern "C" {
#endif
    
    typedef UIImage* (*LoadImageCallback)(const char* name, void* arg);
    typedef void (*LoadImageOKCallback)(UIImage*, void* arg);
    
    void cgeSetLoadImageCallback(LoadImageCallback, LoadImageOKCallback, void* arg);
   
    GLuint cgeGlobalTextureLoadFunc(const char* source, GLint* w, GLint* h, void* arg);
    
    // 注意， 图片格式必须为 GL_RGBA + GL_UNSIGNED_BYTE
    typedef struct CGEFilterImageInfo
    {
        void* data; // char array.
        int width; //图片宽 (真实宽度， 需要将对齐计算在内)
        int height; //图片高 (真实高度， 需要将对齐计算在内)
    }CGEFilterImageInfo;
    
    //图像处理接口 (废弃)
    void cgeFilterImage_MultipleEffects(CGEFilterImageInfo dataIn, CGEFilterImageInfo dataOut, const char* config, float intensity, CGESharedGLContext* processingContext);

    //图像处理接口 (推荐)
    //参数:       uiimage － 输入图像
    //            config  - 附加等滤镜配置
    //         intensity  - 滤镜强度， 范围 [0, 1]
    // processingContext  - 附加的context, 如果为 nil， 将使用 globalContext。 如果需要多线程使用， 请自行创建新的  context.
    UIImage* cgeFilterUIImage_MultipleEffects(UIImage* uiimage, const char* config, float intensity, CGESharedGLContext* processingContext);
    
    //通过配置创建单个滤镜
    void* cgeCreateSingleFilterByConfig(const char* config);

    //通过配置创建多重滤镜
    void* cgeCreateMultipleFilterByConfig(const char* config, float intensity);

    GLuint cgeUIImage2Texture(UIImage* uiimage);

    //width和height将被写入texture的真实宽高 (tips: 后期可能存在UIImage过大时， 纹理将被压缩， 所以只有从这里获得的参数才是准确值)
    GLuint cgeUIImage2TextureWithSize(UIImage* uiimage, GLint* width, GLint* height);
    
    //较快创建Texture的方法， 当imageBuffer为NULL 时将使用malloc创建合适大小的buffer。
    GLuint cgeCGImage2Texture(CGImageRef cgImage, void* imageBuffer);
    
    UIImage* cgeCreateUIImageWithBufferRGBA(void* buffer, size_t width, size_t height, size_t bitsPerComponent, size_t bytesPerRow);
    
    CGAffineTransform cgeGetUIImageOrientationTransform(UIImage* image);
    UIImage* cgeForceUIImageUp(UIImage* image);
    
    /*
     
     cgeGetMachineDescriptionString 返回值对应表 
     (from: http://stackoverflow.com/questions/448162/determine-device-iphone-ipod-touch-with-iphone-sdk )
     
     @"iPhone1,1" => @"iPhone 1G"
     @"iPhone1,2" => @"iPhone 3G"
     @"iPhone2,1" => @"iPhone 3GS"
     @"iPhone3,1" => @"iPhone 4"
     @"iPhone3,3" => @"Verizon iPhone 4"
     @"iPhone4,1" => @"iPhone 4S"
     @"iPhone5,1" => @"iPhone 5 (GSM)"
     @"iPhone5,2" => @"iPhone 5 (GSM+CDMA)"
     @"iPhone5,3" => @"iPhone 5c (GSM)"
     @"iPhone5,4" => @"iPhone 5c (GSM+CDMA)"
     @"iPhone6,1" => @"iPhone 5s (GSM)"
     @"iPhone6,2" => @"iPhone 5s (GSM+CDMA)"
     @"iPhone7,1" => @"iPhone 6 Plus"
     @"iPhone7,2" => @"iPhone 6"
     @"iPod1,1" => @"iPod Touch 1G"
     @"iPod2,1" => @"iPod Touch 2G"
     @"iPod3,1" => @"iPod Touch 3G"
     @"iPod4,1" => @"iPod Touch 4G"
     @"iPod5,1" => @"iPod Touch 5G"
     @"iPad1,1" => @"iPad"
     @"iPad2,1" => @"iPad 2 (WiFi)"
     @"iPad2,2" => @"iPad 2 (GSM)"
     @"iPad2,3" => @"iPad 2 (CDMA)"
     @"iPad2,4" => @"iPad 2 (WiFi)"
     @"iPad2,5" => @"iPad Mini (WiFi)"
     @"iPad2,6" => @"iPad Mini (GSM)"
     @"iPad2,7" => @"iPad Mini (GSM+CDMA)"
     @"iPad3,1" => @"iPad 3 (WiFi)"
     @"iPad3,2" => @"iPad 3 (GSM+CDMA)"
     @"iPad3,3" => @"iPad 3 (GSM)"
     @"iPad3,4" => @"iPad 4 (WiFi)"
     @"iPad3,5" => @"iPad 4 (GSM)"
     @"iPad3,6" => @"iPad 4 (GSM+CDMA)"
     @"iPad4,1" => @"iPad Air (WiFi)"
     @"iPad4,2" => @"iPad Air (Cellular)"
     @"iPad4,4" => @"iPad mini 2G (WiFi)"
     @"iPad4,5" => @"iPad mini 2G (Cellular)"
     
     @"iPad4,7" => @"iPad mini 3 (WiFi)"
     @"iPad4,8" => @"iPad mini 3 (Cellular)"
     @"iPad4,9" => @"iPad mini 3 (China Model)"
     
     @"iPad5,3" => @"iPad Air 2 (WiFi)"
     @"iPad5,4" => @"iPad Air 2 (Cellular)"
     
     @"i386" => @"Simulator"
     @"x86_64" => @"Simulator"
     */
    
    NSString* cgeGetMachineDescriptionString();
    
    typedef enum { CGEDevice_Simulator, CGEDevice_iPod, CGEDevice_iPhone, CGEDevice_iPad } CGEDeviceEnum;
    
    typedef struct
    {
        CGEDeviceEnum model;
        int majorVerion, minorVersion;
    } CGEDeviceDescription;
    
    CGEDeviceDescription cgeGetDeviceDescription();
    
#ifdef __cplusplus
}
#endif