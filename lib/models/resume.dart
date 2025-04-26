import "../models/user.dart";

class Resume {
  final int id;
  final String filePath;
  final int ownerId;
  final DateTime createdAt;
  final User? owner;

  Resume({
    required this.id,
    required this.filePath,
    required this.ownerId,
    required this.createdAt,
    this.owner,
  });

  factory Resume.fromJson(Map<String, dynamic> json) {
    return Resume(
      id: json['id'],
      filePath: json['filePath'],
      ownerId: json['ownerId'],
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
      owner: json['owner'] != null ? User.fromJson(json['owner']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filePath': filePath,
      'ownerId': ownerId,
      'createdAt': createdAt.toIso8601String(),
      'owner': owner?.toJson(),
    };
  }

  Resume copyWith({
    int? id,
    String? filePath,
    int? ownerId,
    DateTime? createdAt,
    User? owner,
  }) {
    return Resume(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
      owner: owner ?? this.owner,
    );
  }
}
