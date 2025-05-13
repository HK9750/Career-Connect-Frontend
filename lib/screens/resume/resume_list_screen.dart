import 'package:flutter/material.dart';
import 'package:frontend/utils/logger.dart';
import '../../widgets/custom_button.dart';
import '../../models/resume.dart';
import '../../services/api_service.dart';

class ResumeListScreen extends StatefulWidget {
  const ResumeListScreen({Key? key}) : super(key: key);

  @override
  State<ResumeListScreen> createState() => _ResumeListScreenState();
}

class _ResumeListScreenState extends State<ResumeListScreen> {
  final ApiService _apiService = ApiService();
  List<Resume> _resumes = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadResumes();
  }

  // Modified _loadResumes method with better logging and error handling
  Future<void> _loadResumes() async {
    setState(() => _isLoading = true);
    try {
      // Add debug print to see what's happening before the API call
      print('Starting to fetch resumes...');

      final List<Resume> fetched = await _apiService.fetchResumesByUser();

      // Debug print to see the raw response
      if (fetched.isNotEmpty) {
        print('First resume: ${fetched.first.toString()}');
      }

      setState(() => _resumes = fetched);
      AppLogger.i('Fetched resumes: ${_resumes.length}');
    } catch (e, stackTrace) {
      // Improved error logging with stack trace

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load resumes: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshResumes() async {
    await _loadResumes();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('My Resumes')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _refreshResumes,
                child:
                    _resumes.isEmpty
                        ? _buildEmptyState(theme)
                        : _buildResumeList(theme),
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed:
            () => Navigator.pushNamed(
              context,
              '/resumes/upload',
            ).then((_) => _loadResumes()),
        icon: const Icon(Icons.add),
        label: const Text('New Resume'),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 80,
            color: theme.colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text('No Resumes Yet', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Create your first resume to get started',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Create Resume',
            icon: Icons.add,
            onPressed:
                () => Navigator.pushNamed(
                  context,
                  '/resumes/upload',
                ).then((_) => _loadResumes()),
          ),
        ],
      ),
    );
  }

  Widget _buildResumeList(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _resumes.length,
      itemBuilder: (context, index) {
        final resume = _resumes[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap:
                () => Navigator.pushNamed(
                  context,
                  '/resumes/detail',
                  arguments: {'resumeId': resume.id.toString()},
                ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.description, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          resume.title ?? 'Untitled',
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'delete') {
                            _confirmDelete(resume.id);
                          }
                        },
                        itemBuilder:
                            (_) => [
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Created', style: theme.textTheme.bodySmall),
                            Text(
                              resume.createdAt
                                  .toLocal()
                                  .toIso8601String()
                                  .split('T')
                                  .first,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Applications',
                              style: theme.textTheme.bodySmall,
                            ),
                            Text(
                              resume.applications?.length.toString() ?? '0',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            title: const Text('Delete Resume'),
            content: const Text('Are you sure you want to delete this resume?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
    if (confirmed == true) {
      try {
        await _apiService.deleteResume(id.toString());
        setState(() => _resumes.removeWhere((r) => r.id == id));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Resume deleted')));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Delete failed: \$e')));
      }
    }
  }
}
