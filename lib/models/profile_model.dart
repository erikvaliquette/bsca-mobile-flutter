import 'package:flutter/foundation.dart';

class WorkHistory {
  final String? company;
  final String? position;
  final String? description;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool? isCurrent;

  WorkHistory({
    this.company,
    this.position,
    this.description,
    this.startDate,
    this.endDate,
    this.isCurrent,
  });

  factory WorkHistory.fromJson(Map<String, dynamic> json) {
    return WorkHistory(
      company: json['company'] as String?,
      position: json['position'] as String?,
      description: json['description'] as String?,
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date'] as String) : null,
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date'] as String) : null,
      isCurrent: json['is_current'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'company': company,
      'position': position,
      'description': description,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'is_current': isCurrent,
    };
  }
}

class Education {
  final String? institution;
  final String? degree;
  final String? fieldOfStudy;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool? isCurrent;

  Education({
    this.institution,
    this.degree,
    this.fieldOfStudy,
    this.startDate,
    this.endDate,
    this.isCurrent,
  });

  factory Education.fromJson(Map<String, dynamic> json) {
    return Education(
      institution: json['institution'] as String?,
      degree: json['degree'] as String?,
      fieldOfStudy: json['field_of_study'] as String?,
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date'] as String) : null,
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date'] as String) : null,
      isCurrent: json['is_current'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'institution': institution,
      'degree': degree,
      'field_of_study': fieldOfStudy,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'is_current': isCurrent,
    };
  }
}

class Certification {
  final String? name;
  final String? issuingOrganization;
  final DateTime? issueDate;
  final DateTime? expirationDate;
  final String? credentialId;
  final String? credentialUrl;

  Certification({
    this.name,
    this.issuingOrganization,
    this.issueDate,
    this.expirationDate,
    this.credentialId,
    this.credentialUrl,
  });

  factory Certification.fromJson(Map<String, dynamic> json) {
    return Certification(
      name: json['name'] as String?,
      issuingOrganization: json['issuing_organization'] as String?,
      issueDate: json['issue_date'] != null ? DateTime.parse(json['issue_date'] as String) : null,
      expirationDate: json['expiration_date'] != null ? DateTime.parse(json['expiration_date'] as String) : null,
      credentialId: json['credential_id'] as String?,
      credentialUrl: json['credential_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'issuing_organization': issuingOrganization,
      'issue_date': issueDate?.toIso8601String(),
      'expiration_date': expirationDate?.toIso8601String(),
      'credential_id': credentialId,
      'credential_url': credentialUrl,
    };
  }
}

class ProfileModel {
  final String id;
  final String? username;
  final String? fullName;
  final String? avatarUrl;
  final String? bio;
  final Map<String, dynamic>? preferences;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  // Additional profile fields
  final List<String>? sdgGoals;
  final List<WorkHistory>? workHistory;
  final List<Education>? education;
  final List<Certification>? certifications;

  ProfileModel({
    required this.id,
    this.username,
    this.fullName,
    this.avatarUrl,
    this.bio,
    this.preferences,
    this.createdAt,
    this.updatedAt,
    this.sdgGoals,
    this.workHistory,
    this.education,
    this.certifications,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    // Parse SDG goals if available
    List<String>? sdgGoals;
    if (json['sdg_goals'] != null) {
      if (json['sdg_goals'] is List) {
        sdgGoals = (json['sdg_goals'] as List).map((e) => e.toString()).toList();
      } else if (json['sdg_goals'] is Map) {
        // Handle case where it might be stored as a JSON object
        sdgGoals = (json['sdg_goals'] as Map).values.map((e) => e.toString()).toList();
      }
    }
    
    // Parse work history if available
    List<WorkHistory>? workHistory;
    if (json['work_history'] != null && json['work_history'] is List) {
      workHistory = (json['work_history'] as List)
          .map((e) => WorkHistory.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    
    // Parse education if available
    List<Education>? education;
    if (json['education'] != null && json['education'] is List) {
      education = (json['education'] as List)
          .map((e) => Education.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    
    // Parse certifications if available
    List<Certification>? certifications;
    if (json['certifications'] != null && json['certifications'] is List) {
      certifications = (json['certifications'] as List)
          .map((e) => Certification.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    
    return ProfileModel(
      id: json['id'] as String,
      username: json['username'] as String?,
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      preferences: json['preferences'] as Map<String, dynamic>?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
      sdgGoals: sdgGoals,
      workHistory: workHistory,
      education: education,
      certifications: certifications,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'bio': bio,
      'preferences': preferences,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'sdg_goals': sdgGoals,
      'work_history': workHistory?.map((work) => work.toJson()).toList(),
      'education': education?.map((edu) => edu.toJson()).toList(),
      'certifications': certifications?.map((cert) => cert.toJson()).toList(),
    };
  }

  ProfileModel copyWith({
    String? id,
    String? username,
    String? fullName,
    String? avatarUrl,
    String? bio,
    Map<String, dynamic>? preferences,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? sdgGoals,
    List<WorkHistory>? workHistory,
    List<Education>? education,
    List<Certification>? certifications,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      preferences: preferences ?? this.preferences,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sdgGoals: sdgGoals ?? this.sdgGoals,
      workHistory: workHistory ?? this.workHistory,
      education: education ?? this.education,
      certifications: certifications ?? this.certifications,
    );
  }

  @override
  String toString() {
    return 'ProfileModel(id: $id, username: $username, fullName: $fullName, avatarUrl: $avatarUrl, bio: $bio)';
  }
}
