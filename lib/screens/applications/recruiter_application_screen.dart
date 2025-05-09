// ignore_for_file: collection_methods_unrelated_type

import 'package:flutter/material.dart';
import '../../models/application.dart';
import '../../services/api_service.dart';
import '../../utils/logger.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_view.dart';
import '../../utils/theme.dart';

class RecruiterApplicationsScreen extends StatefulWidget {
  const RecruiterApplicationsScreen({Key? key}) : super(key: key);

  @override
  _RecruiterApplicationsScreenState createState() =>
      _RecruiterApplicationsScreenState();
}

class _RecruiterApplicationsScreenState
    extends State<RecruiterApplicationsScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Application>> _applicationsFuture;
  bool _isLoading = false;
  String? _filterStatus;
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
    setState(() {
      _applicationsFuture = _apiService.listApplicationsByRecruiter();
    });
  }

  Future<void> _updateStatus(Application application, String newStatus) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _apiService.updateApplicationStatus(
        application.id.toString(),
        newStatus,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Application status updated to $newStatus'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
      // Reload the applications list
      _loadApplications();
    } catch (e) {
      AppLogger.e('Error updating application status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildStatusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildStatusButton(Application application) {
    // Define available status transitions based on current status
    Map<String, List<String>> availableTransitions = {
      'APPLIED': ['REVIEWED', 'ACCEPTED', 'REJECTED'],
      'REVIEWED': ['ACCEPTED', 'REJECTED'],
      'ACCEPTED': ['REJECTED'],
      'REJECTED': ['ACCEPTED'],
    };

    List<String> nextStatuses = availableTransitions[application.status] ?? [];

    if (nextStatuses.isEmpty) {
      return _buildStatusChip(application.status);
    }

    return PopupMenuButton<String>(
      onSelected: (String status) {
        _updateStatus(application, status);
      },
      itemBuilder: (BuildContext context) {
        return nextStatuses.map((String status) {
          return PopupMenuItem<String>(
            value: status,
            child: Row(
              children: [
                Icon(
                  _getStatusIcon(status),
                  color: _getStatusColor(status),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  status,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: _getStatusColor(status),
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        decoration: BoxDecoration(
          color: _getStatusColor(application.status),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              application.status,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

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
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'APPLIED':
        return Icons.send;
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

  List<Application> _filterApplications(List<Application> applications) {
    if (_filterStatus == null || _filterStatus == 'ALL') {
      return applications;
    }
    return applications.where((app) => app.status == _filterStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Job Applications',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0, // Flat modern design
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadApplications,
            tooltip: 'Refresh applications',
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () {
                  _showFilterDialog();
                },
                tooltip: 'Filter applications',
              ),
              if (_filterStatus != null && _filterStatus != 'ALL')
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _getStatusColor(_filterStatus!),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          FutureBuilder<List<Application>>(
            future: _applicationsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingIndicator();
              } else if (snapshot.hasError) {
                return ErrorView(
                  error: snapshot.error.toString(),
                  onRetry: _loadApplications,
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildEmptyState(
                  icon: Icons.work_off,
                  title: 'No applications found',
                  message:
                      'Applications will appear here once candidates apply',
                );
              }

              final allApplications = snapshot.data!;
              final applications = _filterApplications(allApplications);

              if (applications.isEmpty) {
                return _buildEmptyState(
                  icon: Icons.filter_list,
                  title: 'No ${_filterStatus?.toLowerCase()} applications',
                  message: 'Try changing the filter to see more applications',
                  showClearFilterButton: true,
                );
              }

              // Group applications by job
              final Map<String, List<Application>> applicationsByJob = {};
              for (var app in applications) {
                if (app.job != null) {
                  String jobId = app.job!.id.toString();
                  if (!applicationsByJob.containsKey(jobId)) {
                    applicationsByJob[jobId] = [];
                  }
                  applicationsByJob[jobId]!.add(app);
                }
              }

              if (applicationsByJob.isEmpty) {
                return _buildEmptyState(
                  icon: Icons.error_outline,
                  title: 'Job data missing',
                  message: 'Some applications are missing job details',
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  _loadApplications();
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: applicationsByJob.length,
                  itemBuilder: (context, index) {
                    final jobId = applicationsByJob.keys.elementAt(index);
                    final jobApplications = applicationsByJob[jobId]!;
                    final job = jobApplications.first.job;

                    if (job == null) {
                      return const SizedBox.shrink();
                    }

                    final jobTitle = job.title;
                    final company = job.company;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Theme(
                        data: Theme.of(
                          context,
                        ).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.all(16),
                          childrenPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primaryColor.withOpacity(
                              0.1,
                            ),
                            child: Text(
                              jobApplications.length.toString(),
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            jobTitle,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 16,
                                runSpacing: 8,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.business,
                                        size: 16,
                                        color: AppTheme.subtitleColor,
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          company,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyMedium?.copyWith(
                                            color: AppTheme.subtitleColor,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        size: 16,
                                        color: AppTheme.subtitleColor,
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          job.location ?? 'Remote',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyMedium?.copyWith(
                                            color: AppTheme.subtitleColor,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildStatusSummary(jobApplications),
                            ],
                          ),
                          children: [
                            const Divider(height: 1, thickness: 1),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: jobApplications.length,
                              itemBuilder: (context, appIndex) {
                                final application = jobApplications[appIndex];
                                return _buildApplicationCard(application);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          if (_isLoading)
            Container(
              color: Colors.black45,
              child: const Center(
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusSummary(List<Application> applications) {
    // Count applications by status
    Map<String, int> statusCounts = {
      'APPLIED': 0,
      'REVIEWED': 0,
      'ACCEPTED': 0,
      'REJECTED': 0,
    };

    for (var app in applications) {
      if (statusCounts.containsKey(app.status)) {
        statusCounts[app.status] = (statusCounts[app.status] ?? 0) + 1;
      }
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          statusCounts.entries.map((entry) {
            if (entry.value == 0) return const SizedBox.shrink();

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(entry.key).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getStatusColor(entry.key).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                '${entry.value} ${entry.key.toLowerCase()}',
                style: TextStyle(
                  color: _getStatusColor(entry.key),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
    bool showClearFilterButton = false,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: AppTheme.subtitleColor.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.subtitleColor,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            if (showClearFilterButton) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _filterStatus = null;
                  });
                },
                icon: const Icon(Icons.clear),
                label: const Text('Clear Filter'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
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

  Widget _buildApplicationCard(Application application) {
    final applicant = application.applicant;
    final resume = application.resume;

    if (applicant == null || resume == null) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppTheme.errorColor),
              const SizedBox(width: 8),
              Text(
                'Missing applicant or resume data',
                style: TextStyle(color: AppTheme.errorColor),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getStatusColor(application.status).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: 'applicant-${application.id}',
                  child: CircleAvatar(
                    backgroundColor: AppTheme.primaryColor,
                    radius: 24,
                    child: Text(
                      applicant.username.isNotEmpty
                          ? applicant.username[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        applicant.username,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.email_outlined,
                            size: 14,
                            color: AppTheme.subtitleColor,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              applicant.email,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppTheme.subtitleColor),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Applied on: ${_formatDate(application.createdAt)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: AppTheme.subtitleColor,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusButton(application),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 16,
                  color: AppTheme.accentColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    resume.title ?? "Untitled Resume",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to resume detail screen
                      Navigator.pushNamed(
                        context,
                        '/resume-detail',
                        arguments: resume.id,
                      );
                    },
                    icon: const Icon(Icons.description, size: 18),
                    label: const Text('View Resume'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                if (application.analysisId != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Navigate to analysis detail screen
                        Navigator.pushNamed(
                          context,
                          '/analysis-detail',
                          arguments: application.analysisId,
                        );
                      },
                      icon: const Icon(Icons.analytics, size: 18),
                      label: const Text('View Analysis'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        side: BorderSide(color: AppTheme.primaryColor),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
