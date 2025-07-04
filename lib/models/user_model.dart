class UserModel {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phoneNumber; 
  final String? studentId;  
  final String? district;
  final String? village;
  final String? physicalAddress;
  final String? postalAddress;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phoneNumber,
    this.studentId,
    this.district,
    this.village,
    this.physicalAddress,
    this.postalAddress,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'], 
      studentId: json['student_id'],   
      district: json['district'],
      village: json['village'],
      physicalAddress: json['physical_address'],
      postalAddress: json['postal_address'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone_number': phoneNumber,
      'student_id': studentId,
      'district': district,
      'village': village,
      'physical_address': physicalAddress,
      'postal_address': postalAddress,
    };
  }
}