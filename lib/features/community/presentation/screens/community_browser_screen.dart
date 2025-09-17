import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/models/task.dart';
import '../../../tasks/domain/repositories/task_repository.dart';
import '../bloc/community_bloc.dart';
import '../widgets/community_task_card.dart';
import 'submit_task_screen.dart';

class CommunityBrowserScreen extends StatelessWidget {
  const CommunityBrowserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CommunityBloc(
        taskRepository: sl<TaskRepository>(),
      )..add(LoadCommunityTasks()),
      child: const CommunityBrowserView(),
    );
  }
}

class CommunityBrowserView extends StatefulWidget {
  const CommunityBrowserView({super.key});

  @override
  State<CommunityBrowserView> createState() => _CommunityBrowserViewState();
}

class _CommunityBrowserViewState extends State<CommunityBrowserView> {
  final _searchController = TextEditingController();
  TaskType? _selectedFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      context.read<CommunityBloc>().add(LoadCommunityTasks());
    } else {
      context.read<CommunityBloc>().add(SearchCommunityTasks(query: query));
    }
  }

  void _onFilterChanged(TaskType? taskType) {
    setState(() {
      _selectedFilter = taskType;
    });
    context.read<CommunityBloc>().add(FilterTasksByType(taskType: taskType));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Tasks'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SubmitTaskScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            tooltip: 'Submit Task',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search community tasks...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                            icon: const Icon(Icons.clear),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: _onSearchChanged,
                ),
                const SizedBox(height: 12),
                
                // Filter Chips
                Row(
                  children: [
                    Text(
                      'Filter:',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('All'),
                      selected: _selectedFilter == null,
                      onSelected: (_) => _onFilterChanged(null),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Video'),
                      selected: _selectedFilter == TaskType.video,
                      onSelected: (_) => _onFilterChanged(TaskType.video),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Puzzle'),
                      selected: _selectedFilter == TaskType.puzzle,
                      onSelected: (_) => _onFilterChanged(TaskType.puzzle),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tasks List
          Expanded(
            child: BlocBuilder<CommunityBloc, CommunityState>(
              builder: (context, state) {
                if (state is CommunityLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (state is CommunityError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Something went wrong',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.message,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            context.read<CommunityBloc>().add(LoadCommunityTasks());
                          },
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is CommunityLoaded) {
                  if (state.tasks.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'No tasks found',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _searchController.text.isNotEmpty
                                ? 'Try different search terms'
                                : 'Be the first to submit a community task!',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const SubmitTaskScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Submit Task'),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<CommunityBloc>().add(LoadCommunityTasks());
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: state.tasks.length,
                      itemBuilder: (context, index) {
                        final task = state.tasks[index];
                        return CommunityTaskCard(
                          task: task,
                          onUpvote: () {
                            context.read<CommunityBloc>().add(
                              UpvoteTask(taskId: task.id),
                            );
                          },
                          onUse: () {
                            // TODO: Implement adding task to current game
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Task added to game! (Feature coming soon)'),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const SubmitTaskScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'Submit Task',
      ),
    );
  }
}