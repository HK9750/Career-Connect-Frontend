import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../utils/theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    final isRecruiter = authProvider.user?.role == 'RECRUITER';
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    // Show loading indicator while checking auth status
    if (authProvider.isLoading) {
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
          ],
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
            tooltip: 'Notifications',
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
                              (authProvider.user?.username?.isNotEmpty == true)
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
                              isRecruiter ? '12' : '5',
                              isRecruiter ? Icons.work : Icons.send,
                              theme.colorScheme.primary,
                              true,
                            ),
                            const SizedBox(height: 12),
                            _buildStatCard(
                              context,
                              isRecruiter ? 'Candidates' : 'Interviews',
                              isRecruiter ? '48' : '2',
                              isRecruiter ? Icons.people : Icons.calendar_today,
                              theme.colorScheme.secondary,
                              true,
                            ),
                          ],
                        )
                        : Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                context,
                                isRecruiter ? 'Job Listings' : 'Applications',
                                isRecruiter ? '12' : '5',
                                isRecruiter ? Icons.work : Icons.send,
                                theme.colorScheme.primary,
                                false,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatCard(
                                context,
                                isRecruiter ? 'Candidates' : 'Interviews',
                                isRecruiter ? '48' : '2',
                                isRecruiter
                                    ? Icons.people
                                    : Icons.calendar_today,
                                theme.colorScheme.secondary,
                                false,
                              ),
                            ),
                          ],
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
                        'Manage your existing resumes',
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
                        'Track your job applications',
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
                        'View and edit your job listings',
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
                        'Check applications for your jobs',
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
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    bool fullWidth,
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
                '+5%',
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
