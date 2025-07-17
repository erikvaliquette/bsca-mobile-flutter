import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/sdg_icons.dart';

/// A service for efficiently loading and caching SDG icons
class SDGIconService {
  static final SDGIconService _instance = SDGIconService._internal();
  
  factory SDGIconService() {
    return _instance;
  }
  
  SDGIconService._internal();
  
  static SDGIconService get instance => _instance;
  
  /// Get an SDG icon as a Widget with proper caching
  Widget getSDGIconWidget({
    required int sdgNumber,
    required double size,
    Color? color,
    BoxFit fit = BoxFit.contain,
  }) {
    // Get the icon URL
    final String iconUrl = SDGIcons.getSDGIconUrl(sdgNumber);
    final Color iconColor = color ?? SDGIcons.getSDGColor(sdgNumber);
    
    // Return only the raw image without any container or border
    return CachedNetworkImage(
      imageUrl: iconUrl,
      width: size,
      height: size,
      fit: fit,
      color: color,
      placeholder: (context, url) => Icon(
        SDGIcons.getSDGIconData(sdgNumber),
        color: iconColor,
        size: size * 0.7,
      ),
      errorWidget: (context, url, error) => Icon(
        SDGIcons.getSDGIconData(sdgNumber),
        color: iconColor,
        size: size * 0.7,
      ),
    );
  }
  
  /// Preload all SDG icons into cache
  Future<void> preloadAllSDGIcons() async {
    try {
      // CachedNetworkImage handles caching automatically,
      // but we can't use precacheImage without a BuildContext
      // Instead, we'll rely on the automatic caching of CachedNetworkImage
      // when the icons are first displayed
      debugPrint('SDG icons will be cached when first displayed');
    } catch (e) {
      debugPrint('Error preloading SDG icons: $e');
    }
  }
}
