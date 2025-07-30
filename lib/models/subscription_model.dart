import '../services/subscription_service.dart';

class SubscriptionModel {
  final String id;
  final String userId;
  final String? stripeCustomerId;
  final String? stripeSubscriptionId;
  final String status;
  final DateTime? currentPeriodEnd;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<dynamic> billingHistory;
  final ServiceLevel serviceLevel;

  SubscriptionModel({
    required this.id,
    required this.userId,
    this.stripeCustomerId,
    this.stripeSubscriptionId,
    required this.status,
    this.currentPeriodEnd,
    this.createdAt,
    this.updatedAt,
    required this.billingHistory,
    required this.serviceLevel,
  });

  /// Create from JSON (from Supabase)
  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      stripeCustomerId: json['stripe_customer_id'],
      stripeSubscriptionId: json['stripe_subscription_id'],
      status: json['status'] ?? 'inactive',
      currentPeriodEnd: json['current_period_end'] != null
          ? DateTime.parse(json['current_period_end'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      billingHistory: json['billing_history'] ?? [],
      serviceLevel: ServiceLevel.fromString(json['service_level'] ?? 'GENESIS'),
    );
  }

  /// Convert to JSON (for Supabase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'stripe_customer_id': stripeCustomerId,
      'stripe_subscription_id': stripeSubscriptionId,
      'status': status,
      'current_period_end': currentPeriodEnd?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'billing_history': billingHistory,
      'service_level': serviceLevel.databaseValue,
    };
  }

  /// Create default free subscription for new users
  factory SubscriptionModel.defaultFree(String userId) {
    return SubscriptionModel(
      id: 'temp_free_${userId}',
      userId: userId,
      status: 'active',
      billingHistory: [],
      serviceLevel: ServiceLevel.free,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Check if subscription is currently active
  bool get isActive {
    if (status != 'active') return false;
    
    // Free tier is always active
    if (serviceLevel == ServiceLevel.free) return true;
    
    // Paid tiers need to check expiration
    if (currentPeriodEnd == null) return false;
    
    return DateTime.now().isBefore(currentPeriodEnd!);
  }

  /// Check if subscription is expired
  bool get isExpired {
    if (serviceLevel == ServiceLevel.free) return false;
    if (currentPeriodEnd == null) return false;
    return DateTime.now().isAfter(currentPeriodEnd!);
  }

  /// Get days until expiration (null if free tier or no expiration)
  int? get daysUntilExpiration {
    if (serviceLevel == ServiceLevel.free || currentPeriodEnd == null) {
      return null;
    }
    
    final now = DateTime.now();
    if (now.isAfter(currentPeriodEnd!)) return 0;
    
    return currentPeriodEnd!.difference(now).inDays;
  }

  /// Check if subscription is expiring soon
  bool isExpiringSoon({int daysThreshold = 7}) {
    final days = daysUntilExpiration;
    if (days == null) return false;
    return days <= daysThreshold;
  }

  /// Get subscription display information
  Map<String, dynamic> get displayInfo {
    return {
      'tier': serviceLevel.displayName,
      'status': status,
      'isActive': isActive,
      'isExpired': isExpired,
      'expirationDate': currentPeriodEnd,
      'daysUntilExpiration': daysUntilExpiration,
    };
  }

  /// Copy with method for updates
  SubscriptionModel copyWith({
    String? id,
    String? userId,
    String? stripeCustomerId,
    String? stripeSubscriptionId,
    String? status,
    DateTime? currentPeriodEnd,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<dynamic>? billingHistory,
    ServiceLevel? serviceLevel,
  }) {
    return SubscriptionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      stripeCustomerId: stripeCustomerId ?? this.stripeCustomerId,
      stripeSubscriptionId: stripeSubscriptionId ?? this.stripeSubscriptionId,
      status: status ?? this.status,
      currentPeriodEnd: currentPeriodEnd ?? this.currentPeriodEnd,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      billingHistory: billingHistory ?? this.billingHistory,
      serviceLevel: serviceLevel ?? this.serviceLevel,
    );
  }

  @override
  String toString() {
    return 'SubscriptionModel(id: $id, userId: $userId, serviceLevel: ${serviceLevel.displayName}, status: $status, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SubscriptionModel &&
        other.id == id &&
        other.userId == userId &&
        other.serviceLevel == serviceLevel &&
        other.status == status;
  }

  @override
  int get hashCode {
    return Object.hash(id, userId, serviceLevel, status);
  }
}
