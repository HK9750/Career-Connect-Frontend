import 'package:flutter/material.dart';
import 'package:frontend/utils/theme.dart';
import '../../models/job.dart';
import '../../services/api_service.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_view.dart';
import '../applications/application_list_screen.dart';

class JobDetailScreen extends StatefulWidget {
  const JobDetailScreen({Key? key}) : super(key: key);

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  late Future<Job> _jobFuture;
  final ApiService _apiService = ApiService();
  bool _isApplying = false;
  bool _isAnalyzing = false;
  int? jobId;
  int? resumeId;
  Map<String, dynamic>? _analysisResult;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Move from initState to didChangeDependencies to ensure context is available
    if (jobId == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is int) {
        jobId = args;
        _loadJob();
      }
    }
  }

  void _loadJob() {
    if (jobId != null) {
      _jobFuture = _apiService.getJob(jobId.toString());
    }
  }

  Future<void> _applyForJob() async {
    if (jobId == null) return;

    setState(() {
      _isApplying = true;
    });

    try {
      final response = await _apiService.applyForJob(jobId.toString());
      resumeId = response.resumeId;
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application submitted successfully!'),
          backgroundColor: AppTheme.successColor,
        ),
      );

      // Now perform the resume analysis with the jobId and resumeId
      await _analyzeResume();

      // Navigate to application detail
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ApplicationListScreen()),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to apply: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isApplying = false;
        });
      }
    }
  }

  Future<void> _analyzeResume() async {
    if (jobId == null || resumeId == null) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      _analysisResult = await _apiService.analyzeResume(
        resumeId.toString(),
        jobId.toString(),
      );
      if (!mounted) return;

      // You can handle the analysis result here
      // For example, show a dialog with the results or store it for later use
      print('Resume analysis completed: $_analysisResult');
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Resume analysis failed: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (jobId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Job Details')),
        body: const Center(child: Text('Job ID not provided')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Job Details')),
      body: FutureBuilder<Job>(
        future: _jobFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator();
          } else if (snapshot.hasError) {
            return ErrorView(
              error: 'Error loading job details: ${snapshot.error}',
              onRetry: () {
                setState(() {
                  _loadJob();
                });
              },
            );
          } else if (!snapshot.hasData) {
            return const Center(child: Text('Job not found'));
          } else {
            final job = snapshot.data!;
            return _buildJobDetails(job);
          }
        },
      ),
      bottomNavigationBar:
          jobId != null
              ? FutureBuilder<Job>(
                future: _jobFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return _buildApplyButton();
                  }
                  return const SizedBox.shrink();
                },
              )
              : null,
    );
  }

  Widget _buildJobDetails(Job job) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(job.title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.business, job.company),
          if (job.location != null)
            _buildInfoRow(Icons.location_on, job.location!),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About this role',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    job.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (job.tags != null && job.tags!.isNotEmpty) ...[
            Text('Skills', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  job.tags!.map((tag) {
                    return Chip(
                      label: Text(tag),
                      backgroundColor: AppTheme.accentColor.withOpacity(0.2),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 16),
          ],
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Posted by',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppTheme.primaryColor,
                        child: Text(
                          job.recruiter?.username
                                  .substring(0, 1)
                                  .toUpperCase() ??
                              'R',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.recruiter?.username ?? 'Recruiter',
                            style: Theme.of(context).textTheme.bodyLarge!
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Posted on ${_formatDate(job.createdAt)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 80), // Space for the bottom button
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.subtitleColor, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge!.copyWith(color: AppTheme.subtitleColor),
          ),
        ],
      ),
    );
  }

  Widget _buildApplyButton() {
    final bool isLoading = _isApplying || _isAnalyzing;
    String buttonText = 'Apply Now';

    if (_isApplying) {
      buttonText = 'Applying...';
    } else if (_isAnalyzing) {
      buttonText = 'Analyzing Resume...';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : _applyForJob,
        style: Theme.of(context).elevatedButtonTheme.style,
        child:
            isLoading
                ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(buttonText),
                  ],
                )
                : Text(buttonText),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
