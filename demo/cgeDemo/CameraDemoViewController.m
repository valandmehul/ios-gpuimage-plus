//
//  CameraDemoViewController.m
//  cgeDemo
//
//  Created by WangYang on 15/8/31.
//  Copyright (c) 2015年 wysaid. All rights reserved.
//

#import "CameraDemoViewController.h"
#import "cgeUtilFunctions.h"
#import "cgeVideoCameraViewHandler.h"
#import "demoUtils.h"
#import "cgeCustomFilters.h"

#define SHOW_FULLSCREEN 0
#define RECORD_WIDTH 480
#define RECORD_HEIGHT 640

#define _MYAVCaptureSessionPreset(w, h) AVCaptureSessionPreset ## w ## x ## h
#define MYAVCaptureSessionPreset(w, h) _MYAVCaptureSessionPreset(w, h)

static const char* const s_functionList[] = {
    "mask", //0
    "Pause", //1
    "Beautify", //2
    "PreCalc", //3
    "TakeShot", //4
    "Torch", //5
    "Resolution", //6
    "CropRec", //7
    "MyFilter0", //8
    "MyFilter1", //9
    "MyFilter2", //10
    "MyFilter3", //11
    "MyFilter4", //12
};

static const int s_functionNum = sizeof(s_functionList) / sizeof(*s_functionList);

@interface CameraDemoViewController() <CGEFrameProcessingDelegate>
@property (weak, nonatomic) IBOutlet UIButton *quitBtn;
@property (weak, nonatomic) IBOutlet UISlider *intensitySlider;
@property CGECameraViewHandler* myCameraViewHandler;
@property (nonatomic) UIScrollView* myScrollView;
@property (nonatomic) GLKView* glkView;
@property (nonatomic) int currentFilterIndex;
@property (nonatomic) NSURL* movieURL;
@end

@implementation CameraDemoViewController
- (IBAction)quitBtnClicked:(id)sender {
    NSLog(@"Camera Demo Quit...");
    [[[_myCameraViewHandler cameraRecorder] cameraDevice] stopCameraCapture];
    [self dismissViewControllerAnimated:true completion:nil];
    //safe clear to avoid memLeaks.
    [_myCameraViewHandler clear];
    _myCameraViewHandler = nil;
    [CGESharedGLContext clearGlobalGLContext];
}
- (IBAction)intensityChanged:(UISlider*)sender {
    float currentIntensity = [sender value] * 3.0f - 1.0f; //[-1, 2]
    [_myCameraViewHandler setFilterIntensity: currentIntensity];
}
- (IBAction)switchCameraClicked:(id)sender {
    [_myCameraViewHandler switchCamera :YES]; //Pass YES to mirror the front camera.

    CMVideoDimensions dim = [[[_myCameraViewHandler cameraDevice] inputCamera] activeFormat].highResolutionStillImageDimensions;
    NSLog(@"Max Photo Resolution: %d, %d\n", dim.width, dim.height);
}

- (IBAction)takePicture:(id)sender {
    [_myCameraViewHandler takePicture:^(UIImage* image){
        [DemoUtils saveImage:image];
        NSLog(@"Take Picture OK, Saved To The Album!\n");
        
    } filterConfig:g_effectConfig[_currentFilterIndex] filterIntensity:1.0f isFrontCameraMirrored:YES];
}

- (IBAction)recordingBtnClicked:(UIButton*)sender {
    
    [sender setEnabled:NO];
    
    if([_myCameraViewHandler isRecording])
    {
        void (^finishBlock)(void) = ^{
            NSLog(@"End recording...\n");
            
            [CGESharedGLContext mainASyncProcessingQueue:^{
                [sender setTitle:@"Rec OK" forState:UIControlStateNormal];
                [sender setEnabled:YES];
            }];
            
            [DemoUtils saveVideo:_movieURL];
            
        };
        
//        [_myCameraViewHandler endRecording:nil];
//        finishBlock();
        [_myCameraViewHandler endRecording:finishBlock withCompressionLevel:2];
    }
    else
    {
        unlink([_movieURL.path UTF8String]);
        [_myCameraViewHandler startRecording:_movieURL size:CGSizeMake(RECORD_WIDTH, RECORD_HEIGHT)];
        [sender setTitle:@"Recording" forState:UIControlStateNormal];
        [sender setEnabled:YES];
    }
}

- (IBAction)switchFlashLight:(id)sender {
    static AVCaptureFlashMode flashLightList[] = {
        AVCaptureFlashModeOff,
        AVCaptureFlashModeOn,
        AVCaptureFlashModeAuto
    };
    static int flashLightIndex = 0;
    
    ++flashLightIndex;
    flashLightIndex %= sizeof(flashLightList) / sizeof(*flashLightList);
    
    [_myCameraViewHandler setCameraFlashMode:flashLightList[flashLightIndex]];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _movieURL = [NSURL fileURLWithPath:[NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie.mp4"]];
    
    CGRect rt = [[UIScreen mainScreen] bounds];
    
    CGRect sliderRT = [_intensitySlider bounds];
    sliderRT.size.width = rt.size.width - 20;
    [_intensitySlider setBounds:sliderRT];
    
#if SHOW_FULLSCREEN
    
    _glkView = [[GLKView alloc] initWithFrame:rt];
    
#else
    
    CGFloat x, y, w = RECORD_WIDTH, h = RECORD_HEIGHT;
    
    CGFloat scaling = MIN(rt.size.width / (float)w, rt.size.height / (float)h);
    
    w *= scaling;
    h *= scaling;
    
    x = (rt.size.width - w) / 2.0;
    y = (rt.size.height - h) / 2.0;
    
    _glkView = [[GLKView alloc] initWithFrame: CGRectMake(x, y, w, h)];
    
#endif

    _myCameraViewHandler = [[CGECameraViewHandler alloc] initWithGLKView:_glkView];

    if([_myCameraViewHandler setupCamera: MYAVCaptureSessionPreset(RECORD_HEIGHT, RECORD_WIDTH) cameraPosition:AVCaptureDevicePositionFront isFrontCameraMirrored:YES authorizationFailed:^{
        NSLog(@"Not allowed to open camera and microphone, please choose allow in the 'settings' page!!!");
    }])
    {
        [[_myCameraViewHandler cameraDevice] startCameraCapture];
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"The Camera Is Not Allowed!"
                                                       delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
    
    [self.view insertSubview:_glkView belowSubview:_quitBtn];
    
    CGRect scrollRT = rt;
    scrollRT.origin.y = scrollRT.size.height - 60;
    scrollRT.size.height = 50;
    _myScrollView = [[UIScrollView alloc] initWithFrame:scrollRT];
    
    CGRect frame = CGRectMake(0, 0, 95, 50);
    
    for(int i = 0; i != s_functionNum; ++i)
    {
        MyButton* btn = [[MyButton alloc] initWithFrame:frame];
        [btn setTitle:[NSString stringWithUTF8String:s_functionList[i]] forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
        [btn.layer setBorderColor:[UIColor redColor].CGColor];
        [btn.layer setBorderWidth:2.0f];
        [btn.layer setCornerRadius:11.0f];
        [btn setIndex:i];
        [btn addTarget:self action:@selector(functionButtonClick:) forControlEvents:UIControlEventTouchUpInside];
        [_myScrollView addSubview:btn];
        frame.origin.x += frame.size.width;
    }
    
    frame.size.width = 70;
    
    for(int i = 0; i != g_configNum; ++i)
    {
        MyButton* btn = [[MyButton alloc] initWithFrame:frame];
        
        if(i == 0)
            [btn setTitle:@"Origin" forState:UIControlStateNormal];
        else
            [btn setTitle:[NSString stringWithFormat:@"filter%d", i] forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        [btn.layer setBorderColor:[UIColor blueColor].CGColor];
        [btn.layer setBorderWidth:1.5f];
        [btn.layer setCornerRadius:10.0f];
        [btn setIndex:i];
        [btn addTarget:self action:@selector(filterButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        [_myScrollView addSubview:btn];
        frame.origin.x += frame.size.width;
    }
    
    _myScrollView.contentSize = CGSizeMake(frame.origin.x, 50);
    
    [self.view addSubview:_myScrollView];
    
    [CGESharedGLContext globalSyncProcessingQueue:^{
        [CGESharedGLContext useGlobalGLContext];
        void cgePrintGLInfo();
        cgePrintGLInfo();
    }];
    
    [_myCameraViewHandler fitViewSizeKeepRatio:YES];

    //Set to the max resolution for taking photos.
    [[_myCameraViewHandler cameraRecorder] setPictureHighResolution:YES];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    NSLog(@"view appear.");
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    NSLog(@"view disappear.");
}

- (void)filterButtonClicked: (MyButton*)sender
{
    _currentFilterIndex = [sender index];
    NSLog(@"Filter %d Clicked...\n", _currentFilterIndex);
    
    const char* config = g_effectConfig[_currentFilterIndex];
    [_myCameraViewHandler setFilterWithConfig:config];
}

- (void)setMask
{
    CGRect rt = [[UIScreen mainScreen] bounds];
    
    CGFloat x, y, w = RECORD_WIDTH, h = RECORD_HEIGHT;
    
    if([_myCameraViewHandler isUsingMask])
    {
        [_myCameraViewHandler setMaskUIImage:nil];
    }
    else
    {
        UIImage* img = [UIImage imageNamed:@"mask1.png"];
        w = img.size.width;
        h = img.size.height;
        [_myCameraViewHandler setMaskUIImage:img];        
    }
    
    float scaling = MIN(rt.size.width / (float)w, rt.size.height / (float)h);
    
    w *= scaling;
    h *= scaling;
    
    x = (rt.size.width - w) / 2.0;
    y = (rt.size.height - h) / 2.0;
    
    [_myCameraViewHandler fitViewSizeKeepRatio:YES];
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.5];
    
#if SHOW_FULLSCREEN
    
    [_glkView setFrame:rt];
    
#else
    
    [_glkView setFrame:CGRectMake(x, y, w, h)];
    
#endif
    
    [UIView commitAnimations];
}

#pragma mark - CGEFrameProcessingDelegate

- (BOOL)bufferRequestRGBA
{
    return NO;
}

// Draw your own content!
// The content would be shown in realtime, and can be recorded to the video.
- (void)drawProcResults:(void *)handler
{
    // unmark below, if you can use cpp. (remember #include "cgeImageHandler.h")
//    using namespace CGE;
//    CGEImageHandler* cppHandler = (CGEImageHandler*)handler;
//    cppHandler->setAsTarget();
    
    static float x = 0;
    static float dx = 10.0f;
    glEnable(GL_SCISSOR_TEST);
    x += dx;
    if(x < 0 || x > 500)
        dx = -dx;
    glScissor(x, 100, 200, 200);
    glClearColor(1, 0.5, 0, 1);
    glClear(GL_COLOR_BUFFER_BIT);
    glDisable(GL_SCISSOR_TEST);
}

//The realtime buffer for processing. Default format is YUV, and you can change the return value of "bufferRequestRGBA" to recieve buffer of format-RGBA.
- (BOOL)processingHandleBuffer:(CVImageBufferRef)imageBuffer
{
    return NO;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [touches enumerateObjectsUsingBlock:^(UITouch* touch, BOOL* stop) {
        CGPoint touchPoint = [touch locationInView:_glkView];
        CGSize sz = [_glkView frame].size;
        CGPoint transPoint = CGPointMake(touchPoint.x / sz.width, touchPoint.y / sz.height);
        
        [_myCameraViewHandler focusPoint:transPoint];
        NSLog(@"touch position: %g, %g, transPoint: %g, %g", touchPoint.x, touchPoint.y, transPoint.x, transPoint.y);
    }];
}

- (void)switchTorchMode
{
    AVCaptureTorchMode mode[3] = {
        AVCaptureTorchModeOff,
        AVCaptureTorchModeOn,
        AVCaptureTorchModeAuto
    };
    
    static int torchModeIndex = 0;
    
    ++torchModeIndex;
    torchModeIndex %= 3;
    
    [_myCameraViewHandler setTorchMode:mode[torchModeIndex]];
}

- (void)switchResolution
{
    NSString* resolutionList[] = {
        AVCaptureSessionPresetPhoto,
        AVCaptureSessionPresetHigh,
        AVCaptureSessionPresetMedium,
        AVCaptureSessionPresetLow,
        AVCaptureSessionPreset352x288,
        AVCaptureSessionPreset640x480,
        AVCaptureSessionPreset1280x720,
        AVCaptureSessionPreset1920x1080,
        AVCaptureSessionPreset3840x2160,
        AVCaptureSessionPresetiFrame960x540,
        AVCaptureSessionPresetiFrame1280x720,
        AVCaptureSessionPresetInputPriority
    };

    static const int listNum = sizeof(resolutionList) / sizeof(*resolutionList);
    static int index = 0;

    if([[_myCameraViewHandler cameraDevice] captureSessionPreset] != resolutionList[index])
    {
        [_myCameraViewHandler setCameraSessionPreset:resolutionList[index]];
    }

    CMVideoDimensions dim = [[[_myCameraViewHandler cameraDevice] inputCamera] activeFormat].highResolutionStillImageDimensions;
    NSLog(@"Preset: %@, max resolution: %d, %d\n", [[_myCameraViewHandler cameraDevice] captureSessionPreset], dim.width, dim.height);

    [[_myCameraViewHandler cameraRecorder] setPictureHighResolution:YES];

    ++index;
    index %= listNum;
}

//This example shows how to record the specified area of your camera view.
- (void)cropRecording: (MyButton*)sender
{
    if([_myCameraViewHandler isRecording])
    {
        void (^finishBlock)(void) = ^{
            NSLog(@"End recording...\n");
            
            [CGESharedGLContext mainASyncProcessingQueue:^{
                [sender setTitle:@"录制完成" forState:UIControlStateNormal];
                [sender setEnabled:YES];
            }];
            
            [DemoUtils saveVideo:_movieURL];
            
        };
        [_myCameraViewHandler endRecording:finishBlock withCompressionLevel:2];
    }
    else
    {
        unlink([_movieURL.path UTF8String]);
        
        CGRect rts[] = {
            CGRectMake(0.25, 0.25, 0.5, 0.5), //Record a quarter of the camera view in the center.
            CGRectMake(0.5, 0.0, 0.5, 1.0), //Record the right (half) side of the camera view.
            CGRectMake(0.0, 0.0, 1.0, 0.5), //Record the up (half) side of the camera view.
        };
        
        CGRect rt = rts[rand() % sizeof(rts) / sizeof(*rts)];
        
        CGSize videoSize = CGSizeMake(RECORD_WIDTH * rt.size.width, RECORD_HEIGHT * rt.size.height);
        
        NSLog(@"Crop area: %g, %g, %g, %g, record resolution: %g, %g", rt.origin.x, rt.origin.y, rt.size.width, rt.size.height, videoSize.width, videoSize.height);
        
        [_myCameraViewHandler startRecording:_movieURL size:videoSize cropArea:rt];
        [sender setTitle:@"Rec stopped" forState:UIControlStateNormal];
        [sender setEnabled:YES];
    }
}

- (void)setCustomFilter:(CustomFilterType)type
{
    void* customFilter = cgeCreateCustomFilter(type, 1.0f, _myCameraViewHandler.cameraRecorder.sharedContext);
    [_myCameraViewHandler.cameraRecorder setFilterWithAddress:customFilter];
}

- (void)functionButtonClick: (MyButton*)sender
{
    NSLog(@"Function Button %d Clicked...\n", [sender index]);
    
    switch ([sender index])
    {
        case 0:
            [self setMask];
            break;
        case 1:
            if([[_myCameraViewHandler cameraDevice] captureIsRunning])
            {
                [[_myCameraViewHandler cameraDevice] stopCameraCapture];
                [sender setTitle:@"Start Cam" forState:UIControlStateNormal];
            }
            else
            {
                [[_myCameraViewHandler cameraDevice] startCameraCapture];
                [sender setTitle:@"Stop Cam" forState:UIControlStateNormal];
            }
            break;
        case 2:
            
            //美颜
            if([_myCameraViewHandler isGlobalFilterEnabled])
            {
                [_myCameraViewHandler enableFaceBeautify:NO];
                [sender setTitle:@"Stopped" forState:UIControlStateNormal];
            }
            else
            {
                [_myCameraViewHandler enableFaceBeautify:YES];
//                [_myCameraViewHandler enableGlobalFilter:"@style halftone 1.2 "];
                [sender setTitle:@"Running" forState:UIControlStateNormal];
            }

            break;
        case 3:
            if([[_myCameraViewHandler cameraRecorder] processingDelegate] == nil)
            {
                [[_myCameraViewHandler cameraRecorder] setProcessingDelegate:self];
                [sender setTitle:@"Processing" forState:UIControlStateNormal];
            }
            else
            {
                [[_myCameraViewHandler cameraRecorder] setProcessingDelegate:nil];
                [sender setTitle:@"Stopped" forState:UIControlStateNormal];
            }
            break;
        case 4:
        {
            [_myCameraViewHandler takeShot:^(UIImage *image) {
                
                if(image != nil)
                {
                    [DemoUtils saveImage:image];
                    NSLog(@"TakeShot OK, saved to the album!!\n");
                }
                else
                {
                    NSLog(@"Take shot failed!!!");
                }
            }];
        }
            break;
            
        case 5:
            [self switchTorchMode];
            break;
        case 6:
            [self switchResolution];
            break;
        case 7:
            [self cropRecording:sender];
            break;
        case 8:
            [self setCustomFilter:CGE_CUSTOM_FILTER_0];
            break;
        case 9:
            [self setCustomFilter:CGE_CUSTOM_FILTER_1];
            break;
        case 10:
            [self setCustomFilter:CGE_CUSTOM_FILTER_2];
            break;
        case 11:
            [self setCustomFilter:CGE_CUSTOM_FILTER_3];
            break;
        case 12:
            [self setCustomFilter:CGE_CUSTOM_FILTER_4];
            break;
        default:
            break;
    }
}

@end
