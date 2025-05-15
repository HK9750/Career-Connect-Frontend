import 'package:flutter/material.dart';
import 'package:frontend/utils/logger.dart';
import 'package:provider/provider.dart';
import 'package:frontend/utils/theme.dart';
import '../../models/job.dart';
import '../../services/api_service.dart';
import '../../widgets/loading_indicator.dart';
import '../../services/auth_provider.dart';
import '../../widgets/error_view.dart';

class UpdateJobScreen extends StatefulWidget {
  const UpdateJobScreen({Key? key}) : super(key: key);

  @override
  State<UpdateJobScreen> createState() => _UpdateJobScreenState();
}

class _UpdateJobScreenState extends State<UpdateJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _companyController = TextEditingController();
  final _locationController = TextEditingController();
  final _tagsController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  late String _jobId;
  Job? _job;

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    // Delay the loading of job details until after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadJobDetails();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _companyController.dispose();
    _locationController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  // In _UpdateJobScreenState class, update the _loadJobDetails method

  Future<void> _loadJobDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get jobId from route arguments
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args == null) {
        throw Exception('Job ID is missing from route arguments');
      }

      // Store the jobId directly without casting to String
      // This will work whether jobId is an int or String
      _jobId = args.toString();
      AppLogger.d('Loading job details for job ID: $_jobId');

      // Fetch job details
      final job = await _apiService.getJob(_jobId);
      _job = job;

      // Populate form fields
      _titleController.text = job.title;
      _descriptionController.text = job.description;
      _companyController.text = job.company;
      _locationController.text = job.location ?? '';

      // Convert tags list to comma-separated string
      if (job.tags != null && job.tags!.isNotEmpty) {
        _tagsController.text = job.tags!.join(', ');
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.e('Error loading job details: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load job details: ${e.toString()}';
        });
      }
    }
  }

  // Convert comma-separated tags to a list
  List<String>? _parseTagsToList(String? tagsString) {
    if (tagsString == null || tagsString.isEmpty) {
      return null;
    }

    // Split by comma, trim whitespace, and filter out empty strings
    return tagsString
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
        _errorMessage = null;
      });

      try {
        // Parse tags from comma-separated string to List<String>
        final List<String>? tags = _parseTagsToList(_tagsController.text);

        // Prepare update data
        final Map<String, dynamic> updateData = {
          'title': _titleController.text,
          'description': _descriptionController.text,
          'company': _companyController.text,
          'location':
              _locationController.text.isNotEmpty
                  ? _locationController.text
                  : null,
          'tags': tags,
        };

        // Update job
        final updatedJob = await _apiService.updateJob(_jobId, updateData);

        if (mounted) {
          setState(() {
            _isSaving = false;
            _job = updatedJob;
          });

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Job updated successfully!'),
              backgroundColor: AppTheme.successColor,
              behavior: SnackBarBehavior.floating,
            ),
          );

          // Go back to previous screen with the updated job
          Navigator.pop(context, updatedJob);
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isSaving = false;
            _errorMessage = e.toString();
          });

          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_errorMessage ?? 'Failed to update job'),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);

    // Check if user is authenticated and is a recruiter
    if (!authProvider.isAuthenticated ||
        authProvider.user?.role != 'RECRUITER') {
      // Redirect to login or show unauthorized message
      return Scaffold(
        appBar: AppBar(title: const Text('Unauthorized')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 64, color: AppTheme.errorColor),
              const SizedBox(height: 16),
              Text(
                'You are not authorized to edit job listings.',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Only recruiters can edit job listings.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.subtitleColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Update Job'), elevation: 0),
      body:
          _isLoading
              ? const LoadingIndicator()
              : _isSaving
              ? const LoadingIndicator()
              : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header
                        Text(
                          'Edit Job Details',
                          style: theme.textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Update the information below to edit this job listing.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.subtitleColor,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Error message (if any)
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.errorColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.errorColor.withOpacity(0.5),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: AppTheme.errorColor,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: AppTheme.errorColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Title field
                        _buildSectionHeader('Job Title', true),
                        _buildTextField(
                          controller: _titleController,
                          hintText: 'e.g. Senior Flutter Developer',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Job title is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Company field
                        _buildSectionHeader('Company', true),
                        _buildTextField(
                          controller: _companyController,
                          hintText: 'e.g. Tech Solutions Inc.',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Company name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Location field
                        _buildSectionHeader('Location', false),
                        _buildTextField(
                          controller: _locationController,
                          hintText: 'e.g. Remote, New York, NY',
                          prefixIcon: const Icon(Icons.location_on_outlined),
                        ),
                        const SizedBox(height: 24),

                        // Tags field
                        _buildSectionHeader('Tags', false),
                        _buildTextField(
                          controller: _tagsController,
                          hintText: 'e.g. flutter, mobile, remote',
                          prefixIcon: const Icon(Icons.tag),
                          helperText:
                              'Comma-separated list of tags (e.g. flutter,mobile,web)',
                        ),
                        const SizedBox(height: 24),

                        // Description field
                        _buildSectionHeader('Job Description', true),
                        _buildTextField(
                          controller: _descriptionController,
                          hintText:
                              'Describe the job responsibilities, requirements, and benefits...',
                          maxLines: 8,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Job description is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 36),

                        // Submit button
                        ElevatedButton(
                          onPressed: _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('UPDATE JOB'),
                        ),
                        const SizedBox(height: 16),

                        // Cancel button
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.accentColor,
                            side: const BorderSide(
                              color: AppTheme.accentColor,
                              width: 2,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('CANCEL'),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }

  Widget _buildSectionHeader(String title, bool isRequired) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          if (isRequired) ...[
            const SizedBox(width: 4),
            Text(
              '*',
              style: TextStyle(
                color: AppTheme.errorColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    String? Function(String?)? validator,
    String? helperText,
    Widget? prefixIcon,
    int maxLines = 1,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: prefixIcon,
        helperText: helperText,
        helperMaxLines: 2,
        fillColor: isDarkMode ? const Color(0xFF3A4A5C) : Colors.white,
        filled: true,
      ),
      maxLines: maxLines,
      validator: validator,
    );
  }
}
