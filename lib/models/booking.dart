// lib/models/booking.dart

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class Booking {
  final int id;
  final int userId;
  final int resourceId;
  final DateTime startTime;
  final DateTime endTime;
  final String purpose;
  final String status;

  // Make these fields nullable
  final String resourceName;
  final String resourceLocation;
  final String? resourceDescription; // Make nullable
  final int? resourceCapacity;       // Make nullable
  final String? resourceType;         // Make nullable

  Booking({
    required this.id,
    required this.userId,
    required this.resourceId,
    required this.startTime,
    required this.endTime,
    required this.purpose,
    required this.status,
    required this.resourceName,
    required this.resourceLocation,
    this.resourceDescription, // No 'required' keyword for nullable fields
    this.resourceCapacity,    // No 'required' keyword for nullable fields
    this.resourceType,        // No 'required' keyword for nullable fields
  });

  // Add a copyWith method to easily create a new Booking instance with updated values
  Booking copyWith({
    int? id,
    int? userId,
    int? resourceId,
    DateTime? startTime,
    DateTime? endTime,
    String? purpose,
    String? status,
    String? resourceName,
    String? resourceLocation,
    String? resourceDescription,
    int? resourceCapacity,
    String? resourceType,
  }) {
    return Booking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      resourceId: resourceId ?? this.resourceId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      purpose: purpose ?? this.purpose,
      status: status ?? this.status,
      resourceName: resourceName ?? this.resourceName,
      resourceLocation: resourceLocation ?? this.resourceLocation,
      resourceDescription: resourceDescription ?? this.resourceDescription,
      resourceCapacity: resourceCapacity ?? this.resourceCapacity,
      resourceType: resourceType ?? this.resourceType,
    );
  }


  factory Booking.fromJson(Map<String, dynamic> json) {
    // Access the nested 'resource' object
    final Map<String, dynamic>? resource = json['resource'];

    return Booking(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      resourceId: json['resource_id'] as int,
      // Ensure date strings are parsed correctly, handling potential nulls from backend if dates are optional
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      purpose: json['purpose'] as String,
      status: json['status'] as String,

      // Parse resource details from the nested 'resource' object
      // Use null-aware operators (?.) and null-coalescing (??) for safety
      // Ensure resourceName and resourceLocation are *always* non-null strings
      resourceName: resource?['name'] as String? ?? 'Unknown Resource',
      resourceLocation: resource?['location'] as String? ?? 'Unknown Location',
      resourceDescription: resource?['description'] as String?, // This will be null if not present in JSON
      resourceCapacity: resource?['capacity'] is int // Check if it's an int
          ? resource!['capacity'] as int
          : (resource?['capacity'] is String // Or if it's a string that can be parsed to an int
              ? int.tryParse(resource!['capacity'] as String)
              : null), // Otherwise, null
      resourceType: resource?['type'] as String?,
    );
  }
}