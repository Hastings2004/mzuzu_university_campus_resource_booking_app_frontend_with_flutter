class UserProfile {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phoneNumber;
  final String? userType;
  final String role;
  final String? identityNumber;
  final String? district;
  final String? village;
  final String? physicalAddress;
  final String? postalAddress;
  UserProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phoneNumber,
    this.userType,
    required this.role,
    this.identityNumber,
    this.district,
    this.village,
    this.physicalAddress,
    this.postalAddress,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'],
      userType: json['user_type'],
      role: json['role'] ?? 'user',
      identityNumber: json['identity_number'],
      district: json['district'],
      village: json['village'],
      physicalAddress: json['physical_address'],
      postalAddress: json['postal_address'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phoneNumber,
      'user_type': userType,
      'identity_number': identityNumber,
      'district': district,
      'village': village,
      'physical_address': physicalAddress,
      'postal_address': postalAddress,
    };
  }
}