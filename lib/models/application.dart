// lib/models/application.dart
import "package:intl/intl.dart";
import "user.dart";
import "job.dart";
import "resume.dart";
import "analysis.dart";

enum ApplicationStatus { APPLIED, REVIEWED, ACCEPTED, REJECTED }

class Application {
  final int id;
  final String resumeUrl;
  final int jobId;
  final int applicantId;
  final int? analysisId;
  final String status;
  final DateTime createdAt;
  final Resume? resume;
  final Job? job;
  final User? applicant;
  final Analysis? analysis;
  final String? coverLetter;

  Application({
    required this.id,
    required this.resumeUrl,
    required this.jobId,
    required this.applicantId,
    this.analysisId,
    required this.status,
    required this.createdAt,
    this.resume,
    this.job,
    this.applicant,
    this.analysis,
    this.coverLetter,
  });

  factory Application.fromJson(Map<String, dynamic> json) {
    return Application(
      id: json['id'],
      resumeUrl: json['resume_url'] ?? json['resumeId'].toString(),
      jobId: json['jobId'],
      applicantId: json['applicantId'],
      analysisId: json['analysisId'],
      status: json['status'],
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
      resume: json['resume'] != null ? Resume.fromJson(json['resume']) : null,
      job: json['job'] != null ? Job.fromJson(json['job']) : null,
      applicant:
          json['applicant'] != null ? User.fromJson(json['applicant']) : null,
      analysis:
          json['analysis'] != null ? Analysis.fromJson(json['analysis']) : null,
      coverLetter: json['coverLetter'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'resume_url': resumeUrl,
    'jobId': jobId,
    'applicantId': applicantId,
    'analysisId': analysisId,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
    'resume': resume?.toJson(),
    'job': job?.toJson(),
    'applicant': applicant?.toJson(),
    'analysis': analysis?.toJson(),
    'coverLetter': coverLetter,
  };

  // Computed properties for UI
  String get jobTitle => job?.title ?? 'N/A';
  String get jobLocation => job?.location ?? 'N/A';
  String get formattedDate => DateFormat('MMM d, yyyy').format(createdAt);

  bool get isPending => status == 'APPLIED';
  bool get isReviewed => status == 'REVIEWED';
  bool get isAccepted => status == 'ACCEPTED';
  bool get isRejected => status == 'REJECTED';

  String get statusLabel {
    switch (status) {
      case 'APPLIED':
        return 'Pending';
      case 'REVIEWED':
        return 'Under Review';
      case 'ACCEPTED':
        return 'Accepted';
      case 'REJECTED':
        return 'Rejected';
      default:
        return status;
    }
  }
}
