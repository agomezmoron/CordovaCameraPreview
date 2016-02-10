#import <AssetsLibrary/AssetsLibrary.h>
#import <Cordova/CDV.h>
#import <Cordova/CDVPlugin.h>
#import <Cordova/CDVInvokedUrlCommand.h>

#import "CameraPreview.h"

@implementation CameraPreview

+ (UIDeviceOrientation) fromRotation: (NSInteger) rotation {
    
    switch (rotation){
        case -1: return UIDeviceOrientationUnknown;
        case 0: return UIDeviceOrientationPortrait;
        case 1: return UIDeviceOrientationLandscapeRight;
        case 2: return UIDeviceOrientationPortraitUpsideDown;
        case 3: return UIDeviceOrientationLandscapeLeft;
        default: return UIDeviceOrientationUnknown;
    }
}

- (void) startCamera:(CDVInvokedUrlCommand*)command {
    
    CDVPluginResult *pluginResult;
    
    if (self.sessionManager != nil) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Camera already started!"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        return;
    }
    
    if (command.arguments.count > 3) {
        CGFloat x = (CGFloat)[command.arguments[0] floatValue] + self.webView.frame.origin.x;
        CGFloat y = (CGFloat)[command.arguments[1] floatValue] + self.webView.frame.origin.y;
        CGFloat width = (CGFloat)[command.arguments[2] floatValue];
        CGFloat height = (CGFloat)[command.arguments[3] floatValue];
        NSString *defaultCamera = command.arguments[4];
        BOOL toBack = (BOOL)[command.arguments[5] boolValue];
        self.lockOrientation = [CameraPreview fromRotation: (NSInteger)[command.arguments[6] integerValue]];
        self.filePrefix = command.arguments.count > 8 ? command.arguments[8] : @"picture";
        // Create the session manager
        self.sessionManager = [[CameraSessionManager alloc] init];
        
        //render controller setup
        self.cameraRenderController = [[CameraRenderController alloc] init];
        self.cameraRenderController.sessionManager = self.sessionManager;
        self.cameraRenderController.view.frame = CGRectMake(x, y, width, height);
        self.cameraRenderController.delegate = self;
        
        [self.viewController addChildViewController:self.cameraRenderController];
        //display the camera bellow the webview
        if (toBack) {
            //make transparent
            self.webView.opaque = NO;
            self.webView.backgroundColor = [UIColor clearColor];
            [self.viewController.view insertSubview:self.cameraRenderController.view atIndex:0];
        } else {
            self.cameraRenderController.view.alpha = (CGFloat)[command.arguments[7] floatValue];
            [self.viewController.view addSubview:self.cameraRenderController.view];
        }
        
        // Setup session
        self.sessionManager.delegate = self.cameraRenderController;
        [self.sessionManager setupSession:defaultCamera];
        
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Invalid number of parameters"];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) stopCamera:(CDVInvokedUrlCommand*)command {
    NSLog(@"stopCamera");
    CDVPluginResult *pluginResult;
    
    if(self.sessionManager != nil) {
        [self.cameraRenderController.view removeFromSuperview];
        [self.cameraRenderController removeFromParentViewController];
        self.cameraRenderController = nil;
        
        // Duplicate session stopRunning, also called in CameraRenderController.
        //[self.sessionManager.session stopRunning];
        self.sessionManager = nil;
        
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    }
    else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Camera not started"];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) hideCamera:(CDVInvokedUrlCommand*)command {
    NSLog(@"hideCamera");
    CDVPluginResult *pluginResult;
    
    if (self.cameraRenderController != nil) {
        [self.cameraRenderController.view setHidden:YES];
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Camera not started"];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) showCamera:(CDVInvokedUrlCommand*)command {
    NSLog(@"showCamera");
    CDVPluginResult *pluginResult;
    
    if (self.cameraRenderController != nil) {
        [self.cameraRenderController.view setHidden:NO];
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Camera not started"];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) switchCamera:(CDVInvokedUrlCommand*)command {
    NSLog(@"switchCamera");
    CDVPluginResult *pluginResult;
    
    if (self.sessionManager != nil) {
        [self.sessionManager switchCamera];
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Camera not started"];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) setOnPictureTakenHandler:(CDVInvokedUrlCommand*)command {
    NSLog(@"setOnPictureTakenHandler");
    self.onPictureTakenHandlerId = command.callbackId;
}

- (void) setFlashMode:(CDVInvokedUrlCommand *)command {
    NSInteger mode = [command.arguments[0] integerValue];
    [self.sessionManager setFlashMode:mode];
}


- (void) takePicture:(CDVInvokedUrlCommand*)command {
    NSLog(@"takePicture");
    CDVPluginResult *pluginResult;
    
    if (self.cameraRenderController != NULL) {
        CGFloat maxW = (CGFloat)[command.arguments[0] floatValue];
        CGFloat maxH = (CGFloat)[command.arguments[1] floatValue];
        [self invokeTakePicture:maxW withHeight:maxH command:command];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Camera not started"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

+ (NSString *) applicationDocumentsDirectory {
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    return [path stringByAppendingPathComponent:@"NoCloud"]; // cordova.file.dataDirectory
}

+ (NSString *)saveImage:(UIImage *)image withName:(NSString *)name {
    NSData *data = UIImageJPEGRepresentation(image, 1.0);
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *fullPath = [[CameraPreview applicationDocumentsDirectory] stringByAppendingPathComponent:name];
    [fileManager createFileAtPath:fullPath contents:data attributes:nil];
    
    return fullPath;
}

- (void) invokeTakePicture:(CGFloat) maxWidth withHeight:(CGFloat) maxHeight command:(CDVInvokedUrlCommand*)command{
    NSLog(@"invoke take picture");
    AVCaptureConnection *connection = [self.sessionManager.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
    [self.sessionManager.stillImageOutput captureStillImageAsynchronouslyFromConnection:connection completionHandler:^(CMSampleBufferRef sampleBuffer, NSError *error) {
        
        NSLog(@"Done creating still image");
        
        if (error) {
            NSLog(@"Error taking picture: %@", error);
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Camera not started"];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        } else {
            UIDeviceOrientation currentOrientation = self.lockOrientation != UIDeviceOrientationUnknown
                                                   ? self.lockOrientation
                                                   : [[UIDevice currentDevice] orientation];
            
            NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:sampleBuffer];
            NSLog(@"Captured image");
            UIImage *capturedImage  = [CameraPreview rotateImage:[[UIImage alloc] initWithData:imageData] rotateTo:currentOrientation];
            NSLog(@"Got image data");
            NSLog(@"Image size is %f x %f", capturedImage.size.width, capturedImage.size.height);
            NSLog(@"Image orientation is %ld", (long)capturedImage.imageOrientation);
            
            CIImage *capturedCImage;
            //image resize
            
            if (maxWidth > 0 && maxHeight > 0) {
                NSLog(@"Resizing image");
                CGFloat scaleHeight = maxWidth/capturedImage.size.height;
                CGFloat scaleWidth = maxHeight/capturedImage.size.width;
                CGFloat scale = scaleHeight > scaleWidth ? scaleWidth : scaleHeight;
                
                CIFilter *resizeFilter = [CIFilter filterWithName:@"CILanczosScaleTransform"];
                [resizeFilter setValue:[[CIImage alloc] initWithCGImage:[capturedImage CGImage]] forKey:kCIInputImageKey];
                [resizeFilter setValue:[NSNumber numberWithFloat:1.0f] forKey:@"inputAspectRatio"];
                [resizeFilter setValue:[NSNumber numberWithFloat:scale] forKey:@"inputScale"];
                capturedCImage = [resizeFilter outputImage];
            } else {
                capturedCImage = [[CIImage alloc] initWithCGImage:[capturedImage CGImage]];
            }
            
            CIImage *imageToFilter;
            CIImage *finalCImage;
            
            //fix front mirroring
            if (self.sessionManager.defaultCamera == AVCaptureDevicePositionFront) {
                NSLog(@"Fixing mirroring");
                CGAffineTransform matrix = CGAffineTransformTranslate(CGAffineTransformMakeScale(1, -1), 0, capturedCImage.extent.size.height);
                imageToFilter = [capturedCImage imageByApplyingTransform:matrix];
            } else {
                imageToFilter = capturedCImage;
            }
            
            CIFilter *filter = [self.sessionManager ciFilter];
            if (filter != nil) {
                NSLog(@"Filtering image");
                [self.sessionManager.filterLock lock];
                [filter setValue:imageToFilter forKey:kCIInputImageKey];
                finalCImage = [filter outputImage];
                [self.sessionManager.filterLock unlock];
            } else {
                finalCImage = imageToFilter;
            }
            
            NSLog(@"Saving image");
            __block NSString *originalPicturePath;
            NSString *fileName = [self.filePrefix stringByAppendingString:[[[NSUUID UUID] UUIDString] stringByAppendingString:@".jpg"]];
            CIContext *context = [CIContext contextWithOptions:nil];
            UIImage *saveUIImage = [UIImage imageWithCGImage:[context createCGImage:finalCImage fromRect:finalCImage.extent]];
            originalPicturePath = [CameraPreview saveImage: saveUIImage withName: fileName];
            
            NSLog(@"%@", originalPicturePath);
            dispatch_group_t group = dispatch_group_create();
            dispatch_group_notify(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                NSMutableArray *params = [[NSMutableArray alloc] init];
                
                [params addObject:fileName];
                
                CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:params];
                [pluginResult setKeepCallbackAsBool:true];
                NSLog(@"Dispatching result");
                [self.commandDelegate sendPluginResult:pluginResult callbackId:self.onPictureTakenHandlerId];
            });
        }
    }];
}

+ (UIImage *) rotateImage: (UIImage *) imageIn rotateTo:(UIDeviceOrientation) orientation { // original: http://blog.logichigh.com/2008/06/05/uiimage-fix/
    // Camera defaults to UIImageOrientationRight (3)
    // the image needs to be rotated to match the device orientation
   
    CGImageRef        imgRef    = imageIn.CGImage;
    CGFloat           width     = CGImageGetWidth(imgRef);
    CGFloat           height    = CGImageGetHeight(imgRef);

    // Calculate the size of the rotated view
    UIView *rotatedViewBox = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
    
    CGFloat angle = 0.0;
    switch (orientation) {
        case UIDeviceOrientationPortrait:
            // rotate 90° right
            angle = M_PI_2;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            // rotate 90° left
            angle = -M_PI_2;
            break;
        case UIDeviceOrientationLandscapeLeft:
            // no rotation
            angle = 0.0;
            break;
        case UIDeviceOrientationLandscapeRight:
            // rotate 180°
            angle = M_PI;
            break;
        default:
            // no rotation
            angle = 0.0;
    }
    rotatedViewBox.transform = CGAffineTransformMakeRotation(angle);;
    CGSize rotatedSize = rotatedViewBox.frame.size;
    
    // Create bitmap context;
    UIGraphicsBeginImageContext(rotatedSize);
    CGContextRef bitmap = UIGraphicsGetCurrentContext();
    
    // Move origin to the middle to rotate/scale around center
    CGContextTranslateCTM(bitmap, rotatedSize.width/2, rotatedSize.height/2);
    
    // Rotate image
    CGContextRotateCTM(bitmap, angle);
    
    // Scale and draw image
    CGContextScaleCTM(bitmap, 1.0, -1.0); // what's this?
    CGContextDrawImage(bitmap, CGRectMake(-width/2, -height/2, width, height), imgRef);
    
    UIImage *rotated = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return rotated;
}
@end
