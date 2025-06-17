class ResourceModel {
  final int id;
  final String name;
  final String location;
  final String? imageUrl;
  final String? description;
  final int? capacity;
  final String? status;
  final String type; 

  ResourceModel({
    required this.id,
    required this.name,
    required this.location,
    this.capacity, 
    this.status, 
    this.imageUrl,
    this.description,
    required this.type, 
  });

  factory ResourceModel.fromJson(Map<String, dynamic> json) {
    return ResourceModel(
      id: json['id'] as int, 
      name: json['name'] as String? ?? 'N/A', 
      location: json['location'] as String? ?? 'N/A', 
      capacity: json['capacity'] as int?, 
      status: json['status'] as String?,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?, 
      type: json['type'] as String? ?? 'Unknown', 
    );
  }

  // Add the fromSearchData factory constructor that your previous code was calling
  factory ResourceModel.fromSearchData(Map<String, dynamic> json) {
      return ResourceModel(
      id: json['id'] as int, 
      name: json['name'] as String,
      location: json['location'] as String? ?? 'N/A',
      capacity: json['capacity'] as int?,
      status: json['status'] as String?,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      type: json['type'] as String? ?? 'Unknown', 
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'capacity': capacity, 
      'status': status,
      'description': description,
      'image_url': imageUrl,
      'type': type, 
    };
  }
}