import "../models/user.dart";

class Job {
  final int id;
  final String title;
  final String description;
  final String company;
  final String? location;
  final List<String>? tags;
  final int recruiterId;
  final DateTime createdAt;
  final User? recruiter;

  Job({
    required this.id,
    required this.title,
    required this.description,
    required this.company,
    this.location,
    this.tags,
    required this.recruiterId,
    required this.createdAt,
    this.recruiter,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      company: json['company'],
      location: json['location'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      recruiterId: json['recruiterId'],
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
      recruiter:
          json['recruiter'] != null ? User.fromJson(json['recruiter']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'company': company,
      'location': location,
      'tags': tags,
      'recruiterId': recruiterId,
      'createdAt': createdAt.toIso8601String(),
      'recruiter': recruiter?.toJson(),
    };
  }
}
