import 'package:flutter/material.dart';
import 'organization_model.dart';

/// Model representing a user's membership in an organization
class OrganizationMembership {
  final String id;
  final String organizationId;
  final String userId;
  final String role; // 'admin', 'member', 'manager', etc.
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime? joinedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Organization? organization;
  final UserProfile? userProfile;

  OrganizationMembership({
    required this.id,
    required this.organizationId,
    required this.userId,
    required this.role,
    required this.status,
    this.joinedAt,
    required this.createdAt,
    required this.updatedAt,
    this.organization,
    this.userProfile,
  });

  /// Create from JSON
  factory OrganizationMembership.fromJson(Map<String, dynamic> json) {
    return OrganizationMembership(
      id: json['id'],
      organizationId: json['organization_id'],
      userId: json['user_id'],
      role: json['role'] ?? 'member',
      status: json['status'] ?? 'pending',
      joinedAt: json['joined_at'] != null 
          ? DateTime.parse(json['joined_at']) 
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      organization: json['organizations'] != null 
          ? Organization.fromJson(json['organizations'])
          : null,
      userProfile: json['profiles'] != null 
          ? UserProfile.fromJson(json['profiles'])
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organization_id': organizationId,
      'user_id': userId,
      'role': role,
      'status': status,
      'joined_at': joinedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Copy with new values
  OrganizationMembership copyWith({
    String? id,
    String? organizationId,
    String? userId,
    String? role,
    String? status,
    DateTime? joinedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    Organization? organization,
    UserProfile? userProfile,
  }) {
    return OrganizationMembership(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      status: status ?? this.status,
      joinedAt: joinedAt ?? this.joinedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      organization: organization ?? this.organization,
      userProfile: userProfile ?? this.userProfile,
    );
  }

  /// Check if membership is approved
  bool get isApproved => status == 'approved';

  /// Check if membership is pending
  bool get isPending => status == 'pending';

  /// Check if membership is rejected
  bool get isRejected => status == 'rejected';

  /// Check if user is admin
  bool get isAdmin => role == 'admin';

  /// Check if user is member
  bool get isMember => role == 'member';

  /// Get status display text
  String get statusDisplayText {
    switch (status) {
      case 'approved':
        return 'Approved';
      case 'pending':
        return 'Pending Approval';
      case 'rejected':
        return 'Rejected';
      default:
        return status.toUpperCase();
    }
  }

  /// Get role display text
  String get roleDisplayText {
    switch (role) {
      case 'admin':
        return 'Administrator';
      case 'member':
        return 'Member';
      case 'manager':
        return 'Manager';
      default:
        return role.toUpperCase();
    }
  }

  /// Get status color
  Color get statusColor {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  String toString() {
    return 'OrganizationMembership(id: $id, organizationId: $organizationId, userId: $userId, role: $role, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrganizationMembership && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Simple user profile model for membership display
class UserProfile {
  final String id;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? avatarUrl;
  final String? headline;
  final String? companyName;

  UserProfile({
    required this.id,
    this.firstName,
    this.lastName,
    this.email,
    this.avatarUrl,
    this.headline,
    this.companyName,
  });

  /// Create from JSON
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      email: json['email'],
      avatarUrl: json['avatar_url'],
      headline: json['headline'],
      companyName: json['company_name'],
    );
  }

  /// Get display name
  String get displayName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    } else if (firstName != null) {
      return firstName!;
    } else if (lastName != null) {
      return lastName!;
    } else if (email != null) {
      return email!;
    } else {
      return 'Unknown User';
    }
  }

  /// Get initials for avatar
  String get initials {
    if (firstName != null && lastName != null) {
      return '${firstName![0]}${lastName![0]}'.toUpperCase();
    } else if (firstName != null) {
      return firstName![0].toUpperCase();
    } else if (lastName != null) {
      return lastName![0].toUpperCase();
    } else if (email != null) {
      return email![0].toUpperCase();
    } else {
      return 'U';
    }
  }
}
