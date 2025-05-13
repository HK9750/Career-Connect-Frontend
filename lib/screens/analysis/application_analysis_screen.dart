import 'package:flutter/material.dart';
import 'dart:convert';

import '../../models/application.dart';
import '../../models/analysis.dart';
import '../../services/api_service.dart';
import '../../utils/logger.dart';
import '../../utils/theme.dart';

class ApplicationAnalysisScreen extends StatefulWidget {
  final String applicationId;

  const ApplicationAnalysisScreen({Key? key, required this.applicationId})
    : super(key: key);

  @override
  State<ApplicationAnalysisScreen> createState() =>
      _ApplicationAnalysisScreenState();
}

class _ApplicationAnalysisScreenState extends State<ApplicationAnalysisScreen> {
  bool _isLoading = true;
  Application? _application;
  Map<String, dynamic>? _feedback;

  @override
  void initState() {
    super.initState();
    _loadApplication();
  }

  Future<void> _loadApplication() async {
    try {
      final apiService = ApiService();
      final application = await apiService.getApplication(widget.applicationId);

      Map<String, dynamic>? feedback;
      if (application.analysis?.feedback != null) {
        feedback = jsonDecode(application.analysis!.feedback);
      }

      setState(() {
        _application = application;
        _feedback = feedback;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.e('Error loading application: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load application analysis: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resume Analysis')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _application?.analysis == null
              ? _buildNoAnalysisAvailable()
              : _buildAnalysisContent(),
    );
  }

  Widget _buildNoAnalysisAvailable() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 64,
            color: AppTheme.subtitleColor,
          ),
          const SizedBox(height: 16),
          Text(
            'No analysis available for this application',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'The resume has not been analyzed yet for this job position',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppTheme.subtitleColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisContent() {
    if (_feedback == null) {
      return Center(
        child: Text(
          'Analysis data format is invalid',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    final summary = _feedback!['summary'] as Map<String, dynamic>?;
    final keySkills = _feedback!['keySkills'] as Map<String, dynamic>?;
    final experienceAnalysis =
        _feedback!['experienceAnalysis'] as Map<String, dynamic>?;
    final educationFit = _feedback!['educationFit'] as Map<String, dynamic>?;
    final strengths = _feedback!['strengths'] as List<dynamic>?;
    final weaknesses = _feedback!['weaknesses'] as List<dynamic>?;
    final improvementSuggestions =
        _feedback!['improvementSuggestions'] as List<dynamic>?;
    final keywordMatch = _feedback!['keywordMatch'] as Map<String, dynamic>?;
    final formattingFeedback = _feedback!['formattingFeedback'] as String?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildScoreCard(summary),
          const SizedBox(height: 24),
          _buildSummarySection(summary),
          const SizedBox(height: 24),
          _buildSkillsSection(keySkills),
          const SizedBox(height: 24),
          _buildExperienceSection(experienceAnalysis),
          const SizedBox(height: 24),
          _buildEducationSection(educationFit),
          const SizedBox(height: 24),
          _buildStrengthsWeaknessesCard(strengths, weaknesses),
          const SizedBox(height: 24),
          _buildImprovementSuggestionsSection(improvementSuggestions),
          const SizedBox(height: 24),
          _buildKeywordMatchSection(keywordMatch),
          if (formattingFeedback != null) ...[
            const SizedBox(height: 24),
            _buildFormattingSection(formattingFeedback),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildScoreCard(Map<String, dynamic>? summary) {
    final score = summary?['overallMatch'] ?? '0';
    final scoreNum = double.tryParse(score.toString()) ?? 0;

    Color getScoreColor() {
      if (scoreNum >= 80) return AppTheme.successColor;
      if (scoreNum >= 60) return AppTheme.warningColor;
      return AppTheme.errorColor;
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Overall Match Score',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: getScoreColor().withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$score%',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(
                        color: getScoreColor(),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _application?.job?.title ?? 'Job Position',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              _application?.job?.company ?? 'Company',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection(Map<String, dynamic>? summary) {
    return _buildSection(
      title: 'Summary',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (summary?['briefAssessment'] != null) ...[
                Text(
                  summary!['briefAssessment'],
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const Divider(),
              ],
              if (summary?['experienceBuildingScalableBackendSystems'] !=
                  null) ...[
                const SizedBox(height: 8),
                Text(
                  'Experience with Scalable Backend Systems:',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  summary!['experienceBuildingScalableBackendSystems'],
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkillsSection(Map<String, dynamic>? keySkills) {
    final present = keySkills?['present'] as List<dynamic>? ?? [];
    final missing = keySkills?['missing'] as List<dynamic>? ?? [];

    return _buildSection(
      title: 'Key Skills',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Present skills section
              if (present.isNotEmpty) ...[
                Text(
                  'Present Skills:',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                // Simple wrap for present skills
                Wrap(
                  spacing: 8,
                  runSpacing: 12,
                  children:
                      present.map((skill) {
                        return Chip(
                          backgroundColor: AppTheme.successColor.withOpacity(
                            0.2,
                          ),
                          label: Text(
                            skill.toString(),
                            style: TextStyle(color: AppTheme.successColor),
                          ),
                        );
                      }).toList(),
                ),
              ],

              // Missing skills section - fixed to display properly
              if (missing.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Missing Skills:',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // Remove the Container with fixed height and use a simple Wrap
                Wrap(
                  spacing: 8,
                  runSpacing: 12,
                  children:
                      missing.map((skill) {
                        return Chip(
                          backgroundColor: AppTheme.errorColor.withOpacity(0.2),
                          label: Text(
                            skill.toString(),
                            style: TextStyle(color: AppTheme.errorColor),
                          ),
                        );
                      }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExperienceSection(Map<String, dynamic>? experienceAnalysis) {
    final relevantExperience =
        experienceAnalysis?['relevantExperience'] as List<dynamic>? ?? [];
    final gaps = experienceAnalysis?['gaps'] as List<dynamic>? ?? [];

    return _buildSection(
      title: 'Experience Analysis',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (relevantExperience.isNotEmpty) ...[
                Text(
                  'Relevant Experience:',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...relevantExperience.map((exp) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: AppTheme.successColor,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            exp.toString(),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
              if (gaps.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Experience Gaps:',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...gaps.map((gap) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppTheme.warningColor,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            gap.toString(),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEducationSection(Map<String, dynamic>? educationFit) {
    final match = educationFit?['match'] ?? '';
    final details = educationFit?['details'] ?? '';

    Color getMatchColor() {
      if (match == 'Strong') return AppTheme.successColor;
      if (match == 'Moderate') return AppTheme.warningColor;
      if (match == 'Weak') return AppTheme.errorColor;
      return AppTheme.secondaryColor;
    }

    return _buildSection(
      title: 'Education Fit',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: getMatchColor().withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      match,
                      style: TextStyle(
                        color: getMatchColor(),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(details, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStrengthsWeaknessesCard(
    List<dynamic>? strengths,
    List<dynamic>? weaknesses,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Strengths & Weaknesses',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.trending_up, color: AppTheme.successColor),
                          const SizedBox(width: 8),
                          Text(
                            'Strengths',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.successColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (strengths != null)
                        ...strengths.map((strength) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.check,
                                  color: AppTheme.successColor,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    strength.toString(),
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.trending_down, color: AppTheme.errorColor),
                          const SizedBox(width: 8),
                          Text(
                            'Weaknesses',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.errorColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (weaknesses != null)
                        ...weaknesses.map((weakness) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.close,
                                  color: AppTheme.errorColor,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    weakness.toString(),
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImprovementSuggestionsSection(
    List<dynamic>? improvementSuggestions,
  ) {
    if (improvementSuggestions == null || improvementSuggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSection(
      title: 'Improvement Suggestions',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:
                improvementSuggestions.map((suggestion) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: AppTheme.secondaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            suggestion.toString(),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildKeywordMatchSection(Map<String, dynamic>? keywordMatch) {
    if (keywordMatch == null) return const SizedBox.shrink();

    final score = keywordMatch['score'] ?? '0';
    final scoreNum = double.tryParse(score.toString()) ?? 0;
    final missingKeywords =
        keywordMatch['missingKeywords'] as List<dynamic>? ?? [];

    Color getScoreColor() {
      if (scoreNum >= 80) return AppTheme.successColor;
      if (scoreNum >= 60) return AppTheme.warningColor;
      return AppTheme.errorColor;
    }

    return _buildSection(
      title: 'Keyword Match',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: getScoreColor().withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$score%',
                        style: TextStyle(
                          color: getScoreColor(),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Your resume matches ${score}% of the keywords from the job description',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              if (missingKeywords.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Missing Keywords:',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      missingKeywords.map((keyword) {
                        return Chip(
                          backgroundColor: AppTheme.errorColor.withOpacity(0.2),
                          label: Text(
                            keyword.toString(),
                            style: TextStyle(color: AppTheme.errorColor),
                          ),
                        );
                      }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormattingSection(String formattingFeedback) {
    return _buildSection(
      title: 'Formatting Feedback',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            formattingFeedback,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
