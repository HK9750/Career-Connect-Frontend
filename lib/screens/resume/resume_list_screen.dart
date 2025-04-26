import 'package:flutter/material.dart';
import '../../widgets/custom_button.dart';

class ResumeListScreen extends StatefulWidget {
  const ResumeListScreen({Key? key}) : super(key: key);

  @override
  State<ResumeListScreen> createState() => _ResumeListScreenState();
}

class _ResumeListScreenState extends State<ResumeListScreen> {
  final List<Map<String, dynamic>> _mockResumes = [
    {
      'id': '1',
      'title': 'Software Developer Resume',
      'createdAt': '2025-02-15',
      'lastUpdated': '2025-04-20',
      'applications': 3,
    },
    {
      'id': '2',
      'title': 'Front-end Developer Resume',
      'createdAt': '2025-03-05',
      'lastUpdated': '2025-04-15',
      'applications': 2,
    },
    {
      'id': '3',
      'title': 'Mobile Developer Resume',
      'createdAt': '2025-04-01',
      'lastUpdated': '2025-04-01',
      'applications': 0,
    },
  ];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadResumes();
  }

  Future<void> _loadResumes() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate API request
    await Future.delayed(const Duration(milliseconds: 800));

    // TODO: Replace with actual API call
    // final resumes = await resumeService.getResumes();
    // setState(() {
    //   _resumes = resumes;
    // });

    setState(() {
      _isLoading = false;
    });
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
                    _mockResumes.isEmpty
                        ? _buildEmptyState(theme)
                        : _buildResumeList(theme),
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/resumes/upload');
        },
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
            onPressed: () {
              Navigator.pushNamed(context, '/resumes/upload');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResumeList(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _mockResumes.length,
      itemBuilder: (context, index) {
        final resume = _mockResumes[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/resumes/detail',
                arguments: {'resumeId': resume['id']},
              );
            },
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
                          resume['title'],
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            // TODO: Navigate to edit screen
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Edit functionality will be implemented soon',
                                ),
                              ),
                            );
                          } else if (value == 'delete') {
                            _showDeleteConfirmationDialog(
                              context,
                              resume['id'],
                            );
                          }
                        },
                        itemBuilder:
                            (BuildContext context) => [
                              const PopupMenuItem<String>(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem<String>(
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
                              resume['createdAt'],
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Last Updated',
                              style: theme.textTheme.bodySmall,
                            ),
                            Text(
                              resume['lastUpdated'],
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Applications',
                              style: theme.textTheme.bodySmall,
                            ),
                            Text(
                              resume['applications'].toString(),
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

  Future<void> _showDeleteConfirmationDialog(
    BuildContext context,
    String resumeId,
  ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text(
            'Are you sure you want to delete this resume? This action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                // TODO: Implement delete functionality
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Resume deleted successfully')),
                );
                // After successful deletion
                setState(() {
                  _mockResumes.removeWhere(
                    (element) => element['id'] == resumeId,
                  );
                });
              },
            ),
          ],
        );
      },
    );
  }
}
