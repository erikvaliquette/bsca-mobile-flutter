import 'package:flutter/material.dart';

class SustainabilityBackground extends StatelessWidget {
  final Widget child;
  final double iconOpacity;
  final int iconCount;
  
  const SustainabilityBackground({
    super.key,
    required this.child,
    this.iconOpacity = 0.1,
    this.iconCount = 15,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Gradient background
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1A73E8), // Blue
                Color(0xFF34A853), // Green
              ],
            ),
          ),
        ),
        
        // Sustainability icons
        Positioned.fill(
          child: CustomPaint(
            painter: SustainabilityIconsPainter(
              iconCount: iconCount,
              opacity: iconOpacity,
            ),
          ),
        ),
        
        // Content
        child,
      ],
    );
  }
}

class SustainabilityIconsPainter extends CustomPainter {
  final int iconCount;
  final double opacity;
  
  SustainabilityIconsPainter({
    required this.iconCount,
    required this.opacity,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final random = DateTime.now().millisecondsSinceEpoch;
    final icons = [
      Icons.eco,
      Icons.water_drop,
      Icons.recycling,
      Icons.energy_savings_leaf,
      Icons.solar_power,
      Icons.forest,
      Icons.compost,
    ];
    
    final paint = Paint()
      ..color = Colors.white.withOpacity(opacity)
      ..style = PaintingStyle.fill;
    
    for (int i = 0; i < iconCount; i++) {
      final icon = icons[(random + i) % icons.length];
      final x = (random + i * 7919) % size.width.toInt();
      final y = (random + i * 6997) % size.height.toInt();
      final iconSize = (random + i * 3) % 30 + 20.0;
      
      final textPainter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(icon.codePoint),
          style: TextStyle(
            fontSize: iconSize,
            fontFamily: icon.fontFamily,
            color: Colors.white.withOpacity(opacity),
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      
      textPainter.layout();
      textPainter.paint(canvas, Offset(x.toDouble(), y.toDouble()));
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
