import 'package:flutter/material.dart';
import 'package:frontend/utils/theme.dart';
import '../../models/job.dart';
import '../../services/api_service.dart';
import '../../widgets/loading_indicator.dart';

class CreateJobScreen extends StatefulWidget {
  const CreateJobScreen({Key? key}) : super(key: key);

  @override
  State<CreateJobScreen> createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends State<CreateJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _companyController = TextEditingController();
  final _locationController = TextEditingController();
  final _tagsController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  final ApiService _apiService = ApiService();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _companyController.dispose();
    _locationController.dispose();
    _tagsController.dispose();
    super.dispose();
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
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        // Parse tags from comma-separated string to List<String>
        final List<String>? tags = _parseTagsToList(_tagsController.text);

        final job = await _apiService.createJob(
          _titleController.text,
          _descriptionController.text,
          _companyController.text,
          _locationController.text.isNotEmpty ? _locationController.text : null,
          tags, // Now passing tags as a List<String>
        );

        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Job created successfully!'),
              backgroundColor: AppTheme.successColor,
              behavior: SnackBarBehavior.floating,
            ),
          );

          // Go back to previous screen with the new job
          Navigator.pop(context, job);
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = e.toString();
          });

          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_errorMessage ?? 'Failed to create job'),
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

    return Scaffold(
      appBar: AppBar(title: const Text('Create New Job'), elevation: 0),
      body:
          _isLoading
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
                          'Job Details',
                          style: theme.textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Fill in the information below to post a new job.',
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
                          child: const Text('POST JOB'),
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
