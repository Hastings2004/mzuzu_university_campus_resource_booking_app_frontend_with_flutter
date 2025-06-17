class NotificationModel {
  final int id;
  final String title;
  final String message;
  final DateTime timestamp; 
  final bool read; 

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.read = false, 
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      title: json['title'] ?? 'No Title',
      message: json['message'] ?? 'No Message',
      timestamp: DateTime.parse(json['timestamp']), 
      read: json['read'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(), 
      'read': read,
    };
  }
}