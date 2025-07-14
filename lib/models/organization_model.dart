import 'package:flutter/material.dart';

class Organization {
  final String id;
  final String name;
  final String? description;
  final String? logoUrl;
  final String? website;
  final String? location;
  final List<SustainabilityMetric>? sustainabilityMetrics;
  final CarbonFootprint? carbonFootprint;
  final List<TeamMember>? teamMembers;
  final List<String>? sdgFocusAreas;
  final List<OrganizationActivity>? recentActivities;

  Organization({
    required this.id,
    required this.name,
    this.description,
    this.logoUrl,
    this.website,
    this.location,
    this.sustainabilityMetrics,
    this.carbonFootprint,
    this.teamMembers,
    this.sdgFocusAreas,
    this.recentActivities,
  });

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      logoUrl: json['logo_url'],
      website: json['website'],
      location: json['location'],
      sustainabilityMetrics: json['sustainability_metrics'] != null
          ? (json['sustainability_metrics'] as List)
              .map((metric) => SustainabilityMetric.fromJson(metric))
              .toList()
          : null,
      carbonFootprint: json['carbon_footprint'] != null
          ? CarbonFootprint.fromJson(json['carbon_footprint'])
          : null,
      teamMembers: json['team_members'] != null
          ? (json['team_members'] as List)
              .map((member) => TeamMember.fromJson(member))
              .toList()
          : null,
      sdgFocusAreas: json['sdg_focus_areas'] != null
          ? List<String>.from(json['sdg_focus_areas'])
          : null,
      recentActivities: json['recent_activities'] != null
          ? (json['recent_activities'] as List)
              .map((activity) => OrganizationActivity.fromJson(activity))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'logo_url': logoUrl,
      'website': website,
      'location': location,
      'sustainability_metrics': sustainabilityMetrics?.map((metric) => metric.toJson()).toList(),
      'carbon_footprint': carbonFootprint?.toJson(),
      'team_members': teamMembers?.map((member) => member.toJson()).toList(),
      'sdg_focus_areas': sdgFocusAreas,
      'recent_activities': recentActivities?.map((activity) => activity.toJson()).toList(),
    };
  }
}

class SustainabilityMetric {
  final String name;
  final String value;
  final String? unit;
  final IconData? icon;

  SustainabilityMetric({
    required this.name,
    required this.value,
    this.unit,
    this.icon,
  });

  factory SustainabilityMetric.fromJson(Map<String, dynamic> json) {
    return SustainabilityMetric(
      name: json['name'],
      value: json['value'],
      unit: json['unit'],
      icon: json['icon'] != null ? IconData(json['icon'], fontFamily: 'MaterialIcons') : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
      'unit': unit,
      'icon': icon?.codePoint,
    };
  }
}

class CarbonFootprint {
  final double totalEmissions;
  final String unit;
  final double? reductionGoal;
  final double? reductionAchieved;
  final List<EmissionCategory>? categories;

  CarbonFootprint({
    required this.totalEmissions,
    required this.unit,
    this.reductionGoal,
    this.reductionAchieved,
    this.categories,
  });

  factory CarbonFootprint.fromJson(Map<String, dynamic> json) {
    return CarbonFootprint(
      totalEmissions: json['total_emissions'],
      unit: json['unit'],
      reductionGoal: json['reduction_goal'],
      reductionAchieved: json['reduction_achieved'],
      categories: json['categories'] != null
          ? (json['categories'] as List)
              .map((category) => EmissionCategory.fromJson(category))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_emissions': totalEmissions,
      'unit': unit,
      'reduction_goal': reductionGoal,
      'reduction_achieved': reductionAchieved,
      'categories': categories?.map((category) => category.toJson()).toList(),
    };
  }
}

class EmissionCategory {
  final String name;
  final double value;
  final String? icon;
  final List<EmissionSubcategory>? subcategories;

  EmissionCategory({
    required this.name,
    required this.value,
    this.icon,
    this.subcategories,
  });

  factory EmissionCategory.fromJson(Map<String, dynamic> json) {
    return EmissionCategory(
      name: json['name'],
      value: json['value'],
      icon: json['icon'],
      subcategories: json['subcategories'] != null
          ? (json['subcategories'] as List)
              .map((subcategory) => EmissionSubcategory.fromJson(subcategory))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
      'icon': icon,
      'subcategories': subcategories?.map((subcategory) => subcategory.toJson()).toList(),
    };
  }
}

class EmissionSubcategory {
  final String name;
  final double value;
  final String? fuelType;

  EmissionSubcategory({
    required this.name,
    required this.value,
    this.fuelType,
  });

  factory EmissionSubcategory.fromJson(Map<String, dynamic> json) {
    return EmissionSubcategory(
      name: json['name'],
      value: json['value'],
      fuelType: json['fuel_type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
      'fuel_type': fuelType,
    };
  }
}

class TeamMember {
  final String id;
  final String name;
  final String? role;
  final String? photoUrl;
  final String? email;

  TeamMember({
    required this.id,
    required this.name,
    this.role,
    this.photoUrl,
    this.email,
  });

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      id: json['id'],
      name: json['name'],
      role: json['role'],
      photoUrl: json['photo_url'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'photo_url': photoUrl,
      'email': email,
    };
  }
}

class OrganizationActivity {
  final String id;
  final String title;
  final String? description;
  final DateTime date;
  final String? imageUrl;
  final ActivityType type;

  OrganizationActivity({
    required this.id,
    required this.title,
    this.description,
    required this.date,
    this.imageUrl,
    required this.type,
  });

  factory OrganizationActivity.fromJson(Map<String, dynamic> json) {
    return OrganizationActivity(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      date: DateTime.parse(json['date']),
      imageUrl: json['image_url'],
      type: ActivityType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => ActivityType.other,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'image_url': imageUrl,
      'type': type.toString().split('.').last,
    };
  }
}

enum ActivityType {
  event,
  initiative,
  achievement,
  announcement,
  other,
}
