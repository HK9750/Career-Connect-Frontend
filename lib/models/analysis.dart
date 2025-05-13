import "../models/user.dart";
import "../models/job.dart";
import "../models/resume.dart";
import "dart:convert";

class Analysis {
  final int id;
  final int resumeId;
  final int? jobId;
  final String? jdText;
  final double? score;
  final String feedback; // Raw JSON string
  final int applicantId;
  final DateTime createdAt;
  final Resume? resume;
  final Job? job;
  final User? applicant;

  Analysis({
    required this.id,
    required this.resumeId,
    this.jobId,
    this.jdText,
    this.score,
    required this.feedback,
    required this.applicantId,
    required this.createdAt,
    this.resume,
    this.job,
    this.applicant,
  });

  factory Analysis.fromJson(Map<String, dynamic> json) {
    return Analysis(
      id: json['id'],
      resumeId: json['resumeId'],
      jobId: json['jobId'],
      jdText: json['jdText'],
      score: json['score'] != null ? json['score'].toDouble() : null,
      feedback: json['feedback'],
      applicantId: json['applicantId'],
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
      resume: json['resume'] != null ? Resume.fromJson(json['resume']) : null,
      job: json['job'] != null ? Job.fromJson(json['job']) : null,
      applicant:
          json['applicant'] != null ? User.fromJson(json['applicant']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'resumeId': resumeId,
      'jobId': jobId,
      'jdText': jdText,
      'score': score,
      'feedback': feedback,
      'applicantId': applicantId,
      'createdAt': createdAt.toIso8601String(),
      'resume': resume?.toJson(),
      'job': job?.toJson(),
      'applicant': applicant?.toJson(),
    };
  }

  // Parse the feedback JSON string into a Map
  Map<String, dynamic>? parsedFeedback() {
    if (feedback == null || feedback!.isEmpty) return null;
    try {
      return jsonDecode(feedback!) as Map<String, dynamic>;
    } catch (e) {
      print('Error parsing feedback JSON: $e');
      return null;
    }
  }
}
