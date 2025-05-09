import 'package:flutter/material.dart';
import 'package:frontend/utils/theme.dart';
import '../../models/application.dart';
import '../../services/api_service.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_view.dart';
import 'application_detail_screen.dart';

class ApplicationListScreen extends StatefulWidget {
  const ApplicationListScreen({Key? key}) : super(key: key);

  @override
  State<ApplicationListScreen> createState() => _ApplicationListScreenState();
}

class _ApplicationListScreenState extends State<ApplicationListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<Application>> _applicationsFuture;
  final ApiService _apiService = ApiService();

  // User role - in a real app, you'd get this from a user service
  final bool _isRecruiter = false; // Change to test different views

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadApplications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadApplications() {
    if (_isRecruiter) {
      _applicationsFuture = _apiService.listApplicationsByRecruiter();
    } else {
      _applicationsFuture = _apiService.listApplicationsByApplicant();
    }
  }

  List<Application> _filterApplications(
    List<Application> applications,
    String status,
  ) {
    if (status == 'ALL') {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isRecruiter ? 'Received Applications' : 'My Applications'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppTheme.secondaryColor,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'Under Review'),
            Tab(text: 'Completed'),
          ],
        ),
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
            return TabBarView(
              controller: _tabController,
              children: [
                _buildApplicationList(_filterApplications(applications, 'ALL')),
                _buildApplicationList(
                  _filterApplications(applications, 'APPLIED'),
                ),
                _buildApplicationList(
                  _filterApplications(applications, 'REVIEWED'),
                ),
                _buildCompletedApplicationsView(applications),
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

  Widget _buildCompletedApplicationsView(List<Application> applications) {
    // Create a separate TabController for the nested tabs
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color:
                Theme.of(context).brightness == Brightness.light
                    ? AppTheme.lightBackgroundColor
                    : AppTheme.darkBackgroundColor,
            child: TabBar(
              labelColor:
                  Theme.of(context).brightness == Brightness.light
                      ? AppTheme.primaryColor
                      : Colors.white,
              unselectedLabelColor: AppTheme.subtitleColor,
              indicatorColor: AppTheme.secondaryColor,
              tabs: const [Tab(text: 'Accepted'), Tab(text: 'Rejected')],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildApplicationList(
                  _filterApplications(applications, 'ACCEPTED'),
                ),
                _buildApplicationList(
                  _filterApplications(applications, 'REJECTED'),
                ),
              ],
            ),
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
              'No applications in this category',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppTheme.subtitleColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationCard(Application application) {
    final theme = Theme.of(context);

    // Colors for different status
    Color statusColor;
    IconData statusIcon;

    switch (application.status) {
      case 'APPLIED':
        statusColor = AppTheme.accentColor;
        statusIcon = Icons.hourglass_bottom;
        break;
      case 'REVIEWED':
        statusColor = AppTheme.warningColor;
        statusIcon = Icons.visibility;
        break;
      case 'ACCEPTED':
        statusColor = AppTheme.successColor;
        statusIcon = Icons.check_circle;
        break;
      case 'REJECTED':
        statusColor = AppTheme.errorColor;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = AppTheme.accentColor;
        statusIcon = Icons.help_outline;
    }

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
