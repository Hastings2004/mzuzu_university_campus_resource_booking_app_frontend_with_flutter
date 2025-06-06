// lib/models/notification_model.dart
class NotificationModel {
  final int id;
  final String title;
  final String message;
  final DateTime timestamp; // Changed from String to DateTime for easier handling
  final bool read; // Assuming you might have a 'read' status

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.read = false, // Default to false if not provided
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      title: json['title'] ?? 'No Title',
      message: json['message'] ?? 'No Message',
      timestamp: DateTime.parse(json['timestamp']), // Parse the timestamp string
      read: json['read'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(), // Convert to ISO 8601 string for API
      'read': read,
    };
  }
}