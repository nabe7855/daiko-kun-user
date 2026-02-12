class UserModel {
  final String id;
  final String? name;
  final String phoneNumber;
  final String? email;
  final String? socialId;
  final String? socialProvider;
  final String status;

  UserModel({
    required this.id,
    this.name,
    required this.phoneNumber,
    this.email,
    this.socialId,
    this.socialProvider,
    required this.status,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      phoneNumber: json['phone_number'],
      email: json['email'],
      socialId: json['social_id'],
      socialProvider: json['social_provider'],
      status: json['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone_number': phoneNumber,
      'email': email,
      'social_id': socialId,
      'social_provider': socialProvider,
      'status': status,
    };
  }
}
