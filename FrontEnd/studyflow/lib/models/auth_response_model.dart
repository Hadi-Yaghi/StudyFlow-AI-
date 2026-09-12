class AuthResponseModel {
  final String token;
  final int userId;
  final String name;
  final String email;
  final String? major;
  final bool emailVerified;

  AuthResponseModel({
    required this.token,
    required this.userId,
    required this.name,
    required this.email,
    this.major,
    this.emailVerified = true,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      token: json['token']?.toString() ?? '',
      userId: json['userId'] is int
          ? json['userId']
          : (int.tryParse(json['userId']?.toString() ?? '0') ?? 0),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      major: json['major']?.toString(),
      emailVerified: json['emailVerified'] is bool
          ? json['emailVerified']
          : (json['emailVerified']?.toString() == 'true'),
    );
  }
}
