class AuthUser {
  final String id;
  final String email;
  final String name;
  final String role;
  final String token;
  final String? refreshToken;

  AuthUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.token,
    this.refreshToken,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json, String token) {
    final user = json['user'] as Map<String, dynamic>? ?? json;
    return AuthUser(
      id: user['id'] ?? '',
      email: user['email'] ?? '',
      name: user['name'] ?? '',
      role: user['role'] ?? '',
      token: token,
      refreshToken: json['refreshToken'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'role': role,
        'token': token,
        if (refreshToken != null) 'refreshToken': refreshToken,
      };
}
