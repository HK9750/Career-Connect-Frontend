// lib/core/routes.dart
import '../utils/constants.dart';

class ApiRoutes {
  static const auth = '${Constants.baseUrl}/auth';
  static const login = '$auth/login';
  static const register = '$auth/register';
  static const refreshToken = '$auth/refresh-token';

  static const job = '${Constants.baseUrl}/job';
  static const listJobs = '$job';
  static const createJob = '$job';
  static const jobDetail = '$job/{id}';
  static const updateJob = '$job/{id}';
  static const deleteJob = '$job/{id}';

  static const resume = '${Constants.baseUrl}/resume';
  static const uploadResume = '$resume/upload';
  static const listResumes = '$resume';
  static const getResume = '$resume/{id}';
  static const getResumesByUser = '$resume/user/me';
  static const getResumesByRecruiter = '$resume/recruiter/me';
  static const downloadResume = '$resume/download/{id}';
  static const updateResume = '$resume/{id}';
  static const deleteResume = '$resume/{id}';

  static const analysis = '${Constants.baseUrl}/analysis';
  static const analyze = '$analysis/analyze/{resumeId}';

  static const _base = '${Constants.baseUrl}/review/application';
  static const submitReview = '$_base/{applicationId}/review';
  static const updateReview = '$_base/{applicationId}/review-update';
  static const getOneReview = '$_base/{applicationId}/review';
  static const deleteOneReview = '$_base/{applicationId}/review';
  static const listAllReview = '${Constants.baseUrl}/reviews';

  static const application = '${Constants.baseUrl}/application';
  static const applyForJob = '$application/apply/{jobId}';
  static const listByApplicant = '$application/applicant/me';
  static const listByRecruiter = '$application/recruiter/me';
  static const getApplication = '$application/{applicationId}';
  static const updateApplicationStatus = '$application/{applicationId}/status';
  static const deleteApplication = '$application/{applicationId}';

  static const dashboardInfo = '${Constants.baseUrl}/dashboard';
}
