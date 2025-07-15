import Foundation
import UniformTypeIdentifiers
import MobileCoreServices

// This extension provides modern UTType equivalents for the deprecated kUTType constants
// used by the image_picker_ios plugin
@objc extension NSString {
    // Image types
    @objc static var utTypeImage: NSString {
        if #available(iOS 14.0, *) {
            return UTType.image.identifier as NSString
        } else {
            return kUTTypeImage as NSString
        }
    }
    
    @objc static var utTypeGIF: NSString {
        if #available(iOS 14.0, *) {
            return UTType.gif.identifier as NSString
        } else {
            return kUTTypeGIF as NSString
        }
    }
    
    // Video types
    @objc static var utTypeMovie: NSString {
        if #available(iOS 14.0, *) {
            return UTType.movie.identifier as NSString
        } else {
            return kUTTypeMovie as NSString
        }
    }
    
    @objc static var utTypeVideo: NSString {
        if #available(iOS 14.0, *) {
            return UTType.video.identifier as NSString
        } else {
            return kUTTypeVideo as NSString
        }
    }
    
    @objc static var utTypeAVIMovie: NSString {
        if #available(iOS 14.0, *) {
            return UTType.avi.identifier as NSString
        } else {
            return kUTTypeAVIMovie as NSString
        }
    }
    
    @objc static var utTypeMPEG4: NSString {
        if #available(iOS 14.0, *) {
            return UTType.mpeg4Movie.identifier as NSString
        } else {
            return kUTTypeMPEG4 as NSString
        }
    }
}
