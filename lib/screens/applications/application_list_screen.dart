import 'package:flutter/material.dart';
import 'package:frontend/utils/theme.dart';
import '../../models/application.dart';
import '../../models/review.dart';
import '../../services/api_service.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_view.dart';
import 'application_detail_screen.dart';

class ApplicationListScreen extends StatefulWidget {
  const ApplicationListScreen({Key? key}) : super(key: key);

  @override
  State<ApplicationListScreen> createState() => _ApplicationListScreenState();
}

class _ApplicationListScreenState extends State<ApplicationListScreen> {
  late Future<List<Application>> _applicationsFuture;
  final ApiService _apiService = ApiService();
  String? _filterStatus;

  // User role - in a real app, you'd get this from a user service
  final bool _isRecruiter = false; // Change to test different views

  // Status options for filtering
  final List<String> _statusOptions = [
    'ALL',
    'APPLIED',
    'REVIEWED',
    'ACCEPTED',
    'REJECTED',
  ];

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  void _loadApplications() {
    if (_isRecruiter) {
      _applicationsFuture = _apiService.listApplicationsByRecruiter();
    } else {
      _applicationsFuture = _apiService.listApplicationsByApplicant();
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.filter_list, color: AppTheme.primaryColor),
              const SizedBox(width: 12),
              const Text('Filter Applications'),
            ],
          ),
          content: SizedBox(
            width: double.minPositive,
            child: ListView(
              shrinkWrap: true,
              children:
                  _statusOptions.map((status) {
                    return RadioListTile<String>(
                      title: Text(
                        status,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      value: status,
                      groupValue: _filterStatus ?? 'ALL',
                      onChanged: (String? value) {
                        Navigator.pop(context);
                        setState(() {
                          _filterStatus = value == 'ALL' ? null : value;
                        });
                      },
                      activeColor:
                          status == 'ALL'
                              ? AppTheme.accentColor
                              : _getStatusColor(status),
                      secondary:
                          status != 'ALL'
                              ? Icon(
                                _getStatusIcon(status),
                                color: _getStatusColor(status),
                              )
                              : Icon(
                                Icons.all_inclusive,
                                color: AppTheme.accentColor,
                              ),
                    );
                  }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'CANCEL',
                style: TextStyle(color: AppTheme.primaryColor),
              ),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        );
      },
    );
  }

  // Get color based on application status
  Color _getStatusColor(String status) {
    switch (status) {
      case 'APPLIED':
        return AppTheme.accentColor;
      case 'REVIEWED':
        return AppTheme.warningColor;
      case 'ACCEPTED':
        return AppTheme.successColor;
      case 'REJECTED':
        return AppTheme.errorColor;
      default:
        return AppTheme.accentColor;
    }
  }

  // Get icon based on application status
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'APPLIED':
        return Icons.hourglass_bottom;
      case 'REVIEWED':
        return Icons.visibility;
      case 'ACCEPTED':
        return Icons.check_circle;
      case 'REJECTED':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  List<Application> _filterApplications(
    List<Application> applications,
    String? status,
  ) {
    if (status == null || status == 'ALL') {
      return applications;
    }
    return applications.where((app) => app.status == status).toList();
  }

  void _navigateToApplicationDetail(Application application) {
    if (application.id == null) {
      // Show an error message if ID is missing
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cannot view application details: Application ID is missing',
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ApplicationDetailScreen(),
        settings: RouteSettings(arguments: application.id),
      ),
    ).then((_) {
      // Refresh applications when returning from detail screen
      setState(() {
        _loadApplications();
      });
    });
  }

  // Add a method to show review details
  Future<void> _showReviewDetails(String applicationId) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LoadingIndicator(),
                SizedBox(height: 16),
                Text('Loading review...'),
              ],
            ),
          ),
    );

    try {
      // Add debug logging
      print('Fetching review for application ID: $applicationId');

      // Fetch the review
      final Review review = await _apiService.fetchReview(applicationId);

      // Add debug logging
      print('Successfully fetched review: ${review.comment}');

      // Close loading dialog
      Navigator.of(context).pop();

      // Show review details dialog
      showDialog(
        context: context,
        builder: (context) => _buildReviewDialog(review),
      );
    } catch (e) {
      // Add debug logging
      print('Error fetching review: $e');

      // Close loading dialog
      Navigator.of(context).pop();

      // Show error dialog
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Error'),
              content: Text('Failed to load review: ${e.toString()}'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    }
  }

  // Build the review dialog
  Widget _buildReviewDialog(Review review) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Review Details'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reviewer info
            if (review.recruiter != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppTheme.accentColor,
                      child: Text(
                        review.recruiter!.username.isNotEmpty
                            ? review.recruiter!.username
                                .substring(0, 1)
                                .toUpperCase()
                            : 'R',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Reviewed by: ${review.recruiter!.username}',
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
              ),

            // Comment
            Text('Comment:', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    theme.brightness == Brightness.light
                        ? AppTheme.lightBackgroundColor
                        : AppTheme.darkBackgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Text(
                review.comment ?? 'No comment provided',
                style: theme.textTheme.bodyMedium,
              ),
            ),

            // Review date
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Reviewed on: ${review.createdAt.toLocal().toString().split(' ')[0]}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isRecruiter ? 'Received Applications' : 'My Applications'),
        actions: [
          // Add filter button to AppBar
          Tooltip(
            message: 'Filter Applications',
            child: IconButton(
              icon: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.filter_list),
                  if (_filterStatus != null)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(_filterStatus!),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 8,
                          minHeight: 8,
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: _showFilterDialog,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<Application>>(
        future: _applicationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator();
          } else if (snapshot.hasError) {
            return ErrorView(
              error: 'Error loading applications: ${snapshot.error}',
              onRetry: () {
                setState(() {
                  _loadApplications();
                });
              },
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState(theme);
          } else {
            final applications = snapshot.data!;
            return Column(
              children: [
                // Show filter indicator if filter is active
                if (_filterStatus != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                    color:
                        theme.brightness == Brightness.light
                            ? AppTheme.lightBackgroundColor
                            : AppTheme.darkBackgroundColor,
                    child: Row(
                      children: [
                        Icon(
                          _getStatusIcon(_filterStatus!),
                          size: 18,
                          color: _getStatusColor(_filterStatus!),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Filtered by: $_filterStatus',
                          style: theme.textTheme.bodyMedium!.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(_filterStatus!),
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _filterStatus = null;
                            });
                          },
                          child: const Text('Clear'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primaryColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                // Application list with filtering
                Expanded(
                  child: _buildApplicationList(
                    _filterApplications(applications, _filterStatus),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.file_copy_outlined,
            size: 64,
            color:
                theme.brightness == Brightness.light
                    ? AppTheme.subtitleColor
                    : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _isRecruiter
                ? 'No applications received yet'
                : 'You haven\'t applied to any jobs yet',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          if (!_isRecruiter)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context); // Go back to job list
              },
              icon: const Icon(Icons.work_outline),
              label: const Text('Browse Jobs'),
            ),
        ],
      ),
    );
  }

  Widget _buildApplicationList(List<Application> applications) {
    return RefreshIndicator(
      color: AppTheme.accentColor,
      onRefresh: () async {
        setState(() {
          _loadApplications();
        });
        // Need to wait for the future to complete
        await _applicationsFuture;
      },
      child:
          applications.isEmpty
              ? _buildEmptyListMessage()
              : ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: applications.length,
                itemBuilder: (context, index) {
                  final application = applications[index];
                  return _buildApplicationCard(application);
                },
              ),
    );
  }

  Widget _buildEmptyListMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: AppTheme.subtitleColor,
            ),
            const SizedBox(height: 16),
            Text(
              _filterStatus != null
                  ? 'No applications with status $_filterStatus'
                  : 'No applications found',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppTheme.subtitleColor),
              textAlign: TextAlign.center,
            ),
            if (_filterStatus != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _filterStatus = null;
                    });
                  },
                  icon: const Icon(Icons.filter_alt_off),
                  label: const Text('Clear Filter'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationCard(Application application) {
    final theme = Theme.of(context);

    // Colors for different status
    Color statusColor = _getStatusColor(application.status);
    IconData statusIcon = _getStatusIcon(application.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      shape:
          theme.cardTheme.shape ??
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      elevation: theme.cardTheme.elevation ?? 2.0,
      shadowColor:
          theme.brightness == Brightness.light
              ? Colors.black.withOpacity(0.1)
              : Colors.black.withOpacity(0.3),
      child: InkWell(
        onTap: () => _navigateToApplicationDetail(application),
        borderRadius: BorderRadius.circular(16.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // FIX 1: Replaced Row with intrinsic height
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // FIX 2: Wrap the Expanded in a container with width constraint
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            application.job?.title ?? 'Job Title',
                            style: theme.textTheme.headlineSmall,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 8),
                          // FIX 3: Replaced inner Row with IntrinsicHeight
                          IntrinsicHeight(
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.business,
                                  size: 16,
                                  color: AppTheme.subtitleColor,
                                ),
                                const SizedBox(width: 4),
                                // FIX 4: Limited the max width of the Text
                                Expanded(
                                  child: Text(
                                    application.job?.company ?? 'Company',
                                    style: theme.textTheme.bodyMedium!.copyWith(
                                      color: AppTheme.subtitleColor,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: statusColor.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 14, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            application.statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Add Show Review button for REVIEWED applications
              if (application.status == 'REVIEWED')
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: OutlinedButton.icon(
                    onPressed: () {
                      if (application.id != null) {
                        _showReviewDetails(application.id.toString());
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Application ID is missing'),
                            backgroundColor: AppTheme.errorColor,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.rate_review, size: 18),
                    label: const Text('Show Review'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.warningColor,
                      side: const BorderSide(color: AppTheme.warningColor),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),

              const Divider(height: 1),
              const SizedBox(height: 16),
              // FIX 5: Use IntrinsicHeight for the bottom Row
              IntrinsicHeight(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _isRecruiter
                        ? IntrinsicWidth(
                          // FIX 6: Added IntrinsicWidth
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: AppTheme.accentColor,
                                child: Text(
                                  application.applicant != null &&
                                          application
                                              .applicant!
                                              .username
                                              .isNotEmpty
                                      ? application.applicant!.username
                                          .substring(0, 1)
                                          .toUpperCase()
                                      : 'A',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                application.applicant?.username ?? 'Applicant',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                        : IntrinsicWidth(
                          // FIX 7: Added IntrinsicWidth
                          child: Row(
                            children: [
                              const Icon(
                                Icons.description_outlined,
                                size: 18,
                                color: AppTheme.accentColor,
                              ),
                              const SizedBox(width: 4),
                              // FIX 8: Removed Flexible and used a limited width Container
                              Container(
                                constraints: const BoxConstraints(
                                  maxWidth: 120,
                                ),
                                child: Text(
                                  application.resume?.owner?.username ??
                                      'Resume',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color:
                                        theme.brightness == Brightness.light
                                            ? AppTheme.textColor
                                            : Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            theme.brightness == Brightness.light
                                ? AppTheme.lightBackgroundColor
                                : AppTheme.darkBackgroundColor.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        application.formattedDate,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
