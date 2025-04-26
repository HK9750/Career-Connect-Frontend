import 'dart:convert';

enum Role { CANDIDATE, RECRUITER }

class User {
  final int id;
  final String username;
  final String email;
  final String role;
  final String token;
  final DateTime createdAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    required this.token,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json, {String? token}) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      role: json['role'],
      token: token ?? '',
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
    );
  }

  factory User.fromStorage(String data) {
    final Map<String, dynamic> json = jsonDecode(data);
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      role: json['role'],
      token: json['token'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  String toStorage() {
    return jsonEncode({
      'id': id,
      'username': username,
      'email': email,
      'role': role,
      'token': token,
    });
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
