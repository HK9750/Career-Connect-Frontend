import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_selector/file_selector.dart';

import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../services/api_service.dart';
import '../../models/resume.dart';
import '../../utils/theme.dart';

class UploadResumeScreen extends StatefulWidget {
  const UploadResumeScreen({Key? key}) : super(key: key);

  @override
  State<UploadResumeScreen> createState() => _UploadResumeScreenState();
}

class _UploadResumeScreenState extends State<UploadResumeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _apiService = ApiService();

  File? _selectedFile;
  Uint8List? _webFileBytes;
  String? _fileName;
  bool _isUploading = false;
  int _activeStep = 0;
  Resume? _uploadedResume;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final documentType = XTypeGroup(
        label: 'documents',
        extensions: ['pdf', 'docx'],
        mimeTypes: [
          'application/pdf',
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        ],
      );

      final XFile? file = await openFile(acceptedTypeGroups: [documentType]);
      if (file == null) return; // user cancelled

      setState(() => _fileName = file.name);

      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        setState(() => _webFileBytes = bytes);
      } else {
        setState(() => _selectedFile = File(file.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error selecting file: $e')));
    }
  }

  String _getFileSize() {
    if (kIsWeb && _webFileBytes != null) {
      final kb = _webFileBytes!.length / 1024;
      return '${kb.toStringAsFixed(1)} KB';
    } else if (_selectedFile != null) {
      final kb = _selectedFile!.lengthSync() / 1024;
      return '${kb.toStringAsFixed(0)} KB';
    }
    return '';
  }

  IconData _getFileIcon() {
    if (_fileName == null) return Icons.insert_drive_file;
    final ext = _fileName!.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }

  Future<void> _uploadResume() async {
    if (!_formKey.currentState!.validate() ||
        (_selectedFile == null && _webFileBytes == null)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a file')));
      return;
    }

    setState(() => _isUploading = true);

    try {
      // always call uploadResume; inside ApiService you can detect kIsWeb
      _uploadedResume = await _apiService.uploadResume(
        _titleController.text,
        // if web, wrap bytes in a temporary file or use a separate uploadResumeWeb
        // but ideally your ApiService.uploadResume handles both
        _selectedFile!,
      );

      setState(() => _activeStep = 1);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error uploading resume: $e')));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _goToNextStep() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackgroundColor,
      appBar: AppBar(
        title: const Text('Upload Resume'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: _activeStep == 0 ? _buildUploadForm() : _buildSuccessScreen(),
    );
  }

  Widget _buildUploadForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upload Your Resume',
              style: AppTheme.lightTheme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'We support PDF and DOCX formats.',
              style: AppTheme.lightTheme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),

            // Title field
            CustomTextField(
              controller: _titleController,
              hintText: 'Resume Title',
              labelText: 'Title',
              prefixIcon: Icons.title,
              validator:
                  (value) =>
                      (value == null || value.isEmpty)
                          ? 'Please enter a title'
                          : null,
            ),
            const SizedBox(height: 24),

            // File upload section
            Text(
              'Upload File',
              style: AppTheme.lightTheme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Card(
              color: AppTheme.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: AppTheme.accentColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child:
                    _selectedFile == null && _webFileBytes == null
                        ? _buildFilePrompt()
                        : _buildFilePreview(),
              ),
            ),
            const SizedBox(height: 32),

            // Upload button
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

  Widget _buildFilePrompt() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.accentColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.accentColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(Icons.upload_file, size: 48, color: AppTheme.accentColor),
              const SizedBox(height: 16),
              Text(
                'Select a file from your device',
                style: AppTheme.lightTheme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.file_present),
                label: const Text('Browse Files'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                ),
                onPressed: _pickFile,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Supported formats: PDF, DOCX (Max size: 5MB)',
          style: AppTheme.lightTheme.textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFilePreview() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.accentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(_getFileIcon(), color: AppTheme.accentColor),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _fileName ?? 'Selected File',
                style: AppTheme.lightTheme.textTheme.titleMedium,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                _getFileSize(),
                style: AppTheme.lightTheme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
          onPressed:
              () => setState(() {
                _selectedFile = null;
                _webFileBytes = null;
                _fileName = null;
              }),
        ),
      ],
    );
  }

  Widget _buildSuccessScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline,
                size: 64,
                color: AppTheme.successColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Resume Uploaded Successfully!',
              style: AppTheme.lightTheme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Your resume "${_titleController.text}" has been uploaded.',
              style: AppTheme.lightTheme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'View Job Listings',
              icon: Icons.work_outline,
              onPressed: _goToNextStep,
            ),
          ],
        ),
      ),
    );
  }
}
