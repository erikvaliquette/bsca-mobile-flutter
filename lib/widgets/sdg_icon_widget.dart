import 'package:flutter/material.dart';
import '../utils/sdg_icons.dart';

/// A reusable widget for displaying SDG (Sustainable Development Goals) icons
class SDGIconWidget extends StatelessWidget {
  /// The SDG goal number (1-17)
  final int sdgNumber;
  
  /// Whether this SDG is currently selected
  final bool isSelected;
  
  /// Callback when the SDG icon is tapped
  final VoidCallback? onTap;
  
  /// Size of the icon
  final double size;
  
  /// Whether to show the SDG label text
  final bool showLabel;
  
  /// Whether to use asset images instead of IconData
  final bool useAssetIcon;
  
  /// Whether to show the full SDG name instead of just "SDG X"
  final bool showFullName;

  const SDGIconWidget({
    Key? key,
    required this.sdgNumber,
    this.isSelected = false,
    this.onTap,
    this.size = 24.0,
    this.showLabel = true,
    this.useAssetIcon = false,
    this.showFullName = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color color = SDGIcons.getSDGColor(sdgNumber);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8.0),
        padding: const EdgeInsets.all(4.0),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: color,
            width: 2.0,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon - using Supabase URL, with fallbacks to assets or IconData
            Image.network(
              SDGIcons.getSDGIconUrl(sdgNumber),
              width: size,
              height: size,
              errorBuilder: (context, error, stackTrace) {
                // First fallback: try local asset
                if (useAssetIcon) {
                  return Image.asset(
                    SDGIcons.getSDGIconPath(sdgNumber),
                    width: size,
                    height: size,
                    errorBuilder: (context, error, stackTrace) {
                      // Second fallback: use IconData
                      return Icon(
                        SDGIcons.getSDGIconData(sdgNumber),
                        color: isSelected ? Colors.white : color,
                        size: size,
                      );
                    },
                  );
                } else {
                  // Direct fallback to IconData
                  return Icon(
                    SDGIcons.getSDGIconData(sdgNumber),
                    color: isSelected ? Colors.white : color,
                    size: size,
                  );
                }
              },
            ),
            
            // Optional label
            if (showLabel)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  showFullName ? SDGIcons.getSDGName(sdgNumber) : 'SDG $sdgNumber',
                  style: TextStyle(
                    color: isSelected ? Colors.white : color,
                    fontSize: 12.0,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: showFullName ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
