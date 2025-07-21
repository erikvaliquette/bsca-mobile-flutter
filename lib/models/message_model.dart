import 'dart:convert';

class MessageModel {
  final String id;
  final String? senderId;
  final String? recipientId; // Changed from receiverId to match DB schema
  final String? roomId;
  final String content;
  final String? topic;
  final String? extension;
  final Map<String, dynamic>? payload;
  final bool? read;
  final String? event;
  final DateTime? createdAt;
  final bool? isPrivate;
  final DateTime? updatedAt;
  final String? userId;
  final String? fileUrl;
  final String? fileType;
  final String? fileName;
  final String? status;
  final DateTime? readAt;
  
  // UI-specific fields not in the database
  final String? senderName;
  final String? senderAvatarUrl;

  MessageModel({
    required this.id,
    this.senderId,
    this.recipientId,
    this.roomId,
    required this.content,
    this.topic,
    this.extension,
    this.payload,
    this.read,
    this.event,
    this.createdAt,
    this.isPrivate,
    this.updatedAt,
    this.userId,
    this.fileUrl,
    this.fileType,
    this.fileName,
    this.status,
    this.readAt,
    this.senderName,
    this.senderAvatarUrl,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      senderId: json['sender_id'],
      recipientId: json['recipient_id'],
      roomId: json['room_id'],
      content: json['content'],
      topic: json['topic'],
      extension: json['extension'],
      payload: json['payload'] != null ? 
              (json['payload'] is String ? jsonDecode(json['payload']) : json['payload']) : 
              null,
      read: json['read'],
      event: json['event'],
      createdAt: json['created_at'] != null ? 
                (json['created_at'] is String ? 
                  DateTime.parse(json['created_at']) : 
                  json['created_at']) : 
                null,
      // Skip the 'private' field entirely to avoid UUID conversion errors
      isPrivate: null,
      updatedAt: json['updated_at'] != null ? 
                (json['updated_at'] is String ? 
                  DateTime.parse(json['updated_at']) : 
                  json['updated_at']) : 
                null,
      userId: json['user_id'],
      fileUrl: json['file_url'],
      fileType: json['file_type'],
      fileName: json['file_name'],
      status: json['status'],
      readAt: json['read_at'] != null ? 
              (json['read_at'] is String ? 
                DateTime.parse(json['read_at']) : 
                json['read_at']) : 
              null,
      senderName: json['sender_name'],
      senderAvatarUrl: json['sender_avatar_url'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      'content': content,
    };

    if (senderId != null) data['sender_id'] = senderId;
    if (recipientId != null) data['recipient_id'] = recipientId;
    if (roomId != null) data['room_id'] = roomId;
    if (topic != null) data['topic'] = topic;
    if (extension != null) data['extension'] = extension;
    if (payload != null) data['payload'] = jsonEncode(payload);
    if (read != null) data['read'] = read;
    if (event != null) data['event'] = event;
    if (createdAt != null) data['created_at'] = createdAt!.toIso8601String();
    // Skip the 'private' field entirely to avoid UUID conversion errors
    // if (isPrivate != null) data['private'] = isPrivate == true;
    if (updatedAt != null) data['updated_at'] = updatedAt!.toIso8601String();
    if (userId != null) data['user_id'] = userId;
    if (fileUrl != null) data['file_url'] = fileUrl;
    if (fileType != null) data['file_type'] = fileType;
    if (fileName != null) data['file_name'] = fileName;
    if (status != null) data['status'] = status;
    if (readAt != null) data['read_at'] = readAt!.toIso8601String();
    if (senderName != null) data['sender_name'] = senderName;
    if (senderAvatarUrl != null) data['sender_avatar_url'] = senderAvatarUrl;

    return data;
  }
}
