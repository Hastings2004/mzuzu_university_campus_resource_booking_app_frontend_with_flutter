// lib/models/resource_model.dart
class ResourceModel {
  final int id; // Assuming integer ID from Laravel
  final String name;
  final String location;
  final String? imageUrl; // Changed from 'photoUrl' to 'imageUrl' for clarity with API
  final String? description; 
  final int? capacity; 
  final String? status; // Optional field, can be null

  ResourceModel({
    required this.id,
    required this.name,
    required this.location,
    required this.capacity,
    required this.status, // Changed from 'photoUrl' to 'imageUrl' for clarity with API
    this.imageUrl,
    this.description, 
  });

  factory ResourceModel.fromJson(Map<String, dynamic> json) {
    return ResourceModel(
      id: json['id'],
      name: json['name'] ?? 'N/A',
      location: json['location'] ?? 'N/A',
      capacity: json['capacity'] ?? '0',
      status: json['status'] , // Default to 'available' if not provided 
      description: json['description'], // Optional field, can be null
      imageUrl: json['image_url'] ?? '',  // Match your API's key for image
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'capacity': capacity ?? '0', 
      'status': status , // Default to 'available' if not provided
      'description': description, 
      'image_url': imageUrl,
    };
  }
}