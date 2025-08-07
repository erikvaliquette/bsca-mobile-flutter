import 'package:flutter/material.dart';
import 'package:bsca_mobile_flutter/utils/sdg_icons.dart';

/// A simple widget to display SDG icons using the SDGIcons utility
class SdgIconDisplay extends StatelessWidget {
  final int sdgNumber;
  final double size;

  const SdgIconDisplay({
    Key? key,
    required this.sdgNumber,
    this.size = 24.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color color = SDGIcons.getSDGColor(sdgNumber);
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          SDGIcons.getSDGIconData(sdgNumber),
          color: Colors.white,
          size: size * 0.6,
        ),
      ),
    );
  }
}
