import "../models/user.dart";
import "../models/resume.dart";

class Review {
  final int id;
  final String comment;
  final int resumeId;
  final int reviewerId;
  final DateTime createdAt;
  final Resume? resume;
  final User? reviewer;

  Review({
    required this.id,
    required this.comment,
    required this.resumeId,
    required this.reviewerId,
    required this.createdAt,
    this.resume,
    this.reviewer,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      comment: json['comment'],
      resumeId: json['resumeId'],
      reviewerId: json['reviewerId'],
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
      resume: json['resume'] != null ? Resume.fromJson(json['resume']) : null,
      reviewer:
          json['reviewer'] != null ? User.fromJson(json['reviewer']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'comment': comment,
      'resumeId': resumeId,
      'reviewerId': reviewerId,
      'createdAt': createdAt.toIso8601String(),
      'resume': resume?.toJson(),
      'reviewer': reviewer?.toJson(),
    };
  }
}
