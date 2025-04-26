import 'package:flutter/material.dart';
import 'package:frontend/utils/theme.dart';
import '../../models/job.dart';
import '../../services/api_service.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_view.dart';
import 'job_detail_screen.dart';

class JobListScreen extends StatefulWidget {
  const JobListScreen({Key? key}) : super(key: key);

  @override
  State<JobListScreen> createState() => _JobListScreenState();
}

class _JobListScreenState extends State<JobListScreen> {
  late Future<List<Job>> _jobsFuture;
  final ApiService _apiService = ApiService();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  void _loadJobs() {
    _jobsFuture = _apiService.fetchJobs();
  }

  List<Job> _filterJobs(List<Job> jobs) {
    if (_searchQuery.isEmpty) {
      return jobs;
    }
    return jobs.where((job) {
      return job.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          job.company.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          job.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (job.location != null &&
              job.location!.toLowerCase().contains(_searchQuery.toLowerCase()));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Available Jobs')),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: FutureBuilder<List<Job>>(
              future: _jobsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingIndicator();
                } else if (snapshot.hasError) {
                  return ErrorView(
                    error: 'Error loading jobs: ${snapshot.error}',
                    onRetry: () {
                      setState(() {
                        _loadJobs();
                      });
                    },
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('No jobs available at the moment.'),
                  );
                } else {
                  final filteredJobs = _filterJobs(snapshot.data!);
                  return _buildJobList(filteredJobs);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search jobs by title, company, or location',
          prefixIcon: const Icon(Icons.search),
          suffixIcon:
              _searchQuery.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  )
                  : null,
        ),
      ),
    );
  }

  Widget _buildJobList(List<Job> jobs) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _loadJobs();
        });
      },
      child:
          jobs.isEmpty
              ? Center(
                child: Text(
                  'No jobs match your search criteria.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                itemCount: jobs.length,
                itemBuilder: (context, index) {
                  final job = jobs[index];
                  return _buildJobCard(job);
                },
              ),
    );
  }

  Widget _buildJobCard(Job job) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => JobDetailScreen()),
          ).then((_) {
            // Refresh jobs list when returning from detail screen
            setState(() {
              _loadJobs();
            });
          });
        },
        borderRadius: BorderRadius.circular(16.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      job.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppTheme.accentColor,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.business,
                    size: 16,
                    color: AppTheme.subtitleColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    job.company,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: AppTheme.subtitleColor,
                    ),
                  ),
                ],
              ),
              if (job.location != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 16,
                      color: AppTheme.subtitleColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      job.location!,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: AppTheme.subtitleColor,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Text(
                job.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (job.tags != null && job.tags!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      job.tags!.map((tag) {
                        return Chip(
                          label: Text(
                            tag,
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: AppTheme.accentColor.withOpacity(
                            0.2,
                          ),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        );
                      }).toList(),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'Posted on ${_formatDate(job.createdAt)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
