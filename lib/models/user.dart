import 'dart:convert';

enum Role { CANDIDATE, RECRUITER }

class User {
  final int id;
  final String username;
  final String email;
  final String role;
  final String accessToken;
  final String refreshToken;
  final DateTime createdAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    required this.accessToken,
    required this.refreshToken,
    required this.createdAt,
  });

  factory User.fromJson(
    Map<String, dynamic> json, {
    String? accessToken,
    String? refreshToken,
  }) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      role: json['role'],
      accessToken: accessToken ?? json['accessToken'] ?? '',
      refreshToken: refreshToken ?? json['refreshToken'] ?? '',
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
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  String toStorage() {
    return jsonEncode({
      'id': id,
      'username': username,
      'email': email,
      'role': role,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'createdAt': createdAt.toIso8601String(),
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
