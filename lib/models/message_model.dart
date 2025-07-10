class MessageModel {
  final String id;
  final String senderId;
  final String? receiverId;
  final String? roomId;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? readAt;
  final String? senderName;
  final String? senderAvatarUrl;

  MessageModel({
    required this.id,
    required this.senderId,
    this.receiverId,
    this.roomId,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    this.readAt,
    this.senderName,
    this.senderAvatarUrl,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      senderId: json['sender_id'] as String,
      receiverId: json['receiver_id'] as String?,
      roomId: json['room_id'] as String?,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
      senderName: json['sender_name'] as String?,
      senderAvatarUrl: json['sender_avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'room_id': roomId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
      'sender_name': senderName,
      'sender_avatar_url': senderAvatarUrl,
    };
  }
}
