import 'package:flutter/material.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class UploadResumeScreen extends StatefulWidget {
  const UploadResumeScreen({Key? key}) : super(key: key);

  @override
  State<UploadResumeScreen> createState() => _UploadResumeScreenState();
}

class _UploadResumeScreenState extends State<UploadResumeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  String? _selectedFile;
  bool _isUploading = false;
  int _activeStep = 0;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _selectFile() {
    // Simulate file selection
    setState(() {
      _selectedFile = 'JohnDoe_Resume.pdf';
    });
  }

  Future<void> _uploadResume() async {
    if (_formKey.currentState!.validate() && _selectedFile != null) {
      setState(() {
        _isUploading = true;
      });

      // Simulate API request
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _isUploading = false;
        _activeStep = 1; // Move to success step
      });
    } else if (_selectedFile == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a file')));
    }
  }

  void _goToNextStep() {
    // Navigate back to job listings or to another screen
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Resume')),
      body: _activeStep == 0 ? _buildUploadForm() : _buildSuccessScreen(),
    );
  }

  Widget _buildUploadForm() {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Upload Your Resume', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Upload your resume to apply for jobs. We support PDF, DOCX, and TXT formats.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),

            // Title field
            CustomTextField(
              controller: _titleController,
              hintText: 'Resume Title',
              labelText: 'Title',
              prefixIcon: Icons.title,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title for your resume';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // File Upload Section
            Text('Upload File', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    if (_selectedFile == null) ...[
                      // File selection prompt
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.primary.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.cloud_upload_outlined,
                              size: 48,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Drag and drop your file here',
                              style: theme.textTheme.bodyLarge,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'or',
                              style: theme.textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.file_present),
                              label: const Text('Browse Files'),
                              onPressed: _selectFile,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Supported formats: PDF, DOCX, TXT (Max size: 5MB)',
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ] else ...[
                      // Selected file display
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.picture_as_pdf,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedFile!,
                                  style: theme.textTheme.titleMedium,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '245 KB',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () {
                              setState(() {
                                _selectedFile = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your resume will be parsed automatically to extract information such as education, work experience, and skills.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 32),

            // Upload Button
            CustomButton(
              text: 'Upload Resume',
              icon: Icons.upload_file,
              isLoading: _isUploading,
              onPressed: _uploadResume,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessScreen() {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline,
                size: 64,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Resume Uploaded Successfully!',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Your resume "${_titleController.text}" has been uploaded and added to your profile.',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'We\'ve automatically parsed your resume to extract education, experience, and skills, which you can edit in your profile.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'View Job Listings',
              icon: Icons.work_outline,
              onPressed: _goToNextStep,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                setState(() {
                  _activeStep = 0;
                  _selectedFile = null;
                  _titleController.clear();
                });
              },
              child: const Text('Upload Another Resume'),
            ),
          ],
        ),
      ),
    );
  }
}
