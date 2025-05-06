// lib/screens/application_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/utils/theme.dart';
import '../../models/application.dart';
import '../../services/api_service.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_view.dart';
import '../../widgets/action_button.dart';
import 'package:url_launcher/url_launcher.dart';

class ApplicationDetailScreen extends StatefulWidget {
  const ApplicationDetailScreen({Key? key}) : super(key: key);

  @override
  State<ApplicationDetailScreen> createState() =>
      _ApplicationDetailScreenState();
}

class _ApplicationDetailScreenState extends State<ApplicationDetailScreen> {
  late Future<Application> _applicationFuture;
  final ApiService _apiService = ApiService();
  bool _isProcessing = false;
  late int applicationId;

  /// TODO: Replace this with actual auth-based recruiter check
  final bool _isRecruiter = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      applicationId = ModalRoute.of(context)!.settings.arguments as int;
      _loadApplication();
    });
  }

  void _loadApplication() {
    _applicationFuture = _apiService.getApplication(applicationId.toString());
  }

  Future<void> _updateStatus(String status) async {
    setState(() => _isProcessing = true);
    try {
      await _apiService.updateApplicationStatus(
        applicationId.toString(),
        status,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application status updated successfully'),
          backgroundColor: AppTheme.successColor,
        ),
      );

      setState(() {
        _loadApplication();
        _isProcessing = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _deleteApplication() async {
    setState(() => _isProcessing = true);
    try {
      await _apiService.deleteApplication(applicationId.toString());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application withdrawn successfully'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to withdraw application: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _downloadResume(String resumeUrl) async {
    try {
      final Uri uri = Uri.parse(resumeUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $resumeUrl';
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download resume: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _confirmWithdraw() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Withdraw Application'),
          content: const Text(
            'Are you sure you want to withdraw this application? This action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text(
                'Withdraw',
                style: TextStyle(color: AppTheme.errorColor),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteApplication();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Details'),
        elevation: 0,
        actions: [
          if (!_isRecruiter)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _isProcessing ? null : _confirmWithdraw,
              tooltip: 'Withdraw Application',
            ),
        ],
      ),
      body: FutureBuilder<Application>(
        future: _applicationFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator();
          } else if (snapshot.hasError) {
            return ErrorView(
              error: snapshot.error.toString(),
              onRetry: _loadApplication,
            );
          } else if (!snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppTheme.warningColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Application not found',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          final app = snapshot.data!;

          if (_isProcessing) {
            return const LoadingIndicator(text: 'Processing...');
          }

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.primaryColor.withOpacity(0.05),
                  Colors.transparent,
                ],
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Job Title and Status Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          spreadRadius: 1,
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          app.jobTitle,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(
                              Icons.business,
                              size: 18,
                              color: AppTheme.subtitleColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildStatusBadge(app.statusLabel),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Job Details
                  _buildJobDetails(app),

                  const SizedBox(height: 24),

                  // Recruiter-specific sections
                  if (_isRecruiter) ...[
                    _buildApplicantInfo(app),
                    const SizedBox(height: 24),
                    _buildRecruiterActions(app),
                    const SizedBox(height: 24),
                  ],

                  // Additional Info
                  _buildAdditionalInfo(app),

                  // Footer space
                  const SizedBox(height: 32),

                  // Withdraw button for applicants
                  if (!_isRecruiter)
                    Center(
                      child: OutlinedButton.icon(
                        onPressed: _confirmWithdraw,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Withdraw Application'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.errorColor,
                          side: const BorderSide(color: AppTheme.errorColor),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(String statusLabel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: _getStatusColor(statusLabel).withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _getStatusColor(statusLabel), width: 1),
      ),
      child: Text(
        statusLabel,
        style: TextStyle(
          color: _getStatusColor(statusLabel),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildJobDetails(Application app) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: AppTheme.accentColor),
                const SizedBox(width: 8),
                Text(
                  'Job Details',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const Divider(height: 24),
            _buildDetailRow(Icons.work, 'Position', app.jobTitle, context),
            const SizedBox(height: 16),
            _buildDetailRow(
              Icons.location_on,
              'Location',
              app.jobLocation,
              context,
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              Icons.calendar_today,
              'Applied on',
              app.formattedDate,
              context,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    BuildContext context,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.accentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: AppTheme.accentColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall!.copyWith(color: AppTheme.subtitleColor),
              ),
              const SizedBox(height: 4),
              Text(value, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildApplicantInfo(Application app) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person_outline, color: AppTheme.accentColor),
                const SizedBox(width: 8),
                Text(
                  'Applicant Information',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.primaryColor,
                  child: Text(
                    app.applicant!.username.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.applicant!.username,
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      app.applicant!.email,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: AppTheme.subtitleColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _downloadResume(app.resumeUrl),
              icon: const Icon(Icons.download),
              label: const Text('Download Resume'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecruiterActions(Application app) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.update, color: AppTheme.accentColor),
                const SizedBox(width: 8),
                Text(
                  'Update Application Status',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const Divider(height: 24),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12.0,
              runSpacing: 12.0,
              children: [
                ActionButton(
                  label: 'Mark Reviewed',
                  color: Colors.blue,
                  isActive: app.isPending,
                  onPressed: () => _updateStatus('REVIEWED'),
                  icon: Icons.visibility,
                ),
                ActionButton(
                  label: 'Accept',
                  color: AppTheme.successColor,
                  isActive: !app.isAccepted && !app.isRejected,
                  onPressed: () => _updateStatus('ACCEPTED'),
                  icon: Icons.check_circle,
                ),
                ActionButton(
                  label: 'Reject',
                  color: AppTheme.errorColor,
                  isActive: !app.isRejected,
                  onPressed: () => _updateStatus('REJECTED'),
                  icon: Icons.cancel,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalInfo(Application app) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.description, color: AppTheme.accentColor),
                const SizedBox(width: 8),
                Text(
                  'Cover Letter',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const Divider(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color?.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Text(
                app.coverLetter ?? 'No cover letter provided.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String statusLabel) {
    switch (statusLabel) {
      case 'Pending':
        return Colors.blue;
      case 'Under Review':
        return AppTheme.warningColor;
      case 'Accepted':
        return AppTheme.successColor;
      case 'Rejected':
        return AppTheme.errorColor;
      default:
        return AppTheme.accentColor;
    }
  }
}
