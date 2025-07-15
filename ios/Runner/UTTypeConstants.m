#import "UTTypeConstants.h"
#import <MobileCoreServices/MobileCoreServices.h>

@implementation NSString (UTTypeConstants)

// Image types
+ (NSString *)utTypeImage {
    return (__bridge NSString *)kUTTypeImage;
}

+ (NSString *)utTypeGIF {
    return (__bridge NSString *)kUTTypeGIF;
}

// Video types
+ (NSString *)utTypeMovie {
    return (__bridge NSString *)kUTTypeMovie;
}

+ (NSString *)utTypeVideo {
    return (__bridge NSString *)kUTTypeVideo;
}

+ (NSString *)utTypeAVIMovie {
    return (__bridge NSString *)kUTTypeAVIMovie;
}

+ (NSString *)utTypeMPEG4 {
    return (__bridge NSString *)kUTTypeMPEG4;
}

@end
