import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart';
import '../utils/routes.dart';
import '../models/user.dart';
import '../models/resume.dart';
import '../models/job.dart';
import '../models/review.dart';
import '../models/application.dart';

class ApiService {
  String? token;

  Map<String, String> _headers() {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> _handleResponse(http.Response response) async {
    try {
      final data = json.decode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      } else {
        final errorMessage = data['message'] ?? 'Server error occurred';
        throw ApiException(errorMessage, response.statusCode, data);
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      } else if (e is FormatException) {
        throw ApiException('Invalid response format', response.statusCode);
      } else {
        throw ApiException('Network error occurred', response.statusCode);
      }
    }
  }

  // AUTH METHODS
  Future<User> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiRoutes.login),
        headers: _headers(),
        body: json.encode({'email': email, 'password': password}),
      );
      final data = await _handleResponse(response);
      token = data['accessToken'];
      return User.fromJson(data['user'], token: data['accessToken']);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Login failed: $e', 500);
    }
  }

  Future<User> register(
    String username,
    String email,
    String password,
    String role,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(ApiRoutes.register),
        headers: _headers(),
        body: json.encode({
          'username': username,
          'email': email,
          'password': password,
          'role': role,
        }),
      );
      final data = await _handleResponse(response);
      token = data['accessToken'];
      return User.fromJson(data['user'], token: data['accessToken']);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Registration failed: $e', 500);
    }
  }

  // RESUME METHODS
  Future<List<Resume>> fetchResumes() async {
    try {
      final response = await http.get(
        Uri.parse(ApiRoutes.listResumes),
        headers: _headers(),
      );
      final data = await _handleResponse(response);
      return (data['resumes'] as List)
          .map((json) => Resume.fromJson(json))
          .toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Failed to load resumes: $e', 500);
    }
  }

  Future<List<Resume>> fetchResumesByUser() async {
    try {
      final response = await http.get(
        Uri.parse(ApiRoutes.getResumesByUser),
        headers: _headers(),
      );
      final data = await _handleResponse(response);
      return (data['resumes'] as List)
          .map((json) => Resume.fromJson(json))
          .toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Failed to load user resumes: $e', 500);
    }
  }

  Future<List<Resume>> fetchResumesByRecruiter() async {
    try {
      final response = await http.get(
        Uri.parse(ApiRoutes.getResumesByRecruiter),
        headers: _headers(),
      );
      final data = await _handleResponse(response);
      return (data['resumes'] as List)
          .map((json) => Resume.fromJson(json))
          .toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Failed to load recruiter resumes: $e', 500);
    }
  }

  Future<Resume> getResume(String resumeId) async {
    try {
      final uri = Uri.parse(ApiRoutes.getResume.replaceAll('{id}', resumeId));
      final response = await http.get(uri, headers: _headers());
      final data = await _handleResponse(response);
      return Resume.fromJson(data['resume']);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Failed to get resume: $e', 500);
    }
  }

  Future<Resume> uploadResume(String title, File file) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiRoutes.uploadResume),
      );

      // Add auth header
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Add text fields
      request.fields['title'] = title;

      // Determine file type
      final fileExtension = extension(file.path).toLowerCase();
      _validateFileType(fileExtension);
      String contentType = _getContentType(fileExtension);

      // Add file
      request.files.add(
        http.MultipartFile(
          'file',
          file.readAsBytes().asStream(),
          file.lengthSync(),
          filename: basename(file.path),
          contentType: MediaType.parse(contentType),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = await _handleResponse(response);

      return Resume.fromJson(data['resume']);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Failed to upload resume: $e', 500);
    }
  }

  Future<Resume> uploadResumeWeb(
    String title,
    Uint8List bytes,
    String fileName,
  ) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiRoutes.uploadResume),
      );

      // Add auth header
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Add text fields
      request.fields['title'] = title;

      // Determine file type
      final fileExtension = extension(fileName).toLowerCase();
      _validateFileType(fileExtension);
      String contentType = _getContentType(fileExtension);

      // Add file
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
          contentType: MediaType.parse(contentType),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = await _handleResponse(response);

      return Resume.fromJson(data['resume']);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Failed to upload resume: $e', 500);
    }
  }

  Future<String> downloadResume(String resumeId) async {
    try {
      final uri = Uri.parse(
        ApiRoutes.downloadResume.replaceAll('{id}', resumeId),
      );
      final response = await http.get(uri, headers: _headers());
      final data = await _handleResponse(response);
      return data['url'];
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Failed to download resume: $e', 500);
    }
  }

  Future<Resume> updateResume(
    String resumeId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      final uri = Uri.parse(
        ApiRoutes.updateResume.replaceAll('{id}', resumeId),
      );
      final response = await http.put(
        uri,
        headers: _headers(),
        body: json.encode(updateData),
      );
      final data = await _handleResponse(response);
      return Resume.fromJson(data['resume']);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Failed to update resume: $e', 500);
    }
  }

  Future<Resume> deleteResume(String resumeId) async {
    try {
      final uri = Uri.parse(
        ApiRoutes.deleteResume.replaceAll('{id}', resumeId),
      );
      final response = await http.delete(uri, headers: _headers());
      final data = await _handleResponse(response);
      return Resume.fromJson(data['resume']);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Failed to delete resume: $e', 500);
    }
  }

  // ANALYSIS METHODS
  Future<Map<String, dynamic>> analyzeResume(String resumeId) async {
    try {
      final uri = Uri.parse(
        ApiRoutes.analyze.replaceAll('{resumeId}', resumeId),
      );
      final response = await http.post(uri, headers: _headers());
      return await _handleResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Failed to analyze resume: $e', 500);
    }
  }

  // JOB METHODS
  Future<List<Job>> fetchJobs() async {
    try {
      final response = await http.get(
        Uri.parse(ApiRoutes.listJobs),
        headers: _headers(),
      );
      final data = await _handleResponse(response);
      return (data['jobs'] as List).map((json) => Job.fromJson(json)).toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Failed to load jobs: $e', 500);
    }
  }

  Future<Job> getJob(String jobId) async {
    try {
      final uri = Uri.parse(ApiRoutes.jobDetail.replaceAll('{id}', jobId));
      final response = await http.get(uri, headers: _headers());
      final data = await _handleResponse(response);
      return Job.fromJson(data['job']);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Failed to get job details: $e', 500);
    }
  }

  Future<Job> createJob(
    String title,
    String description,
    String company,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(ApiRoutes.createJob),
        headers: _headers(),
        body: json.encode({
          'title': title,
          'description': description,
          'company': company,
        }),
      );
      final data = await _handleResponse(response);
      return Job.fromJson(data['job']);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Failed to create job: $e', 500);
    }
  }

  Future<Job> updateJob(String jobId, Map<String, dynamic> updateData) async {
    try {
      final uri = Uri.parse(ApiRoutes.updateJob.replaceAll('{id}', jobId));
      final response = await http.put(
        uri,
        headers: _headers(),
        body: json.encode(updateData),
      );
      final data = await _handleResponse(response);
      return Job.fromJson(data['job']);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Failed to update job: $e', 500);
    }
  }

  Future<Job> deleteJob(String jobId) async {
    try {
      final uri = Uri.parse(ApiRoutes.deleteJob.replaceAll('{id}', jobId));
      final response = await http.delete(uri, headers: _headers());
      final data = await _handleResponse(response);
      return Job.fromJson(data['job']);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Failed to delete job: $e', 500);
    }
  }

  // REVIEW METHODS
  Future<Review> submitReview(String resumeId, String comment) async {
    try {
      final uri = Uri.parse(
        ApiRoutes.submitReview.replaceAll('{resumeId}', resumeId),
      );
      final response = await http.post(
        uri,
        headers: _headers(),
        body: json.encode({'comment': comment}),
      );
      final data = await _handleResponse(response);
      return Review.fromJson(data['review']);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Failed to submit review: $e', 500);
    }
  }

  Future<List<Review>> fetchReviews(String resumeId) async {
    try {
      final uri = Uri.parse(
        ApiRoutes.listReviews.replaceAll('{resumeId}', resumeId),
      );
      final response = await http.get(uri, headers: _headers());
      final data = await _handleResponse(response);
      return (data['reviews'] as List)
          .map((json) => Review.fromJson(json))
          .toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Failed to load reviews: $e', 500);
    }
  }

  Future<Review> deleteReview(String reviewId) async {
    try {
      final uri = Uri.parse(
        ApiRoutes.deleteReview.replaceAll('{reviewId}', reviewId),
      );
      final response = await http.delete(uri, headers: _headers());
      final data = await _handleResponse(response);
      return Review.fromJson(data['review']);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Failed to delete review: $e', 500);
    }
  }

  Future<List<Review>> fetchAllReviews() async {
    try {
      final response = await http.get(
        Uri.parse(ApiRoutes.review),
        headers: _headers(),
      );
      final data = await _handleResponse(response);
      return (data['reviews'] as List)
          .map((json) => Review.fromJson(json))
          .toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Failed to load all reviews: $e', 500);
    }
  }

  // UTILITY METHODS
  void _validateFileType(String fileExtension) {
    if (fileExtension != '.pdf' && fileExtension != '.docx') {
      throw UnsupportedFileTypeException(
        'Unsupported file format. Only PDF and DOCX are supported.',
      );
    }
  }

  String _getContentType(String fileExtension) {
    if (fileExtension == '.pdf') {
      return 'application/pdf';
    } else if (fileExtension == '.docx') {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    // This should never happen due to validation above
    throw UnsupportedFileTypeException('Unsupported file format.');
  }

  // APPLICATION METHODS
  Future<Application> applyForJob(String jobId) async {
    try {
      final uri = Uri.parse(ApiRoutes.applyForJob.replaceAll('{jobId}', jobId));
      final response = await http.post(uri, headers: _headers());
      final data = await _handleResponse(response);
      return Application.fromJson(data['application']);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Failed to apply for job: $e', 500);
    }
  }

  Future<Application> getApplication(String applicationId) async {
    try {
      final uri = Uri.parse(
        ApiRoutes.getApplication.replaceAll('{applicationId}', applicationId),
      );
      final response = await http.get(uri, headers: _headers());
      final data = await _handleResponse(response);
      return Application.fromJson(data['application']);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Failed to get application details: $e', 500);
    }
  }

  Future<List<Application>> listApplicationsByApplicant() async {
    try {
      final response = await http.get(
        Uri.parse(ApiRoutes.listByApplicant),
        headers: _headers(),
      );
      final data = await _handleResponse(response);
      return (data['applications'] as List)
          .map((json) => Application.fromJson(json))
          .toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Failed to load your applications: $e', 500);
    }
  }

  Future<List<Application>> listApplicationsByRecruiter() async {
    try {
      final response = await http.get(
        Uri.parse(ApiRoutes.listByRecruiter),
        headers: _headers(),
      );
      final data = await _handleResponse(response);
      return (data['applications'] as List)
          .map((json) => Application.fromJson(json))
          .toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Failed to load applications: $e', 500);
    }
  }

  Future<Application> updateApplicationStatus(
    String applicationId,
    String status,
  ) async {
    try {
      // Validate status
      final validStatuses = ['APPLIED', 'REVIEWED', 'ACCEPTED', 'REJECTED'];
      if (!validStatuses.contains(status)) {
        throw ApiException(
          'Invalid status. Must be one of: ${validStatuses.join(', ')}',
          400,
        );
      }

      final uri = Uri.parse(
        ApiRoutes.updateApplicationStatus.replaceAll(
          '{applicationId}',
          applicationId,
        ),
      );
      final response = await http.put(
        uri,
        headers: _headers(),
        body: json.encode({'status': status}),
      );
      final data = await _handleResponse(response);
      return Application.fromJson(data['application']);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Failed to update application status: $e', 500);
    }
  }

  Future<Map<String, dynamic>> deleteApplication(String applicationId) async {
    try {
      final uri = Uri.parse(
        ApiRoutes.deleteApplication.replaceAll(
          '{applicationId}',
          applicationId,
        ),
      );
      final response = await http.delete(uri, headers: _headers());
      return await _handleResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Failed to cancel application: $e', 500);
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  final dynamic data;

  ApiException(this.message, this.statusCode, [this.data]);

  @override
  String toString() => 'ApiException: $message (Status Code: $statusCode)';
}

class UnsupportedFileTypeException implements Exception {
  final String message;

  UnsupportedFileTypeException(this.message);

  @override
  String toString() => 'UnsupportedFileTypeException: $message';
}
