import 'package:flutter/material.dart'; 

class NotificationModel {
  final int id;
  final String title;
  final String message;
  final DateTime timestamp;
  String status; 

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.status = 'unread', 
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      title: json['title'] ?? 'No Title',
      message: json['message'] ?? 'No Message',
      // Assuming 'created_at' or a similar field for the timestamp
      // Adjust if your API sends a different key for the timestamp.
      timestamp: DateTime.parse(json['created_at']),
      status: json['status'] ?? 'unread', // Parse the status from JSON
    );
  }

  // Optional: Add a method to mark as read if you want
  void markAsRead() {
    status = 'read';
  }
}