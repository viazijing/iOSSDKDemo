#import <Foundation/Foundation.h>
#import <WebRTC/RTCVideoCapturer.h>

NS_ASSUME_NONNULL_BEGIN

RTC_OBJC_EXPORT

NS_CLASS_AVAILABLE_IOS(10)
@interface RTCImageCapturer : RTCVideoCapturer
- (void)startCaptureWithImage:(UIImage *)image interval:(float) interval;
// you must stop capture before release RTCImageCapturer
- (void)stop;
- (void)restartWithinterval:(float)interval;
@end
NS_ASSUME_NONNULL_END
