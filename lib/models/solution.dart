import 'package:uuid/uuid.dart';

class Solution {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? userId;
  final String? name;
  final String? vendorName;
  final String? description;
  final String? category;
  final List<String> features;
  final String? pricingModel;
  final String? website;
  final bool isActive;
  final List<int> sdgGoals;

  Solution({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.userId,
    this.name,
    this.vendorName,
    this.description,
    this.category,
    required this.features,
    this.pricingModel,
    this.website,
    required this.isActive,
    required this.sdgGoals,
  });

  factory Solution.fromJson(Map<String, dynamic> json) {
    return Solution(
      id: json['id'] ?? const Uuid().v4(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      userId: json['user_id'],
      name: json['name'],
      vendorName: json['vendor_name'],
      description: json['description'],
      category: json['category'],
      features: json['features'] != null
          ? List<String>.from(json['features'])
          : [],
      pricingModel: json['pricing_model'],
      website: json['website'],
      isActive: json['is_active'] ?? true,
      sdgGoals: json['sdg_goals'] != null
          ? List<int>.from(json['sdg_goals'])
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'user_id': userId,
      'name': name,
      'vendor_name': vendorName,
      'description': description,
      'category': category,
      'features': features,
      'pricing_model': pricingModel,
      'website': website,
      'is_active': isActive,
      'sdg_goals': sdgGoals,
    };
  }
}
