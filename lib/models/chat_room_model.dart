class ChatRoomModel {
  final String id;
  final String roomId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  // Additional UI fields not in the database
  final String? name;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int? unreadCount;
  final List<String>? participantIds;
  final bool? isStarred;
  final String? avatarUrl;

  ChatRoomModel({
    required this.id,
    required this.roomId,
    this.createdAt,
    this.updatedAt,
    this.name,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount,
    this.participantIds,
    this.isStarred,
    this.avatarUrl,
  });

  factory ChatRoomModel.fromJson(Map<String, dynamic> json) {
    return ChatRoomModel(
      id: json['id'],
      roomId: json['room_id'],
      createdAt: json['created_at'] != null 
          ? (json['created_at'] is String 
              ? DateTime.parse(json['created_at']) 
              : json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null 
          ? (json['updated_at'] is String 
              ? DateTime.parse(json['updated_at']) 
              : json['updated_at'])
          : null,
      name: json['name'],
      lastMessage: json['last_message'],
      lastMessageTime: json['last_message_time'] != null 
          ? (json['last_message_time'] is String 
              ? DateTime.parse(json['last_message_time']) 
              : json['last_message_time'])
          : null,
      unreadCount: json['unread_count'],
      avatarUrl: json['avatar_url'],
      participantIds: json['participant_ids'] != null 
          ? List<String>.from(json['participant_ids'])
          : null,
      isStarred: json['is_starred'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      'room_id': roomId,
    };

    if (createdAt != null) data['created_at'] = createdAt!.toIso8601String();
    if (updatedAt != null) data['updated_at'] = updatedAt!.toIso8601String();
    if (name != null) data['name'] = name;
    if (lastMessage != null) data['last_message'] = lastMessage;
    if (lastMessageTime != null) data['last_message_time'] = lastMessageTime!.toIso8601String();
    if (unreadCount != null) data['unread_count'] = unreadCount;
    if (participantIds != null) data['participant_ids'] = participantIds;
    if (isStarred != null) data['is_starred'] = isStarred;

    return data;
  }
  
  // Create a copy of this ChatRoomModel with optional field updates
  ChatRoomModel copyWith({
    String? id,
    String? roomId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? name,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    List<String>? participantIds,
    bool? isStarred,
    String? avatarUrl,
  }) {
    return ChatRoomModel(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      name: name ?? this.name,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      participantIds: participantIds ?? this.participantIds,
      isStarred: isStarred ?? this.isStarred,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
