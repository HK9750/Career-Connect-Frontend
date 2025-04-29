import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../widgets/custom_card.dart';

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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // If not authenticated, navigate to login
    if (!authProvider.isAuthenticated) {
      // Optionally, you can redirect or show a message
      return const Scaffold(body: Center(child: Text('Not authenticated')));
    }

    // Display any auth errors
    if (authProvider.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(authProvider.errorMessage!)));
        authProvider.clearErrors();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutConfirmationDialog(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Center(
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
                    style: theme.textTheme.bodyLarge,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
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
                              isRecruiter ? Icons.people : Icons.calendar_today,
                              theme.colorScheme.secondary,
                              false,
                            ),
                          ),
                        ],
                      ),
                  const SizedBox(height: 28),
                  Text(
                    'Quick Actions',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!isRecruiter) ...[
                    _buildActionCard(
                      context,
                      theme,
                      'My Resumes',
                      Icons.description,
                      'Manage your resumes',
                      theme.colorScheme.primary,
                      () => Navigator.pushNamed(context, '/resumes'),
                      isSmallScreen,
                    ),
                    const SizedBox(height: 12),
                    _buildActionCard(
                      context,
                      theme,
                      'Browse Jobs',
                      Icons.work_outline,
                      'Find job opportunities',
                      theme.colorScheme.primary,
                      () => Navigator.pushNamed(context, '/jobs'),
                      isSmallScreen,
                    ),
                    const SizedBox(height: 12),
                    _buildActionCard(
                      context,
                      theme,
                      'My Applications',
                      Icons.send,
                      'Track your job applications',
                      theme.colorScheme.secondary,
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
                      theme.colorScheme.primary,
                      () => Navigator.pushNamed(context, '/create-job'),
                      isSmallScreen,
                    ),
                    const SizedBox(height: 12),
                    _buildActionCard(
                      context,
                      theme,
                      'Manage Job Listings',
                      Icons.list_alt,
                      'View and edit your job listings',
                      theme.colorScheme.primary,
                      () => Navigator.pushNamed(context, '/jobs'),
                      isSmallScreen,
                    ),
                    const SizedBox(height: 12),
                    _buildActionCard(
                      context,
                      theme,
                      'Review Applications',
                      Icons.folder_open,
                      'Check applications for your jobs',
                      theme.colorScheme.secondary,
                      () => Navigator.pushNamed(context, '/applications'),
                      isSmallScreen,
                    ),
                  ],
                  const SizedBox(height: 28),
                  Text(
                    'Resources',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildActionCard(
                    context,
                    theme,
                    'Tips & Guides',
                    Icons.lightbulb_outline,
                    isRecruiter
                        ? 'Hiring best practices'
                        : 'Job search strategies',
                    theme.colorScheme.primary,
                    () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Feature coming soon')),
                    ),
                    isSmallScreen,
                  ),
                ],
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
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.2), width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 14.0 : 16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 22),
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
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showLogoutConfirmationDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to logout?'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
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
