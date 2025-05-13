import "../models/user.dart";
import "../models/application.dart";

class Review {
  final int id;
  final String comment;
  final int applicationId;
  final int recruiterId;
  final DateTime createdAt;
  final Application? application;
  final User? recruiter;

  Review({
    required this.id,
    required this.comment,
    required this.applicationId,
    required this.recruiterId,
    required this.createdAt,
    this.application,
    this.recruiter,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      comment: json['comment'],
      applicationId: json['applicationId'],
      recruiterId: json['recruiterId'],
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
      application:
          json['application'] != null
              ? Application.fromJson(json['application'])
              : null,
      recruiter:
          json['recruiter'] != null ? User.fromJson(json['recruiter']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'comment': comment,
      'applicationId': applicationId,
      'recruiterId': recruiterId,
      'createdAt': createdAt.toIso8601String(),
      'application': application?.toJson(),
      'recruiter': recruiter?.toJson(),
    };
  }
}
