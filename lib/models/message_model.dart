// lib/models/message_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String groupId;
  String text;
  final DateTime sentAt;
  bool isRead;
  // deletedForSender: message removed only from sender's view
  bool deletedForSender;
  // deletedForEveryone: message replaced with "deleted" placeholder for both
  bool deletedForEveryone;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.groupId,
    required this.text,
    DateTime? sentAt,
    this.isRead = false,
    this.deletedForSender = false,
    this.deletedForEveryone = false,
  }) : sentAt = sentAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'senderId': senderId,
        'receiverId': receiverId,
        'groupId': groupId,
        'text': text,
        'sentAt': sentAt.toIso8601String(),
        'isRead': isRead,
        'deletedForSender': deletedForSender,
        'deletedForEveryone': deletedForEveryone,
      };

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    // FIX: Firestore returns sentAt as a Timestamp object when using
    // FieldValue.serverTimestamp(). We must handle both Timestamp and String.
    DateTime parsedSentAt;
    final raw = json['sentAt'];
    if (raw == null) {
      parsedSentAt = DateTime.now();
    } else if (raw is Timestamp) {
      parsedSentAt = raw.toDate();
    } else if (raw is String) {
      parsedSentAt = DateTime.parse(raw);
    } else {
      parsedSentAt = DateTime.now();
    }

    return MessageModel(
      id: json['id'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      receiverId: json['receiverId'] as String? ?? '',
      groupId: json['groupId'] as String? ?? '',
      text: json['text'] as String? ?? '',
      sentAt: parsedSentAt,
      isRead: json['isRead'] as bool? ?? false,
      deletedForSender: json['deletedForSender'] as bool? ?? false,
      deletedForEveryone: json['deletedForEveryone'] as bool? ?? false,
    );
  }
}
