import 'package:flutter/material.dart';

/// A utility class for SDG (Sustainable Development Goals) icons and data
class SDGIcons {
  /// Get the color associated with a specific SDG goal number
  static Color getSDGColor(int sdgNumber) {
    switch (sdgNumber) {
      case 1:
        return const Color(0xFFE5243B); // No Poverty - Red
      case 2:
        return const Color(0xFFDDA63A); // Zero Hunger - Yellow
      case 3:
        return const Color(0xFF4C9F38); // Good Health and Well-being - Green
      case 4:
        return const Color(0xFFC5192D); // Quality Education - Dark Red
      case 5:
        return const Color(0xFFFF3A21); // Gender Equality - Orange Red
      case 6:
        return const Color(0xFF26BDE2); // Clean Water and Sanitation - Light Blue
      case 7:
        return const Color(0xFFFCC30B); // Affordable and Clean Energy - Yellow
      case 8:
        return const Color(0xFFA21942); // Decent Work and Economic Growth - Burgundy
      case 9:
        return const Color(0xFFFF6C2C); // Industry, Innovation and Infrastructure - Orange
      case 10:
        return const Color(0xFFDD1367); // Reduced Inequalities - Magenta
      case 11:
        return const Color(0xFFFD9D24); // Sustainable Cities and Communities - Gold
      case 12:
        return const Color(0xFFBF8B2E); // Responsible Consumption and Production - Brown
      case 13:
        return const Color(0xFF3F7E44); // Climate Action - Dark Green
      case 14:
        return const Color(0xFF0A97D9); // Life Below Water - Blue
      case 15:
        return const Color(0xFF56C02B); // Life on Land - Lime Green
      case 16:
        return const Color(0xFF00689D); // Peace, Justice and Strong Institutions - Navy Blue
      case 17:
        return const Color(0xFF19486A); // Partnerships for the Goals - Dark Blue
      default:
        return Colors.grey; // Default color for invalid SDG numbers
    }
  }

  /// Get the name of a specific SDG goal
  static String getSDGName(int sdgNumber) {
    switch (sdgNumber) {
      case 1:
        return 'No Poverty';
      case 2:
        return 'Zero Hunger';
      case 3:
        return 'Good Health and Well-being';
      case 4:
        return 'Quality Education';
      case 5:
        return 'Gender Equality';
      case 6:
        return 'Clean Water and Sanitation';
      case 7:
        return 'Affordable and Clean Energy';
      case 8:
        return 'Decent Work and Economic Growth';
      case 9:
        return 'Industry, Innovation and Infrastructure';
      case 10:
        return 'Reduced Inequalities';
      case 11:
        return 'Sustainable Cities and Communities';
      case 12:
        return 'Responsible Consumption and Production';
      case 13:
        return 'Climate Action';
      case 14:
        return 'Life Below Water';
      case 15:
        return 'Life on Land';
      case 16:
        return 'Peace, Justice and Strong Institutions';
      case 17:
        return 'Partnerships for the Goals';
      default:
        return 'Unknown SDG';
    }
  }

  /// Get the icon data for a specific SDG goal
  static IconData getSDGIconData(int sdgNumber) {
    switch (sdgNumber) {
      case 1:
        return Icons.attach_money; // No Poverty
      case 2:
        return Icons.restaurant; // Zero Hunger
      case 3:
        return Icons.favorite; // Good Health and Well-being
      case 4:
        return Icons.school; // Quality Education
      case 5:
        return Icons.people; // Gender Equality
      case 6:
        return Icons.water_drop; // Clean Water and Sanitation
      case 7:
        return Icons.bolt; // Affordable and Clean Energy
      case 8:
        return Icons.work; // Decent Work and Economic Growth
      case 9:
        return Icons.precision_manufacturing; // Industry, Innovation and Infrastructure
      case 10:
        return Icons.balance; // Reduced Inequalities
      case 11:
        return Icons.location_city; // Sustainable Cities and Communities
      case 12:
        return Icons.shopping_cart; // Responsible Consumption and Production
      case 13:
        return Icons.thermostat; // Climate Action
      case 14:
        return Icons.water; // Life Below Water
      case 15:
        return Icons.forest; // Life on Land
      case 16:
        return Icons.gavel; // Peace, Justice and Strong Institutions
      case 17:
        return Icons.handshake; // Partnerships for the Goals
      default:
        return Icons.help_outline; // Default icon for invalid SDG numbers
    }
  }

  /// Get the URL for a specific SDG goal icon from Supabase
  static String getSDGIconUrl(int sdgNumber) {
    // Format the goal number with leading zero if needed
    String formattedNumber = sdgNumber < 10 ? '0$sdgNumber' : '$sdgNumber';
    
    // Return the Supabase URL for the SDG icon
    return 'https://vufeuaoosussspqyskdw.supabase.co/storage/v1/object/public/site_images//E-WEB-Goal-$formattedNumber.png';
  }
  
  /// Get the asset path for a specific SDG goal icon (fallback for local assets)
  static String getSDGIconPath(int sdgNumber) {
    return 'assets/icons/sdg$sdgNumber.png';
  }

  /// Build a reusable SDG icon widget
  static Widget buildSDGIcon({
    required int sdgNumber,
    required bool isSelected,
    required VoidCallback onTap,
    double size = 24.0,
    bool showLabel = true,
    bool useAssetIcon = false,
  }) {
    final Color color = getSDGColor(sdgNumber);
    
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
            // Icon - either from assets or using IconData
            useAssetIcon
                ? Image.asset(
                    getSDGIconPath(sdgNumber),
                    width: size,
                    height: size,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback to IconData if asset not found
                      return Icon(
                        getSDGIconData(sdgNumber),
                        color: isSelected ? Colors.white : color,
                        size: size,
                      );
                    },
                  )
                : Icon(
                    getSDGIconData(sdgNumber),
                    color: isSelected ? Colors.white : color,
                    size: size,
                  ),
            
            // Optional label
            if (showLabel)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'SDG $sdgNumber',
                  style: TextStyle(
                    color: isSelected ? Colors.white : color,
                    fontSize: 12.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Get a list of all SDG numbers (1-17)
  static List<int> getAllSDGNumbers() {
    return List.generate(17, (index) => index + 1);
  }
}
