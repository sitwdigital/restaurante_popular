import 'package:flutter/material.dart';

class AppNotification {
  final String id;          // único
  final String title;
  final String message;
  final DateTime createdAt;
  final String type;        // ex.: 'unidade_adicionada'
  bool read;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    this.type = 'generic',
    this.read = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'message': message,
        'createdAt': createdAt.toIso8601String(),
        'type': type,
        'read': read,
      };

  factory AppNotification.fromMap(Map m) => AppNotification(
        id: (m['id'] ?? '').toString(),
        title: (m['title'] ?? '').toString(),
        message: (m['message'] ?? '').toString(),
        createdAt: DateTime.tryParse((m['createdAt'] ?? '').toString()) ?? DateTime.now(),
        type: (m['type'] ?? 'generic').toString(),
        read: m['read'] == true,
      );
}
