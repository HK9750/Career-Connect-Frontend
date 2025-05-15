import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../utils/theme.dart';
import '../../services/api_service.dart'; // Import the API service

class DashboardScreen extends StatefulWidget {
  // Changed to StatefulWidget
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _dashboardData = {};
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Create instance of ApiService
      final apiService = ApiService();
      final data = await apiService.getDashboardInfo();

      setState(() {
        _dashboardData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    final isRecruiter = authProvider.user?.role == 'RECRUITER';
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    // Show loading indicator while checking auth status or loading dashboard data
    if (authProvider.isLoading || _isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppTheme.accentColor),
              const SizedBox(height: 16),
              Text('Loading dashboard...', style: theme.textTheme.bodyLarge),
            ],
          ),
        ),
      );
    }

    // If not authenticated, navigate to login
    if (!authProvider.isAuthenticated) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 48, color: AppTheme.errorColor),
              const SizedBox(height: 16),
              Text('Not authenticated', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed:
                    () => Navigator.pushReplacementNamed(context, '/login'),
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      );
    }

    // Show error message if there's an error while fetching dashboard data
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard'),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadDashboardData,
              tooltip: 'Refresh',
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _showLogoutConfirmationDialog(context),
              tooltip: 'Logout',
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
              const SizedBox(height: 16),
              Text(
                'Failed to load dashboard data',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _errorMessage!,
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadDashboardData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Extract dashboard metrics based on user role
    final metrics = _dashboardData['dashboardInfo']?['metrics'] ?? {};

    // Get application stats
    final applicationsByStatus = metrics['applicationsByStatus'] ?? {};
    final totalApplications = metrics['totalApplications'] ?? 0;

    // Get role-specific stats
    final totalJobs = isRecruiter ? (metrics['totalJobs'] ?? 0) : 0;
    final totalResumes = !isRecruiter ? (metrics['totalResumes'] ?? 0) : 0;
    final uniqueCandidates =
        isRecruiter ? (metrics['uniqueCandidates'] ?? 0) : 0;
    final successRate = !isRecruiter ? (metrics['successRate'] ?? '0') : '0';

    // Display any auth errors
    if (authProvider.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(authProvider.errorMessage!)),
              ],
            ),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
        authProvider.clearErrors();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isRecruiter ? Icons.business_center : Icons.person, size: 22),
            const SizedBox(width: 8),
            const Text('Dashboard'),
            const SizedBox(width: 16),
          ],
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutConfirmationDialog(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.scaffoldBackgroundColor,
                theme.colorScheme.background.withOpacity(0.7),
              ],
              stops: const [0.7, 1.0],
            ),
          ),
          child: RefreshIndicator(
            onRefresh: _loadDashboardData,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 20.0,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome Section with Avatar
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.cardTheme.color,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: AppTheme.accentColor.withOpacity(
                                0.2,
                              ),
                              child: Text(
                                (authProvider.user?.username?.isNotEmpty ==
                                        true)
                                    ? authProvider.user!.username![0]
                                        .toUpperCase()
                                    : 'U',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.accentColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome, ${authProvider.user?.username ?? 'User'}!',
                                    style: theme.textTheme.headlineSmall,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    isRecruiter
                                        ? 'Find the perfect candidates for your roles'
                                        : 'Let\'s build your career path',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: theme.textTheme.bodySmall?.color,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Stats Section
                      Text(
                        'Overview',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      isSmallScreen
                          ? Column(
                            children: [
                              _buildStatCard(
                                context,
                                isRecruiter ? 'Job Listings' : 'Applications',
                                isRecruiter
                                    ? totalJobs.toString()
                                    : totalApplications.toString(),
                                isRecruiter ? Icons.work : Icons.send,
                                theme.colorScheme.primary,
                                true,
                                isRecruiter
                                    ? '+${(totalJobs * 0.05).toStringAsFixed(0)}%'
                                    : '+${(totalApplications * 0.05).toStringAsFixed(0)}%',
                              ),
                              const SizedBox(height: 12),
                              _buildStatCard(
                                context,
                                isRecruiter ? 'Candidates' : 'Success Rate',
                                isRecruiter
                                    ? uniqueCandidates.toString()
                                    : '$successRate%',
                                isRecruiter ? Icons.people : Icons.trending_up,
                                theme.colorScheme.secondary,
                                true,
                                isRecruiter
                                    ? '+${(uniqueCandidates * 0.05).toStringAsFixed(0)}%'
                                    : '+2%',
                              ),
                            ],
                          )
                          : Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  context,
                                  isRecruiter ? 'Job Listings' : 'Applications',
                                  isRecruiter
                                      ? totalJobs.toString()
                                      : totalApplications.toString(),
                                  isRecruiter ? Icons.work : Icons.send,
                                  theme.colorScheme.primary,
                                  false,
                                  isRecruiter
                                      ? '+${(totalJobs * 0.05).toStringAsFixed(0)}%'
                                      : '+${(totalApplications * 0.05).toStringAsFixed(0)}%',
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildStatCard(
                                  context,
                                  isRecruiter ? 'Candidates' : 'Success Rate',
                                  isRecruiter
                                      ? uniqueCandidates.toString()
                                      : '$successRate%',
                                  isRecruiter
                                      ? Icons.people
                                      : Icons.trending_up,
                                  theme.colorScheme.secondary,
                                  false,
                                  isRecruiter
                                      ? '+${(uniqueCandidates * 0.05).toStringAsFixed(0)}%'
                                      : '+2%',
                                ),
                              ),
                            ],
                          ),

                      const SizedBox(height: 20),

                      // Application Status Section
                      Text(
                        'Application Status',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildApplicationStatusCard(
                        context,
                        theme,
                        applicationsByStatus,
                      ),

                      const SizedBox(height: 28),

                      // Quick Actions Section
                      Row(
                        children: [
                          Text(
                            'Quick Actions',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            height: 24,
                            width: 24,
                            decoration: BoxDecoration(
                              color: AppTheme.accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.bolt,
                              size: 14,
                              color: AppTheme.accentColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (!isRecruiter) ...[
                        _buildActionCard(
                          context,
                          theme,
                          'View Resumes',
                          Icons.description_outlined,
                          'Manage your existing resumes (${totalResumes.toString()})',
                          AppTheme.accentColor,
                          () => Navigator.pushNamed(context, '/resumes'),
                          isSmallScreen,
                        ),
                        const SizedBox(height: 12),
                        _buildActionCard(
                          context,
                          theme,
                          'Upload Resume',
                          Icons.upload_file_outlined,
                          'Add a new resume to your profile',
                          AppTheme.primaryColor,
                          () => Navigator.pushNamed(context, '/resumes/upload'),
                          isSmallScreen,
                        ),
                        const SizedBox(height: 12),
                        _buildActionCard(
                          context,
                          theme,
                          'Browse Jobs',
                          Icons.work_outline_outlined,
                          'Find job opportunities',
                          AppTheme.secondaryColor,
                          () => Navigator.pushNamed(context, '/jobs'),
                          isSmallScreen,
                        ),
                        const SizedBox(height: 12),
                        _buildActionCard(
                          context,
                          theme,
                          'My Applications',
                          Icons.send_outlined,
                          'Track your job applications (${totalApplications.toString()})',
                          AppTheme.accentColor,
                          () => Navigator.pushNamed(context, '/applications'),
                          isSmallScreen,
                        ),
                      ] else ...[
                        _buildActionCard(
                          context,
                          theme,
                          'Post New Job',
                          Icons.add_circle_outline,
                          'Create a job listing',
                          AppTheme.accentColor,
                          () => Navigator.pushNamed(context, '/create-job'),
                          isSmallScreen,
                        ),
                        const SizedBox(height: 12),
                        _buildActionCard(
                          context,
                          theme,
                          'Manage Job Listings',
                          Icons.list_alt_outlined,
                          'View and edit your job listings (${totalJobs.toString()})',
                          AppTheme.primaryColor,
                          () => Navigator.pushNamed(context, '/jobs'),
                          isSmallScreen,
                        ),
                        const SizedBox(height: 12),
                        _buildActionCard(
                          context,
                          theme,
                          'Review Applications',
                          Icons.folder_outlined,
                          'Check applications for your jobs (${totalApplications.toString()})',
                          AppTheme.secondaryColor,
                          () => Navigator.pushNamed(
                            context,
                            '/recruiters-application',
                          ),
                          isSmallScreen,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    bool fullWidth,
    String trendValue,
  ) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const Spacer(),
              Icon(Icons.trending_up, color: AppTheme.successColor, size: 20),
              const SizedBox(width: 4),
              Text(
                trendValue,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.successColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationStatusCard(
    BuildContext context,
    ThemeData theme,
    Map<String, dynamic> statusData,
  ) {
    final applied = statusData['APPLIED'] ?? 0;
    final reviewed = statusData['REVIEWED'] ?? 0;
    final accepted = statusData['ACCEPTED'] ?? 0;
    final rejected = statusData['REJECTED'] ?? 0;
    final total = applied + reviewed + accepted + rejected;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (total > 0) ...[
            _buildStatusProgressBar(
              context,
              'Applied',
              applied,
              total,
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildStatusProgressBar(
              context,
              'Reviewed',
              reviewed,
              total,
              Colors.amber,
            ),
            const SizedBox(height: 12),
            _buildStatusProgressBar(
              context,
              'Accepted',
              accepted,
              total,
              Colors.green,
            ),
            const SizedBox(height: 12),
            _buildStatusProgressBar(
              context,
              'Rejected',
              rejected,
              total,
              Colors.red,
            ),
          ] else ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  'No application data available',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusProgressBar(
    BuildContext context,
    String status,
    int count,
    int total,
    Color color,
  ) {
    final theme = Theme.of(context);
    final percentage =
        total > 0 ? (count / total * 100).toStringAsFixed(0) : '0';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              status,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$count ($percentage%)',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: total > 0 ? count / total : 0,
          backgroundColor: theme.colorScheme.background,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    ThemeData theme,
    String title,
    IconData icon,
    String subtitle,
    Color color,
    VoidCallback onTap,
    bool isSmallScreen,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 16.0 : 18.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodySmall?.color,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color:
                      theme.brightness == Brightness.dark
                          ? Colors.black12
                          : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showLogoutConfirmationDialog(BuildContext context) async {
    final theme = Theme.of(context);

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.logout, color: AppTheme.accentColor, size: 24),
              const SizedBox(width: 12),
              const Text('Confirm Logout'),
            ],
          ),
          content: const Text(
            'Are you sure you want to logout? You will need to sign in again to access your account.',
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: <Widget>[
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppTheme.accentColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppTheme.accentColor),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              child: const Text('Logout'),
              onPressed: () {
                final authProvider = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                );
                authProvider.logout();
                Navigator.of(context).pop();
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        );
      },
    );
  }
}
