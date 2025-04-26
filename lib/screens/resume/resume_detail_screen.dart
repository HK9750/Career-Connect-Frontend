import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/custom_button.dart';

class ResumeDetailScreen extends StatefulWidget {
  const ResumeDetailScreen({Key? key}) : super(key: key);

  @override
  State<ResumeDetailScreen> createState() => _ResumeDetailScreenState();
}

class _ResumeDetailScreenState extends State<ResumeDetailScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _resumeData;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadResumeData();
    });
  }

  Future<void> _loadResumeData() async {
    setState(() {
      _isLoading = true;
    });

    // Get the resume ID from the route arguments
    final Map<String, dynamic> args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final String resumeId = args['resumeId'];

    // Simulate API request
    await Future.delayed(const Duration(milliseconds: 800));

    // Mock data
    setState(() {
      _resumeData = {
        'id': resumeId,
        'title': 'Software Developer Resume',
        'createdAt': '2025-02-15',
        'lastUpdated': '2025-04-20',
        'applications': 3,
        'fileUrl': 'https://example.com/resume.pdf',
        'fileName': 'JohnDoe_Developer_Resume.pdf',
        'fileSize': '245 KB',
        'sections': [
          {
            'title': 'Personal Information',
            'data': {
              'name': 'John Doe',
              'email': 'john.doe@example.com',
              'phone': '+1 (555) 123-4567',
              'location': 'San Francisco, CA',
              'portfolio': 'https://johndoe.dev',
              'linkedin': 'linkedin.com/in/johndoe',
            },
          },
          {
            'title': 'Education',
            'data': [
              {
                'institution': 'University of California, Berkeley',
                'degree': 'Bachelor of Science in Computer Science',
                'date': '2018 - 2022',
                'gpa': '3.8/4.0',
              },
            ],
          },
          {
            'title': 'Work Experience',
            'data': [
              {
                'company': 'Tech Innovations Inc',
                'role': 'Software Developer',
                'date': 'June 2022 - Present',
                'description':
                    'Developed and maintained web applications using React and Node.js. Collaborated with cross-functional teams to implement new features and fix bugs.',
              },
              {
                'company': 'StartUp Labs',
                'role': 'Software Development Intern',
                'date': 'May 2021 - August 2021',
                'description':
                    'Assisted in the development of mobile applications using Flutter and Firebase. Participated in daily stand-ups and code reviews.',
              },
            ],
          },
          {
            'title': 'Skills',
            'data': [
              'JavaScript',
              'TypeScript',
              'React',
              'Node.js',
              'Flutter',
              'Dart',
              'Python',
              'Git',
              'AWS',
              'Docker',
              'SQL',
              'NoSQL',
            ],
          },
        ],
      };
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _resumeData?.containsKey('title') ?? false
              ? _resumeData!['title']
              : 'Resume Details',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Navigate to edit screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Edit functionality will be implemented soon'),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Implement share functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Share functionality will be implemented soon'),
                ),
              );
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _resumeData == null
              ? Center(
                child: Text(
                  'Failed to load resume data',
                  style: theme.textTheme.bodyLarge,
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFileInfoCard(theme),
                    const SizedBox(height: 24),

                    Text(
                      'Resume Content',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),

                    // Display resume sections
                    ..._resumeData!['sections'].map<Widget>((section) {
                      return _buildSectionCard(theme, section);
                    }).toList(),

                    const SizedBox(height: 24),

                    // Applications section
                    Text('Applications', style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 16),

                    _resumeData!['applications'] > 0
                        ? Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'This resume has been used in ${_resumeData!['applications']} job applications',
                                  style: theme.textTheme.bodyLarge,
                                ),
                                const SizedBox(height: 16),
                                CustomButton(
                                  text: 'View Applications',
                                  icon: Icons.visibility,
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/applications',
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        )
                        : Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'This resume has not been used in any applications yet',
                                  style: theme.textTheme.bodyLarge,
                                ),
                                const SizedBox(height: 16),
                                CustomButton(
                                  text: 'Browse Jobs',
                                  icon: Icons.work_outline,
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/jobs');
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                  ],
                ),
              ),
    );
  }

  Widget _buildFileInfoCard(ThemeData theme) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.picture_as_pdf,
                    color: theme.colorScheme.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _resumeData!['fileName'],
                        style: theme.textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Size: ${_resumeData!['fileSize']}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.remove_red_eye),
                    label: const Text('Preview'),
                    onPressed: () {
                      // TODO: Implement preview functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Preview functionality will be implemented soon',
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.download),
                    label: const Text('Download'),
                    onPressed: () {
                      // TODO: Implement download functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Download functionality will be implemented soon',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(ThemeData theme, Map<String, dynamic> section) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              section['title'],
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            _buildSectionContent(theme, section),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionContent(ThemeData theme, Map<String, dynamic> section) {
    final data = section['data'];

    if (data is Map<String, dynamic>) {
      // Personal information section
      return Column(
        children:
            data.entries.map<Widget>((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        '${entry.key.substring(0, 1).toUpperCase()}${entry.key.substring(1)}:',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
      );
    } else if (data is List &&
        data.isNotEmpty &&
        data.first is Map<String, dynamic>) {
      // Education or work experience sections
      return Column(
        children:
            data.map<Widget>((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.containsKey('institution') ||
                        item.containsKey('company'))
                      Text(
                        item['institution'] ?? item['company'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    if (item.containsKey('degree') || item.containsKey('role'))
                      Text(
                        item['degree'] ?? item['role'],
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    if (item.containsKey('date'))
                      Text(item['date'], style: theme.textTheme.bodySmall),
                    if (item.containsKey('gpa'))
                      Text(
                        'GPA: ${item['gpa']}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    if (item.containsKey('description'))
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          item['description'],
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    if (data.indexOf(item) < data.length - 1)
                      const Divider(height: 24),
                  ],
                ),
              );
            }).toList(),
      );
    } else if (data is List) {
      // Skills section
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children:
            data.map<Widget>((skill) {
              return Chip(
                label: Text(skill),
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                side: BorderSide(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                ),
              );
            }).toList(),
      );
    }

    return const SizedBox.shrink();
  }
}
