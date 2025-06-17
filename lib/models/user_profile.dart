class UserProfile {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phoneNumber;
  final String? staffId;
  final String role;

  UserProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phoneNumber,
    this.staffId,
    required this.role,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'],
      staffId: json['staff_id'],
      role: json['role'] ?? 'user',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phoneNumber,
      'user_id': staffId,
     
    };
  }
}