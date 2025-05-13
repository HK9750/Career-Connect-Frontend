import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/logger.dart';
import 'package:path/path.dart';
import '../utils/routes.dart';
import '../models/user.dart';
import '../models/resume.dart';
import '../models/job.dart';
import '../models/review.dart';
import '../models/application.dart';

class ApplicationResponse {
  final Application application;
  final int resumeId;

  ApplicationResponse({required this.application, required this.resumeId});
}

class ApiService {
  String? accessToken;
  String? refreshToken;
  bool _isRefreshing = false;

  Future<void> init() async {
    final FlutterSecureStorage storage = const FlutterSecureStorage();
    accessToken = await storage.read(key: 'accessToken');
    refreshToken = await storage.read(key: 'refreshToken');
    print('Access Token from init: $accessToken');
    print('Refresh Token from init: $refreshToken');
  }

  Future<Map<String, String>> _headers() async {
    await init();
    final headers = {
      'Content-Type': 'application/json',
      if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      if (refreshToken != null) 'x-refresh-token': refreshToken!,
    };

    AppLogger.i('API Headers: $headers');

    return headers;
  }

  Future<dynamic> _handleResponse(
    http.Response response, {
    Future<dynamic> Function()? retryFunction,
    bool isRefreshRequest = false,
  }) async {
    try {
      final data = json.decode(response.body);

      // Success
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      }

      // Unauthorized: try refresh + retry
      if (response.statusCode == 401 &&
          !isRefreshRequest &&
          refreshToken != null &&
          retryFunction != null) {
        try {
          // Refresh tokens (throws on failure)
          await refreshAuthToken();
          // Retry original request
          return await retryFunction();
        } catch (_) {
          // If refresh or retry fails, fall through to throwing below
        }
      }

      // Any other error
      final errorMessage = data['message'] ?? 'Server error occurred';
      throw ApiException(errorMessage, response.statusCode, data);
    } catch (e) {
      // Re-throw ApiExceptions
      if (e is ApiException) {
        rethrow;
      }
      // Format error on decode
      if (e is FormatException) {
        throw ApiException('Invalid response format', response.statusCode);
      }
      // Network / unknown
      throw ApiException('Network error occurred', response.statusCode);
    }
  }

  // AUTH METHODS
  Future<User> login(String email, String password) async {
    try {
      AppLogger.i("Login attempt with email: $email and password: $password");
      final response = await http.post(
        Uri.parse(ApiRoutes.login),
        headers: await _headers(),
        body: json.encode({'email': email, 'password': password}),
      );
      final data = await _handleResponse(response);
      accessToken = data['accessToken'];
      refreshToken = data['refreshToken'];

      return User.fromJson(
        data['user'],
        accessToken: data['accessToken'],
        refreshToken: data['refreshToken'],
      );
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
        headers: await _headers(),
        body: json.encode({
          'username': username,
          'email': email,
          'password': password,
          'role': role,
        }),
      );
      final data = await _handleResponse(response);
      accessToken = data['accessToken'];
      refreshToken = data['refreshToken'];
      return User.fromJson(
        data['user'],
        accessToken: data['accessToken'],
        refreshToken: data['refreshToken'],
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Registration failed: $e', 500);
    }
  }

  Future<Map<String, String>> refreshAuthToken([String? token]) async {
    if (_isRefreshing) {
      // Wait until refresh is completed
      await Future.delayed(Duration(milliseconds: 500));
      return {'accessToken': accessToken!, 'refreshToken': refreshToken!};
    }

    _isRefreshing = true;
    try {
      final tokenToUse = token ?? refreshToken;
      if (tokenToUse == null) {
        throw ApiException('No refresh token available', 401);
      }

      final response = await http.post(
        Uri.parse(ApiRoutes.refreshToken),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'refreshToken': tokenToUse}),
      );

      final data = await _handleResponse(response, isRefreshRequest: true);

      accessToken = data['accessToken'];
      refreshToken = data['refreshToken'];

      _isRefreshing = false;
      return {'accessToken': accessToken!, 'refreshToken': refreshToken!};
    } catch (e) {
      _isRefreshing = false;
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Token refresh failed: $e', 500);
    }
  }

  Future<bool> refreshAuthTokenIfNeeded() async {
    try {
      if (refreshToken != null) {
        final tokens = await refreshAuthToken();
        accessToken = tokens['accessToken'];
        refreshToken = tokens['refreshToken'];
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // RESUME METHODS
  Future<List<Resume>> fetchResumes() async {
    try {
      final fetchFunction = () async {
        final response = await http.get(
          Uri.parse(ApiRoutes.listResumes),
          headers: await _headers(),
        );
        final data = await _handleResponse(response);
        return (data['resumes'] as List)
            .map((json) => Resume.fromJson(json))
            .toList();
      };

      final response = await http.get(
        Uri.parse(ApiRoutes.listResumes),
        headers: await _headers(),
      );

      final data = await _handleResponse(
        response,
        retryFunction: fetchFunction,
      );

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
      final fetchFunction = () async {
        final response = await http.get(
          Uri.parse(ApiRoutes.getResumesByUser),
          headers: await _headers(),
        );

        final data = await _handleResponse(response);
        print('Raw API data: $data'); // Debugging the raw response data

        // Add a check to handle cases where 'resumes' might be null or empty
        if (data['resumes'] == null) {
          throw ApiException('No resumes found for the user.', 404);
        }

        return (data['resumes'] as List)
            .map((json) => Resume.fromJson(json))
            .toList();
      };

      final response = await http.get(
        Uri.parse(ApiRoutes.getResumesByUser),
        headers: await _headers(),
      );

      final data = await _handleResponse(
        response,
        retryFunction: fetchFunction,
      );

      print('Raw API data: $data'); // Debugging the raw response data

      // Check for null 'resumes' field
      if (data['resumes'] == null) {
        throw ApiException('No resumes found for the user.', 404);
      }

      return (data['resumes'] as List).map((json) {
        try {
          return Resume.fromJson(json);
        } catch (e, stack) {
          print('Error parsing resume JSON: $json');
          print('Error details: $e\n$stack');
          throw ApiException('Failed to parse resume: $e', 500);
        }
      }).toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      print('Error in fetchResumesByUser: $e');
      throw ApiException('Failed to load user resumes: $e', 500);
    }
  }

  Future<List<Resume>> fetchResumesByRecruiter() async {
    try {
      final fetchFunction = () async {
        final response = await http.get(
          Uri.parse(ApiRoutes.getResumesByRecruiter),
          headers: await _headers(),
        );
        final data = await _handleResponse(response);
        return (data['resumes'] as List)
            .map((json) => Resume.fromJson(json))
            .toList();
      };

      final response = await http.get(
        Uri.parse(ApiRoutes.getResumesByRecruiter),
        headers: await _headers(),
      );

      final data = await _handleResponse(
        response,
        retryFunction: fetchFunction,
      );

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
      final fetchFunction = () async {
        final uri = Uri.parse(ApiRoutes.getResume.replaceAll('{id}', resumeId));
        final response = await http.get(uri, headers: await _headers());
        final data = await _handleResponse(response);
        return Resume.fromJson(data['resume']);
      };

      final uri = Uri.parse(ApiRoutes.getResume.replaceAll('{id}', resumeId));
      final response = await http.get(uri, headers: await _headers());
      final data = await _handleResponse(
        response,
        retryFunction: fetchFunction,
      );

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

      // add your common headers
      request.headers.addAll(await _headers());
      if (accessToken != null) {
        request.headers['Authorization'] = 'Bearer $accessToken';
      }

      // text fields
      request.fields['title'] = title;

      // validate & figure out mime
      final fileExt = extension(file.path).toLowerCase();
      _validateFileType(fileExt);
      final contentType = _getContentType(fileExt);

      // **NOTICE** fieldname is now 'resume'
      request.files.add(
        http.MultipartFile(
          'resume',
          file.readAsBytes().asStream(),
          file.lengthSync(),
          filename: basename(file.path),
          contentType: MediaType.parse(contentType),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // handle 401 retry ...
      if (response.statusCode == 401 && refreshToken != null) {
        final didRefresh = await refreshAuthTokenIfNeeded();
        if (didRefresh) {
          return await uploadResume(title, file);
        }
      }

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
      if (accessToken != null) {
        request.headers['Authorization'] = 'Bearer $accessToken';
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

      // If unauthorized, try to refresh token and retry
      if (response.statusCode == 401 && refreshToken != null) {
        final refreshed = await refreshAuthTokenIfNeeded();
        if (refreshed) {
          return await uploadResumeWeb(title, bytes, fileName);
        }
      }

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
      final fetchFunction = () async {
        final uri = Uri.parse(
          ApiRoutes.downloadResume.replaceAll('{id}', resumeId),
        );
        final response = await http.get(uri, headers: await _headers());
        final data = await _handleResponse(response);
        return data['url'];
      };

      final uri = Uri.parse(
        ApiRoutes.downloadResume.replaceAll('{id}', resumeId),
      );
      final response = await http.get(uri, headers: await _headers());
      final data = await _handleResponse(
        response,
        retryFunction: fetchFunction,
      );

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
      final fetchFunction = () async {
        final uri = Uri.parse(
          ApiRoutes.updateResume.replaceAll('{id}', resumeId),
        );
        final response = await http.put(
          uri,
          headers: await _headers(),
          body: json.encode(updateData),
        );
        final data = await _handleResponse(response);
        return Resume.fromJson(data['resume']);
      };

      final uri = Uri.parse(
        ApiRoutes.updateResume.replaceAll('{id}', resumeId),
      );
      final response = await http.put(
        uri,
        headers: await _headers(),
        body: json.encode(updateData),
      );

      final data = await _handleResponse(
        response,
        retryFunction: fetchFunction,
      );

      return Resume.fromJson(data['resume']);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Failed to update resume: $e', 500);
    }
  }

  Future<Resume> deleteResume(String resumeId) async {
    try {
      final fetchFunction = () async {
        final uri = Uri.parse(
          ApiRoutes.deleteResume.replaceAll('{id}', resumeId),
        );
        final response = await http.delete(uri, headers: await _headers());
        final data = await _handleResponse(response);
        return Resume.fromJson(data['resume']);
      };

      final uri = Uri.parse(
        ApiRoutes.deleteResume.replaceAll('{id}', resumeId),
      );
      final response = await http.delete(uri, headers: await _headers());

      final data = await _handleResponse(
        response,
        retryFunction: fetchFunction,
      );

      return Resume.fromJson(data['resume']);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Failed to delete resume: $e', 500);
    }
  }

  // ANALYSIS METHODS
  Future<Map<String, dynamic>> analyzeResume(
    String resumeId,
    String jobId,
    String applicationId,
  ) async {
    try {
      // define the retry function with body as well
      final fetchFunction = () async {
        final uri = Uri.parse(
          ApiRoutes.analyze.replaceAll('{resumeId}', resumeId),
        );
        final headers = await _headers();
        headers['Content-Type'] = 'application/json';
        final response = await http.post(
          uri,
          headers: headers,
          body: jsonEncode({'jobId': jobId, 'applicationId': applicationId}),
        );
        return await _handleResponse(response);
      };

      final uri = Uri.parse(
        ApiRoutes.analyze.replaceAll('{resumeId}', resumeId),
      );
      final headers = await _headers();
      headers['Content-Type'] = 'application/json';
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode({'jobId': jobId, 'applicationId': applicationId}),
      );

      return await _handleResponse(response, retryFunction: fetchFunction);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Failed to analyze resume: $e', 500);
    }
  }

  // JOB METHODS
  Future<List<Job>> fetchJobs() async {
    try {
      final fetchFunction = () async {
        final response = await http.get(
          Uri.parse(ApiRoutes.listJobs),
          headers: await _headers(),
        );
        final data = await _handleResponse(response);
        return (data['jobs'] as List)
            .map((json) => Job.fromJson(json))
            .toList();
      };

      final response = await http.get(
        Uri.parse(ApiRoutes.listJobs),
        headers: await _headers(),
      );

      final data = await _handleResponse(
        response,
        retryFunction: fetchFunction,
      );

      return (data['jobs'] as List).map((json) => Job.fromJson(json)).toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Failed to load jobs: $e', 500);
    }
  }

  Future<Job> getJob(String jobId) async {
    try {
      final fetchFunction = () async {
        final uri = Uri.parse(ApiRoutes.jobDetail.replaceAll('{id}', jobId));
        final response = await http.get(uri, headers: await _headers());
        final data = await _handleResponse(response);
        return Job.fromJson(data['job']);
      };

      final uri = Uri.parse(ApiRoutes.jobDetail.replaceAll('{id}', jobId));
      final response = await http.get(uri, headers: await _headers());

      final data = await _handleResponse(
        response,
        retryFunction: fetchFunction,
      );

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
    String? location,
    List<String>? tags,
  ) async {
    try {
      final fetchFunction = () async {
        final response = await http.post(
          Uri.parse(ApiRoutes.createJob),
          headers: await _headers(),
          body: json.encode({
            'title': title,
            'description': description,
            'company': company,
            'location': location,
            'tags': tags,
          }),
        );
        final data = await _handleResponse(response);
        return Job.fromJson(data['job']);
      };

      final response = await http.post(
        Uri.parse(ApiRoutes.createJob),
        headers: await _headers(),
        body: json.encode({
          'title': title,
          'description': description,
          'company': company,
          'location': location,
          'tags': tags,
        }),
      );

      final data = await _handleResponse(
        response,
        retryFunction: fetchFunction,
      );

      return Job.fromJson(data['job']);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Failed to create job: $e', 500);
    }
  }

  Future<Job> updateJob(String jobId, Map<String, dynamic> updateData) async {
    try {
      final fetchFunction = () async {
        final uri = Uri.parse(ApiRoutes.updateJob.replaceAll('{id}', jobId));
        final response = await http.put(
          uri,
          headers: await _headers(),
          body: json.encode(updateData),
        );
        final data = await _handleResponse(response);
        return Job.fromJson(data['job']);
      };

      final uri = Uri.parse(ApiRoutes.updateJob.replaceAll('{id}', jobId));
      final response = await http.put(
        uri,
        headers: await _headers(),
        body: json.encode(updateData),
      );

      final data = await _handleResponse(
        response,
        retryFunction: fetchFunction,
      );

      return Job.fromJson(data['job']);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Failed to update job: $e', 500);
    }
  }

  Future<Job> deleteJob(String jobId) async {
    try {
      final fetchFunction = () async {
        final uri = Uri.parse(ApiRoutes.deleteJob.replaceAll('{id}', jobId));
        final response = await http.delete(uri, headers: await _headers());
        final data = await _handleResponse(response);
        return Job.fromJson(data['job']);
      };

      final uri = Uri.parse(ApiRoutes.deleteJob.replaceAll('{id}', jobId));
      final response = await http.delete(uri, headers: await _headers());

      final data = await _handleResponse(
        response,
        retryFunction: fetchFunction,
      );

      return Job.fromJson(data['job']);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Failed to delete job: $e', 500);
    }
  }

  Future<Review> submitReview(String applicationId, String comment) async {
    try {
      final uri = Uri.parse(
        ApiRoutes.submitReview.replaceAll('{applicationId}', applicationId),
      );
      final response = await http.post(
        uri,
        headers: await _headers(),
        body: json.encode({'comment': comment}),
      );
      final body = await _handleResponse(response);
      return Review.fromJson(body['data']);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Failed to submit review: $e', 500);
    }
  }

  Future<Review> updateReview(String applicationId, String comment) async {
    try {
      final uri = Uri.parse(
        ApiRoutes.updateReview.replaceAll('{applicationId}', applicationId),
      );
      final response = await http.put(
        uri,
        headers: await _headers(),
        body: json.encode({'comment': comment}),
      );
      final body = await _handleResponse(response);
      return Review.fromJson(body['data']);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Failed to update review: $e', 500);
    }
  }

  Future<Review> fetchReview(String applicationId) async {
    try {
      final uri = Uri.parse(
        ApiRoutes.getOneReview.replaceAll('{applicationId}', applicationId),
      );

      // Add debug log to see what URL we're requesting
      AppLogger.d('Fetching review from: $uri');

      final response = await http.get(uri, headers: await _headers());

      // Log the raw response
      AppLogger.d('Raw response status: ${response.statusCode}');
      AppLogger.d('Raw response body: ${response.body}');

      final body = await _handleResponse(response);

      // Log the parsed body
      AppLogger.i('Review response parsed body: ${body['data']}');

      // Create review object with more defensive parsing
      return Review.fromJson(body['data']);
    } on ApiException {
      rethrow;
    } catch (e) {
      // More descriptive error message
      AppLogger.e('Error in fetchReview: $e');
      throw ApiException('Failed to load review: $e', 500);
    }
  }

  // Delete a review (only the recruiter who wrote it)
  Future<void> deleteReview(String applicationId) async {
    try {
      final uri = Uri.parse(
        ApiRoutes.deleteOneReview.replaceAll('{applicationId}', applicationId),
      );
      final response = await http.delete(uri, headers: await _headers());
      await _handleResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Failed to delete review: $e', 500);
    }
  }

  // (Optional) Fetch all reviews—e.g. for an admin dashboard
  Future<List<Review>> fetchAllReviews() async {
    try {
      final uri = Uri.parse(ApiRoutes.listAllReview);
      final response = await http.get(uri, headers: await _headers());
      final body = await _handleResponse(response);
      final data =
          (body['data'] as List).map((json) => Review.fromJson(json)).toList();
      AppLogger.i('Fetched all reviews: $data');
      return (body['data'] as List)
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
  Future<ApplicationResponse> applyForJob(String jobId) async {
    try {
      final fetchFunction = () async {
        final uri = Uri.parse(
          ApiRoutes.applyForJob.replaceAll('{jobId}', jobId),
        );
        final response = await http.post(uri, headers: await _headers());
        final data = await _handleResponse(response);
        return ApplicationResponse(
          application: Application.fromJson(data['application']),
          resumeId: data['resumeId'],
        );
      };

      final uri = Uri.parse(ApiRoutes.applyForJob.replaceAll('{jobId}', jobId));
      final response = await http.post(uri, headers: await _headers());

      final data = await _handleResponse(
        response,
        retryFunction: fetchFunction,
      );

      return ApplicationResponse(
        application: Application.fromJson(data['application']),
        resumeId: data['resumeId'],
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Failed to apply for job: $e', 500);
    }
  }

  Future<Application> getApplication(String applicationId) async {
    try {
      final fetchFunction = () async {
        final uri = Uri.parse(
          ApiRoutes.getApplication.replaceAll('{applicationId}', applicationId),
        );
        final response = await http.get(uri, headers: await _headers());
        final data = await _handleResponse(response);
        return Application.fromJson(data['application']);
      };

      final uri = Uri.parse(
        ApiRoutes.getApplication.replaceAll('{applicationId}', applicationId),
      );
      final response = await http.get(uri, headers: await _headers());

      final data = await _handleResponse(
        response,
        retryFunction: fetchFunction,
      );

      final logging = Application.fromJson(data['application']);
      AppLogger.i('Application data: $logging');

      return Application.fromJson(data['application']);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Failed to get application details: $e', 500);
    }
  }

  Future<List<Application>> listApplicationsByApplicant() async {
    try {
      final fetchFunction = () async {
        final response = await http.get(
          Uri.parse(ApiRoutes.listByApplicant),
          headers: await _headers(),
        );
        final data = await _handleResponse(response);
        return (data['applications'] as List)
            .map((json) => Application.fromJson(json))
            .toList();
      };

      final response = await http.get(
        Uri.parse(ApiRoutes.listByApplicant),
        headers: await _headers(),
      );

      final data = await _handleResponse(
        response,
        retryFunction: fetchFunction,
      );

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
      final fetchFunction = () async {
        final response = await http.get(
          Uri.parse(ApiRoutes.listByRecruiter),
          headers: await _headers(),
        );
        final data = await _handleResponse(response);
        return (data['applications'] as List)
            .map((json) => Application.fromJson(json))
            .toList();
      };

      final response = await http.get(
        Uri.parse(ApiRoutes.listByRecruiter),
        headers: await _headers(),
      );

      final data = await _handleResponse(
        response,
        retryFunction: fetchFunction,
      );

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
      // Define valid statuses
      final validStatuses = ['APPLIED', 'REVIEWED', 'ACCEPTED', 'REJECTED'];
      if (!validStatuses.contains(status)) {
        throw ApiException(
          'Invalid status. Must be one of: ${validStatuses.join(', ')}',
          400,
        );
      }

      // Define retryable fetch function
      final fetchFunction = () async {
        final uri = Uri.parse(
          ApiRoutes.updateApplicationStatus.replaceAll(
            '{applicationId}',
            applicationId,
          ),
        );
        final response = await http.put(
          uri,
          headers: await _headers(),
          body: json.encode({'status': status}),
        );
        final data = await _handleResponse(response);
        return Application.fromJson(data['application']);
      };

      final uri = Uri.parse(
        ApiRoutes.updateApplicationStatus.replaceAll(
          '{applicationId}',
          applicationId,
        ),
      );
      final response = await http.put(
        uri,
        headers: await _headers(),
        body: json.encode({'status': status}),
      );
      final data = await _handleResponse(
        response,
        retryFunction: fetchFunction,
      );
      return Application.fromJson(data['application']);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Failed to update application status: $e', 500);
    }
  }

  Future<Map<String, dynamic>> deleteApplication(String applicationId) async {
    try {
      final fetchFunction = () async {
        final uri = Uri.parse(
          ApiRoutes.deleteApplication.replaceAll(
            '{applicationId}',
            applicationId,
          ),
        );
        final response = await http.delete(uri, headers: await _headers());
        return await _handleResponse(response);
      };

      final uri = Uri.parse(
        ApiRoutes.deleteApplication.replaceAll(
          '{applicationId}',
          applicationId,
        ),
      );
      final response = await http.delete(uri, headers: await _headers());

      return await _handleResponse(response, retryFunction: fetchFunction);
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
