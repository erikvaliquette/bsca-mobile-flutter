import 'package:flutter/material.dart';

class Organization {
  final String id;
  final String name;
  final String? description;
  final String? logoUrl;
  final String? website;
  final String? location;
  final String? orgType;
  final String? status;
  final List<SustainabilityMetric>? sustainabilityMetrics;
  final CarbonFootprint? carbonFootprint;
  final List<TeamMember>? teamMembers;
  final List<String>? sdgFocusAreas;
  final List<Activity>? activities;

  Organization({
    required this.id,
    required this.name,
    this.description,
    this.logoUrl,
    this.website,
    this.location,
    this.orgType,
    this.status,
    this.sustainabilityMetrics,
    this.carbonFootprint,
    this.teamMembers,
    this.sdgFocusAreas,
    this.activities,
  });
  
  Organization copyWith({
    String? id,
    String? name,
    String? description,
    String? logoUrl,
    String? website,
    String? location,
    String? orgType,
    String? status,
    List<SustainabilityMetric>? sustainabilityMetrics,
    CarbonFootprint? carbonFootprint,
    List<TeamMember>? teamMembers,
    List<String>? sdgFocusAreas,
    List<Activity>? activities,
  }) {
    return Organization(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      website: website ?? this.website,
      location: location ?? this.location,
      orgType: orgType ?? this.orgType,
      status: status ?? this.status,
      sustainabilityMetrics: sustainabilityMetrics ?? this.sustainabilityMetrics,
      carbonFootprint: carbonFootprint ?? this.carbonFootprint,
      teamMembers: teamMembers ?? this.teamMembers,
      sdgFocusAreas: sdgFocusAreas ?? this.sdgFocusAreas,
      activities: activities ?? this.activities,
    );
  }

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['id'].toString(),
      name: json['name'],
      description: json['description'],
      logoUrl: json['logo_url'],
      website: json['website'],
      location: json['location'],
      orgType: json['org_type'],
      status: json['status'],
      // These fields are fetched separately by the OrganizationService
      sustainabilityMetrics: null,
      carbonFootprint: null,
      teamMembers: null,
      sdgFocusAreas: null,
      activities: null,
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
      'org_type': orgType,
      'status': status,
      // These fields are managed separately
      // 'sustainability_metrics': sustainabilityMetrics?.map((metric) => metric.toJson()).toList(),
      // 'carbon_footprint': carbonFootprint?.toJson(),
      // 'team_members': teamMembers?.map((member) => member.toJson()).toList(),
      // 'sdg_focus_areas': sdgFocusAreas,
      // 'activities': activities?.map((activity) => activity.toJson()).toList(),
    };
  }
}

class SustainabilityMetric {
  final String name;
  final dynamic value; // Can be double or int
  final dynamic target; // Optional target value
  final String? unit;
  final String? description;

  SustainabilityMetric({
    required this.name,
    required this.value,
    this.target,
    this.unit,
    this.description,
  });

  factory SustainabilityMetric.fromJson(Map<String, dynamic> json) {
    return SustainabilityMetric(
      name: json['name'],
      value: json['value'],
      target: json['target'],
      unit: json['unit'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
      'target': target,
      'unit': unit,
      'description': description,
    };
  }
}

class CarbonFootprint {
  final double totalEmissions;
  final String unit;
  final int? year;
  final double? reductionGoal;
  final double? reductionTarget;
  final List<EmissionCategory>? categories;

  CarbonFootprint({
    required this.totalEmissions,
    required this.unit,
    this.year,
    this.reductionGoal,
    this.reductionTarget,
    this.categories,
  });

  factory CarbonFootprint.fromJson(Map<String, dynamic> json) {
    return CarbonFootprint(
      totalEmissions: json['total_emissions'] is int 
          ? (json['total_emissions'] as int).toDouble() 
          : json['total_emissions'],
      unit: json['unit'],
      year: json['year'],
      reductionGoal: json['reduction_goal'] != null 
          ? (json['reduction_goal'] is int 
              ? (json['reduction_goal'] as int).toDouble() 
              : json['reduction_goal']) 
          : null,
      reductionTarget: json['reduction_target'] != null 
          ? (json['reduction_target'] is int 
              ? (json['reduction_target'] as int).toDouble() 
              : json['reduction_target']) 
          : null,
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
      'year': year,
      'reduction_goal': reductionGoal,
      'reduction_target': reductionTarget,
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
  final String? id;
  final String name;
  final String? role;
  final String? photoUrl;
  final String? email;

  TeamMember({
    this.id,
    required this.name,
    this.role,
    this.photoUrl,
    this.email,
  });

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      id: json['id']?.toString(),
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

class Activity {
  final String? id;
  final String title;
  final String? description;
  final DateTime date;
  final String? imageUrl;
  final String? type;

  Activity({
    this.id,
    required this.title,
    this.description,
    required this.date,
    this.imageUrl,
    this.type,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id']?.toString(),
      title: json['title'],
      description: json['description'],
      date: json['date'] is String 
          ? DateTime.parse(json['date']) 
          : DateTime.fromMillisecondsSinceEpoch(json['date']),
      imageUrl: json['image_url'],
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'image_url': imageUrl,
      'type': type,
    };
  }
}
