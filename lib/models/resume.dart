import '../models/user.dart';
import '../models/application.dart';
import '../models/review.dart';
import '../models/analysis.dart';

class Resume {
  final int id;
  final String filePath;
  final String? title;
  final int ownerId;
  final DateTime createdAt;
  final List<Analysis>? analyses;
  final List<Application>? applications;
  final User? owner;
  final List<Review>? reviews;

  Resume({
    required this.id,
    required this.filePath,
    this.title,
    required this.ownerId,
    required this.createdAt,
    this.analyses,
    this.applications,
    this.owner,
    this.reviews,
  });

  factory Resume.fromJson(Map<String, dynamic> json) {
    return Resume(
      id: json['id'] ?? 0, // Handle null or missing id
      filePath:
          json['filePath'] ?? '', // Default empty string if filePath is null
      title: json['title'] ?? '', // Default empty string if title is null
      ownerId: json['ownerId'] ?? 0, // Handle null or missing ownerId
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(), // Handle null createdAt
      analyses:
          (json['analyses'] as List?)
              ?.where((e) => e != null)
              .map((a) => Analysis.fromJson(a))
              .toList() ??
          [], // Default to an empty list if 'analyses' is null
      applications:
          (json['applications'] as List?)
              ?.where((e) => e != null)
              .map((a) => Application.fromJson(a))
              .toList() ??
          [], // Default to an empty list if 'applications' is null
      owner:
          json['owner'] != null
              ? User.fromJson(json['owner'])
              : null, // Handle null owner
      reviews:
          (json['reviews'] as List?)
              ?.where((e) => e != null)
              .map((r) => Review.fromJson(r))
              .toList() ??
          [], // Default to an empty list if 'reviews' is null
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filePath': filePath,
      'title': title,
      'ownerId': ownerId,
      'createdAt': createdAt.toIso8601String(),
      'analyses': analyses?.map((a) => a.toJson()).toList(),
      'applications': applications?.map((a) => a.toJson()).toList(),
      'owner': owner?.toJson(),
      'reviews': reviews?.map((r) => r.toJson()).toList(),
    };
  }
}
