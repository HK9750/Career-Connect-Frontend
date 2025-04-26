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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isRecruiter ? 'Received Applications' : 'My Applications'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.file_copy_outlined,
                    size: 64,
                    color: AppTheme.subtitleColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isRecruiter
                        ? 'No applications received yet'
                        : 'You haven\'t applied to any jobs yet',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  if (!_isRecruiter)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Go back to job list
                      },
                      child: const Text('Browse Jobs'),
                    ),
                ],
              ),
            );
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
                TabBarView(
                  controller: TabController(length: 2, vsync: this),
                  children: [
                    _buildApplicationList(
                      _filterApplications(applications, 'ACCEPTED'),
                    ),
                    _buildApplicationList(
                      _filterApplications(applications, 'REJECTED'),
                    ),
                  ],
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildApplicationList(List<Application> applications) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _loadApplications();
        });
      },
      child:
          applications.isEmpty
              ? Center(
                child: Text(
                  'No applications in this category',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                itemCount: applications.length,
                itemBuilder: (context, index) {
                  final application = applications[index];
                  return _buildApplicationCard(application);
                },
              ),
    );
  }

  Widget _buildApplicationCard(Application application) {
    // Colors for different status
    Color statusColor;
    switch (application.status) {
      case 'APPLIED':
        statusColor = Colors.blue;
        break;
      case 'REVIEWED':
        statusColor = AppTheme.warningColor;
        break;
      case 'ACCEPTED':
        statusColor = AppTheme.successColor;
        break;
      case 'REJECTED':
        statusColor = AppTheme.errorColor;
        break;
      default:
        statusColor = AppTheme.accentColor;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ApplicationDetailScreen()),
          ).then((_) {
            // Refresh applications when returning from detail screen
            setState(() {
              _loadApplications();
            });
          });
        },
        borderRadius: BorderRadius.circular(16.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      application.job?.title ?? 'Job Title',
                      style: Theme.of(context).textTheme.headlineSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      application.statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.business,
                    size: 16,
                    color: AppTheme.subtitleColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    application.job?.company ?? 'Company',
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: AppTheme.subtitleColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _isRecruiter
                      ? Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AppTheme.primaryColor,
                            child: Text(
                              application.applicant?.username
                                      .substring(0, 1)
                                      .toUpperCase() ??
                                  'A',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            application.applicant?.username ?? 'Applicant',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      )
                      : Text(
                        'Resume: ${application.resume?.owner?.username ?? 'Resume'}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                  Text(
                    application.formattedDate,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
