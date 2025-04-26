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
    applicationId = ModalRoute.of(context)!.settings.arguments as int;
    _loadApplication();
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
              child: const Text('Withdraw'),
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
            return const Center(child: Text('Application not found'));
          }

          final app = snapshot.data!;

          if (_isProcessing) {
            return const LoadingIndicator(text: 'Processing...');
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusBadge(app.statusLabel),
                const SizedBox(height: 20),
                _buildJobDetails(app),
                const SizedBox(height: 20),
                if (_isRecruiter) ...[
                  _buildApplicantInfo(app),
                  const SizedBox(height: 20),
                  _buildRecruiterActions(app),
                ],
                const SizedBox(height: 20),
                _buildAdditionalInfo(app),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(String statusLabel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: _getStatusColor(statusLabel),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        statusLabel,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildJobDetails(Application app) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Job Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.work),
              title: Text(app.jobTitle),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.location_on),
              title: Text(app.jobLocation),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('Applied on'),
              subtitle: Text(app.formattedDate),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicantInfo(Application app) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Applicant Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.person),
              title: Text(app.applicant!.username),
              subtitle: Text(app.applicant!.email),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () => _downloadResume(app.resumeUrl),
              icon: const Icon(Icons.download),
              label: const Text('Download Resume'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecruiterActions(Application app) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Update Application Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                ActionButton(
                  label: 'Mark Reviewed',
                  color: Colors.blue,
                  isActive: app.isPending,
                  onPressed: () => _updateStatus('REVIEWED'),
                ),
                ActionButton(
                  label: 'Accept',
                  color: Colors.green,
                  isActive: !app.isAccepted && !app.isRejected,
                  onPressed: () => _updateStatus('ACCEPTED'),
                ),
                ActionButton(
                  label: 'Reject',
                  color: Colors.red,
                  isActive: !app.isRejected,
                  onPressed: () => _updateStatus('REJECTED'),
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
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Additional Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Text(app.coverLetter ?? 'No additional information provided.'),
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
        return Colors.orange;
      case 'Accepted':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
