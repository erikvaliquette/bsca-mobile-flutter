#import <Foundation/Foundation.h>
#import <MobileCoreServices/MobileCoreServices.h>

// This category provides modern replacements for deprecated kUTType constants
@interface NSString (UTTypeConstants)

// Image types
+ (NSString *)utTypeImage;
+ (NSString *)utTypeGIF;

// Video types
+ (NSString *)utTypeMovie;
+ (NSString *)utTypeVideo;
+ (NSString *)utTypeAVIMovie;
+ (NSString *)utTypeMPEG4;

@end
