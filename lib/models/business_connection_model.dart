class BusinessConnection {
  final String id;
  String name; // Changed to non-final to allow updates
  String? location;
  String? title;
  String? organization;
  String? profileImageUrl;
  List<int>? sdgGoals;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String userId;
  final String counterpartyId;
  final String relationshipType;
  final String status;

  BusinessConnection({
    required this.id,
    required this.name,
    required this.userId,
    required this.counterpartyId,
    required this.relationshipType,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.location,
    this.title,
    this.organization,
    this.profileImageUrl,
    this.sdgGoals,
  });

  // Get initials from name
  String get initials {
    if (name.isEmpty) return '';
    
    final nameParts = name.split(' ');
    if (nameParts.length == 1) {
      return nameParts[0][0].toUpperCase();
    } else {
      return '${nameParts[0][0]}${nameParts.last[0]}'.toUpperCase();
    }
  }

  // Factory constructor to create a BusinessConnection from a Supabase JSON response
  factory BusinessConnection.fromJson(Map<String, dynamic> json) {
    List<int>? sdgs;
    if (json['sdg_goals'] != null) {
      if (json['sdg_goals'] is List) {
        sdgs = List<int>.from(json['sdg_goals']);
      } else if (json['sdg_goals'] is String) {
        try {
          // Try to parse string representation of list
          final String sdgString = json['sdg_goals'].toString();
          if (sdgString.startsWith('[') && sdgString.endsWith(']')) {
            final trimmed = sdgString.substring(1, sdgString.length - 1);
            sdgs = trimmed.split(',').map((e) => int.tryParse(e.trim()) ?? 0).toList();
          }
        } catch (e) {
          print('Error parsing SDG goals: $e');
        }
      }
    }

    return BusinessConnection(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      counterpartyId: json['counterparty_id'] ?? '',
      relationshipType: json['relationship_type'] ?? '',
      status: json['status'] ?? '',
      name: json['name'] ?? '',
      location: json['location'],
      title: json['title'],
      organization: json['organization'],
      profileImageUrl: json['profile_image_url'] ?? json['avatar_url'],
      sdgGoals: sdgs,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  // Convert BusinessConnection to JSON
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'counterparty_id': counterpartyId,
      'relationship_type': relationshipType,
      'status': status,
      'name': name,
      'location': location,
      'title': title,
      'organization': organization,
      'profile_image_url': profileImageUrl,
      'sdg_goals': sdgGoals,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
