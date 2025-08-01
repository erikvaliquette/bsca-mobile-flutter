import 'package:hive/hive.dart';
import 'business_connection_model.dart';

part 'local_business_connection.g.dart';

@HiveType(typeId: 2)
class LocalBusinessConnection extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? location;

  @HiveField(3)
  final String? title;

  @HiveField(4)
  final String? organization;

  @HiveField(5)
  final String? profileImageUrl;

  @HiveField(6)
  final List<int>? sdgGoals;

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  final DateTime updatedAt;

  @HiveField(9)
  final String userId;

  @HiveField(10)
  final String counterpartyId;

  @HiveField(11)
  final String relationshipType;

  @HiveField(12)
  final String status;

  @HiveField(13)
  final DateTime cachedAt;

  @HiveField(14)
  final String currentUserId; // To support multiple users

  LocalBusinessConnection({
    required this.id,
    required this.name,
    required this.userId,
    required this.counterpartyId,
    required this.relationshipType,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.cachedAt,
    required this.currentUserId,
    this.location,
    this.title,
    this.organization,
    this.profileImageUrl,
    this.sdgGoals,
  });

  /// Convert from BusinessConnection to LocalBusinessConnection
  factory LocalBusinessConnection.fromBusinessConnection(
    BusinessConnection connection,
    String currentUserId,
  ) {
    return LocalBusinessConnection(
      id: connection.id,
      name: connection.name,
      location: connection.location,
      title: connection.title,
      organization: connection.organization,
      profileImageUrl: connection.profileImageUrl,
      sdgGoals: connection.sdgGoals,
      createdAt: connection.createdAt,
      updatedAt: connection.updatedAt,
      userId: connection.userId,
      counterpartyId: connection.counterpartyId,
      relationshipType: connection.relationshipType,
      status: connection.status,
      cachedAt: DateTime.now(),
      currentUserId: currentUserId,
    );
  }

  /// Convert to BusinessConnection
  BusinessConnection toBusinessConnection() {
    return BusinessConnection(
      id: id,
      name: name,
      location: location,
      title: title,
      organization: organization,
      profileImageUrl: profileImageUrl,
      sdgGoals: sdgGoals,
      createdAt: createdAt,
      updatedAt: updatedAt,
      userId: userId,
      counterpartyId: counterpartyId,
      relationshipType: relationshipType,
      status: status,
    );
  }

  /// Check if cache is still valid (default: 5 minutes)
  bool isCacheValid({Duration maxAge = const Duration(minutes: 5)}) {
    return DateTime.now().difference(cachedAt) < maxAge;
  }

  /// Check if this is a connection for the current user
  bool isForUser(String userId) {
    return currentUserId == userId;
  }
}
