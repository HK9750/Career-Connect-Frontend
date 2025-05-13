import 'package:flutter/material.dart';
import '../../models/review.dart';
import '../../models/application.dart';
import '../../services/api_service.dart';
import '../../utils/logger.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_view.dart';
import '../../utils/theme.dart';

class RecruiterReviewScreen extends StatefulWidget {
  final String applicationId;

  const RecruiterReviewScreen({Key? key, required this.applicationId})
    : super(key: key);

  @override
  _RecruiterReviewScreenState createState() => _RecruiterReviewScreenState();
}

class _RecruiterReviewScreenState extends State<RecruiterReviewScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _commentController = TextEditingController();
  bool _isLoading = false;
  bool _isSubmitting = false;
  Review? _review;
  Application? _application;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load application details
      final application = await _apiService.getApplication(
        widget.applicationId,
      );
      setState(() {
        _application = application;
      });

      // Try to load existing review
      try {
        final review = await _apiService.fetchReview(widget.applicationId);
        setState(() {
          _review = review;
          _commentController.text = review.comment!;
        });
      } catch (e) {
        // No review exists yet, which is fine
        AppLogger.i('No existing review found: $e');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load application data: $e';
      });
      AppLogger.e('Error loading application data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _submitOrUpdateReview() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a review comment'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final comment = _commentController.text.trim();
      Review review;

      // Determine if this is a new review or an update to an existing one
      if (_review != null) {
        // Update existing review
        review = await _apiService.updateReview(widget.applicationId, comment);
      } else {
        // Submit new review
        review = await _apiService.submitReview(widget.applicationId, comment);
      }

      setState(() {
        _review = review;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _review != null
                  ? 'Review updated successfully'
                  : 'Review submitted successfully',
            ),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      AppLogger.e('Error submitting/updating review: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to ${_review != null ? 'update' : 'submit'} review: ${e.toString()}',
            ),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _deleteReview() async {
    if (_review == null) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Review'),
            content: const Text(
              'Are you sure you want to delete this review? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                ),
                child: const Text('DELETE'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _apiService.deleteReview(widget.applicationId);

      setState(() {
        _review = null;
        _commentController.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Review deleted successfully'),
            backgroundColor: AppTheme.accentColor,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      AppLogger.e('Error deleting review: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete review: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Widget _buildApplicationHeader() {
    if (_application == null) {
      return const SizedBox.shrink();
    }

    final applicant = _application!.applicant;
    final job = _application!.job;

    if (applicant == null || job == null) {
      return Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppTheme.errorColor),
              const SizedBox(width: 8),
              const Text('Missing application data'),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Applicant info section
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: 'applicant-avatar-${applicant.id}',
                  child: CircleAvatar(
                    backgroundColor: AppTheme.primaryColor,
                    radius: 24,
                    child: Text(
                      applicant.username.isNotEmpty
                          ? applicant.username[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        applicant.username,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Email with overflow handling
                      Row(
                        children: [
                          Icon(
                            Icons.email_outlined,
                            size: 14,
                            color: AppTheme.subtitleColor,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              applicant.email,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppTheme.subtitleColor),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Job info section
            Text(
              'Application for:',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.subtitleColor),
            ),
            const SizedBox(height: 4),
            Text(
              job.title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
            const SizedBox(height: 8),

            // Company and location with better layout
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.business,
                      size: 16,
                      color: AppTheme.subtitleColor,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        job.company,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.subtitleColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: AppTheme.subtitleColor,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        job.location ?? 'Remote',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.subtitleColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Status and date in wrap to prevent overflow
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(
                      _application!.status,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getStatusColor(
                        _application!.status,
                      ).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _application!.status,
                    style: TextStyle(
                      color: _getStatusColor(_application!.status),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: AppTheme.subtitleColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Applied on: ${_formatDate(_application!.createdAt)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.subtitleColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewForm() {
    final bool isEditing = _review != null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and delete button
            Row(
              children: [
                Icon(
                  isEditing ? Icons.edit : Icons.add_comment,
                  color:
                      isEditing ? AppTheme.accentColor : AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isEditing ? 'Edit Review' : 'Add Review',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color:
                          isEditing
                              ? AppTheme.accentColor
                              : AppTheme.primaryColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isEditing)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    color: AppTheme.errorColor,
                    tooltip: 'Delete review',
                    onPressed: _isSubmitting ? null : _deleteReview,
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Character count indicator
            AnimatedBuilder(
              animation: _commentController,
              builder: (context, child) {
                final int charCount = _commentController.text.length;
                final bool isLongEnough = charCount >= 10;

                return Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Characters: $charCount ${isLongEnough ? "✓" : "(minimum 10)"}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isLongEnough ? Colors.green : Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),

            // Review text field
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Enter your review comments here...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.all(16),
                isDense: true, // More compact text field
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color:
                        isEditing
                            ? AppTheme.accentColor
                            : AppTheme.primaryColor.withOpacity(0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color:
                        isEditing
                            ? AppTheme.accentColor
                            : AppTheme.primaryColor,
                    width: 2,
                  ),
                ),
              ),
              maxLines: 8,
              enabled: !_isSubmitting,
              onChanged: (_) => setState(() {}), // Refresh for character count
            ),
            const SizedBox(height: 16),

            // Bottom row with updated date and submit button
            LayoutBuilder(
              builder: (context, constraints) {
                // For narrow screens, stack the elements vertically
                if (constraints.maxWidth < 400) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (isEditing)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            'Last updated: ${_formatDate(_review!.createdAt ?? DateTime.now())}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(fontStyle: FontStyle.italic),
                            textAlign: TextAlign.start,
                          ),
                        ),
                      ElevatedButton.icon(
                        onPressed:
                            _isSubmitting ||
                                    _commentController.text.trim().length < 10
                                ? null
                                : _submitOrUpdateReview,
                        icon: Icon(isEditing ? Icons.save : Icons.send),
                        label: Text(
                          isEditing ? 'Update Review' : 'Submit Review',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isEditing
                                  ? AppTheme.accentColor
                                  : AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          disabledBackgroundColor: Colors.grey.shade300,
                          disabledForegroundColor: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  );
                }

                // For wider screens, keep the row layout
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (isEditing)
                      Flexible(
                        child: Text(
                          'Last updated: ${_formatDate(_review!.createdAt ?? DateTime.now())}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontStyle: FontStyle.italic),
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    else
                      const Spacer(),
                    ElevatedButton.icon(
                      onPressed:
                          _isSubmitting ||
                                  _commentController.text.trim().length < 10
                              ? null
                              : _submitOrUpdateReview,
                      icon: Icon(isEditing ? Icons.save : Icons.send),
                      label: Text(
                        isEditing ? 'Update Review' : 'Submit Review',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isEditing
                                ? AppTheme.accentColor
                                : AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        disabledBackgroundColor: Colors.grey.shade300,
                        disabledForegroundColor: Colors.grey.shade500,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'APPLIED':
        return AppTheme.accentColor;
      case 'REVIEWED':
        return AppTheme.warningColor;
      case 'ACCEPTED':
        return AppTheme.successColor;
      case 'REJECTED':
        return AppTheme.errorColor;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Application Review',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            if (_isLoading)
              const LoadingIndicator()
            else if (_errorMessage != null)
              ErrorView(error: _errorMessage!, onRetry: _loadData)
            else
              RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 24),
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildApplicationHeader(),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Text(
                          'Recruiter Review',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      _buildReviewForm(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            if (_isSubmitting)
              Container(
                color: Colors.black45,
                child: const Center(
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
