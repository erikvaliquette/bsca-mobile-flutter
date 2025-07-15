import 'package:flutter/material.dart';

class SDGGoal {
  final int id;
  final String name;
  final Color color;
  final String iconPath;

  const SDGGoal({
    required this.id,
    required this.name,
    required this.color,
    required this.iconPath,
  });

  static const List<SDGGoal> allGoals = [
    SDGGoal(
      id: 1,
      name: 'No Poverty',
      color: Color(0xFFE5243B),
      iconPath: 'assets/images/sdg/sdg1.png',
    ),
    SDGGoal(
      id: 2,
      name: 'Zero Hunger',
      color: Color(0xFFDDA63A),
      iconPath: 'assets/images/sdg/sdg2.png',
    ),
    SDGGoal(
      id: 3,
      name: 'Good Health and Well-being',
      color: Color(0xFF4C9F38),
      iconPath: 'assets/images/sdg/sdg3.png',
    ),
    SDGGoal(
      id: 4,
      name: 'Quality Education',
      color: Color(0xFFC5192D),
      iconPath: 'assets/images/sdg/sdg4.png',
    ),
    SDGGoal(
      id: 5,
      name: 'Gender Equality',
      color: Color(0xFFFF3A21),
      iconPath: 'assets/images/sdg/sdg5.png',
    ),
    SDGGoal(
      id: 6,
      name: 'Clean Water and Sanitation',
      color: Color(0xFF26BDE2),
      iconPath: 'assets/images/sdg/sdg6.png',
    ),
    SDGGoal(
      id: 7,
      name: 'Affordable and Clean Energy',
      color: Color(0xFFFCC30B),
      iconPath: 'assets/images/sdg/sdg7.png',
    ),
    SDGGoal(
      id: 8,
      name: 'Decent Work and Economic Growth',
      color: Color(0xFFA21942),
      iconPath: 'assets/images/sdg/sdg8.png',
    ),
    SDGGoal(
      id: 9,
      name: 'Industry, Innovation and Infrastructure',
      color: Color(0xFFFD6925),
      iconPath: 'assets/images/sdg/sdg9.png',
    ),
    SDGGoal(
      id: 10,
      name: 'Reduced Inequalities',
      color: Color(0xFFDD1367),
      iconPath: 'assets/images/sdg/sdg10.png',
    ),
    SDGGoal(
      id: 11,
      name: 'Sustainable Cities and Communities',
      color: Color(0xFFFD9D24),
      iconPath: 'assets/images/sdg/sdg11.png',
    ),
    SDGGoal(
      id: 12,
      name: 'Responsible Consumption and Production',
      color: Color(0xFFBF8B2E),
      iconPath: 'assets/images/sdg/sdg12.png',
    ),
    SDGGoal(
      id: 13,
      name: 'Climate Action',
      color: Color(0xFF3F7E44),
      iconPath: 'assets/images/sdg/sdg13.png',
    ),
    SDGGoal(
      id: 14,
      name: 'Life Below Water',
      color: Color(0xFF0A97D9),
      iconPath: 'assets/images/sdg/sdg14.png',
    ),
    SDGGoal(
      id: 15,
      name: 'Life on Land',
      color: Color(0xFF56C02B),
      iconPath: 'assets/images/sdg/sdg15.png',
    ),
    SDGGoal(
      id: 16,
      name: 'Peace, Justice and Strong Institutions',
      color: Color(0xFF00689D),
      iconPath: 'assets/images/sdg/sdg16.png',
    ),
    SDGGoal(
      id: 17,
      name: 'Partnerships for the Goals',
      color: Color(0xFF19486A),
      iconPath: 'assets/images/sdg/sdg17.png',
    ),
  ];

  static SDGGoal getById(int id) {
    return allGoals.firstWhere(
      (goal) => goal.id == id,
      orElse: () => allGoals[0],
    );
  }

  static List<SDGGoal> getByIds(List<int> ids) {
    return ids.map((id) => getById(id)).toList();
  }
}
