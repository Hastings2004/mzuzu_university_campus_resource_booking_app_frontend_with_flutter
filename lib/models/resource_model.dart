class ResourceModel {
  final int id;
  final String name;
  final String location;
  final String? imageUrl;
  final String? description;
  final int? capacity;
  final String? status;
  final String type; // Assuming 'type' is a required field based on your search logic

  ResourceModel({
    required this.id,
    required this.name,
    required this.location,
    this.capacity, // Made capacity nullable in constructor as well
    this.status, // Made status nullable in constructor as well
    this.imageUrl,
    this.description,
    required this.type, // Added type to the constructor
  });

  factory ResourceModel.fromJson(Map<String, dynamic> json) {
    return ResourceModel(
      id: json['id'] as int, // Ensure 'id' is cast to int
      name: json['name'] as String? ?? 'N/A', // Cast to String? then null check
      location: json['location'] as String? ?? 'N/A', // Cast to String? then null check
      capacity: json['capacity'] as int?, // Correct: default is null, or cast to int?
      status: json['status'] as String?, // Cast to String?
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?, // Cast to String?
      type: json['type'] as String? ?? 'Unknown', // Assume 'type' exists and needs handling
    );
  }

  // Add the fromSearchData factory constructor that your previous code was calling
  factory ResourceModel.fromSearchData(Map<String, dynamic> json) {
    // This constructor needs to correctly map the data from your search API response.
    // Adjust the keys and types according to what your global search API returns.
    // Assuming the search results for resources have similar keys to your main resource fetch.
    return ResourceModel(
      id: json['id'] as int, // Or json['_id'] if that's what your search returns
      name: json['name'] as String,
      location: json['location'] as String? ?? 'N/A',
      capacity: json['capacity'] as int?,
      status: json['status'] as String?,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      type: json['type'] as String? ?? 'Unknown', // Ensure 'type' is handled
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'capacity': capacity, // No need for ?? '0' here if capacity is nullable int
      'status': status,
      'description': description,
      'image_url': imageUrl,
      'type': type, // Add type to toJson
    };
  }
}