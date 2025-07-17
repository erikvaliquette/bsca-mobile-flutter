import 'package:flutter/material.dart';
import '../utils/sdg_icons.dart';
import '../services/sdg_icon_service.dart';

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
  
  /// Whether to display the icon in a circular shape
  final bool isCircular;

  const SDGIconWidget({
    Key? key,
    required this.sdgNumber,
    this.isSelected = false,
    this.onTap,
    this.size = 24.0,
    this.showLabel = true,
    this.useAssetIcon = false,
    this.showFullName = false,
    this.isCircular = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Simply return the icon image without any container, border or label
    return GestureDetector(
      onTap: onTap,
      child: SDGIconService.instance.getSDGIconWidget(
        sdgNumber: sdgNumber,
        size: size,
        color: isSelected ? Colors.white : null,
      ),
    );
  }
}
