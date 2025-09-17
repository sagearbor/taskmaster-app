import 'package:flutter/material.dart';

import '../../../../core/models/episode.dart';
import '../../../../core/models/task.dart';

class EpisodeCreatorScreen extends StatefulWidget {
  final Episode? existingEpisode;

  const EpisodeCreatorScreen({
    super.key,
    this.existingEpisode,
  });

  @override
  State<EpisodeCreatorScreen> createState() => _EpisodeCreatorScreenState();
}

class _EpisodeCreatorScreenState extends State<EpisodeCreatorScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagController = TextEditingController();
  
  List<Task> _selectedTasks = [];
  List<Timestamp> _timestamps = [];
  List<String> _tags = [];
  bool _isPublic = false;
  Duration _estimatedDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    if (widget.existingEpisode != null) {
      _loadExistingEpisode();
    }
  }

  void _loadExistingEpisode() {
    final episode = widget.existingEpisode!;
    _titleController.text = episode.title;
    _descriptionController.text = episode.description;
    _selectedTasks = List.from(episode.tasks);
    _timestamps = List.from(episode.timestamps);
    _tags = List.from(episode.tags);
    _isPublic = episode.isPublic;
    _estimatedDuration = episode.totalDuration;
    setState(() {});
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void _addTimestamp() {
    showDialog(
      context: context,
      builder: (context) => _TimestampDialog(
        onTimestampAdded: (timestamp) {
          setState(() {
            _timestamps.add(timestamp);
            _timestamps.sort((a, b) => a.time.compareTo(b.time));
          });
        },
      ),
    );
  }

  void _removeTimestamp(Timestamp timestamp) {
    setState(() {
      _timestamps.remove(timestamp);
    });
  }

  void _calculateEstimatedDuration() {
    const averageTaskDuration = Duration(minutes: 10);
    _estimatedDuration = Duration(
      milliseconds: (_selectedTasks.length * averageTaskDuration.inMilliseconds),
    );
    setState(() {});
  }

  void _saveEpisode() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an episode title'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedTasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one task'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final episode = Episode.create(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      createdBy: 'current_user_id', // Replace with actual user ID
      isPublic: _isPublic,
      tags: _tags,
    ).copyWith(
      tasks: _selectedTasks,
      timestamps: _timestamps,
      totalDuration: _estimatedDuration,
    );

    Navigator.of(context).pop(episode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingEpisode != null ? 'Edit Episode' : 'Create Episode'),
        actions: [
          TextButton(
            onPressed: _saveEpisode,
            child: const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Basic Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Episode Information',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Episode Title',
                        hintText: 'Enter episode title...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Describe your episode...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Make Public'),
                      subtitle: const Text('Allow other players to discover and play this episode'),
                      value: _isPublic,
                      onChanged: (value) {
                        setState(() {
                          _isPublic = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tags Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tags',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _tagController,
                            decoration: const InputDecoration(
                              hintText: 'Add a tag...',
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: (_) => _addTag(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _addTag,
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                    if (_tags.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _tags.map((tag) {
                          return Chip(
                            label: Text(tag),
                            deleteIcon: const Icon(Icons.close, size: 18),
                            onDeleted: () => _removeTag(tag),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tasks Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Tasks (${_selectedTasks.length})',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () {
                            // Navigate to task selection screen
                            _showTaskSelectionDialog();
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add Tasks'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_selectedTasks.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.task_alt, size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 8),
                              Text(
                                'No tasks added yet',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...List.generate(_selectedTasks.length, (index) {
                        final task = _selectedTasks[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: task.taskType == TaskType.video 
                                  ? Colors.red[100] 
                                  : Colors.blue[100],
                              child: Icon(
                                task.taskType == TaskType.video 
                                    ? Icons.videocam 
                                    : Icons.quiz,
                                color: task.taskType == TaskType.video 
                                    ? Colors.red[700] 
                                    : Colors.blue[700],
                              ),
                            ),
                            title: Text(task.title),
                            subtitle: Text(
                              task.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _selectedTasks.removeAt(index);
                                  _calculateEstimatedDuration();
                                });
                              },
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Timestamps Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Timestamps (${_timestamps.length})',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _addTimestamp,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Timestamp'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_timestamps.isEmpty)
                      Text(
                        'No timestamps added. Add timestamps to mark important moments.',
                        style: TextStyle(color: Colors.grey[600]),
                      )
                    else
                      ...List.generate(_timestamps.length, (index) {
                        final timestamp = _timestamps[index];
                        return ListTile(
                          leading: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              timestamp.formattedTime,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                color: Colors.blue[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(timestamp.description),
                          subtitle: timestamp.notes != null 
                              ? Text(timestamp.notes!) 
                              : null,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeTimestamp(timestamp),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Episode Summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Episode Summary',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.timer, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text('Estimated Duration: ${_estimatedDuration.inMinutes} minutes'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.task, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text('Total Tasks: ${_selectedTasks.length}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.bookmark, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text('Timestamps: ${_timestamps.length}'),
                      ],
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

  void _showTaskSelectionDialog() {
    // This would open a task selection dialog
    // For now, we'll add a sample task
    final sampleTask = Task(
      id: 'task_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Sample Task ${_selectedTasks.length + 1}',
      description: 'This is a sample task for the episode',
      taskType: TaskType.video,
      submissions: [],
    );
    
    setState(() {
      _selectedTasks.add(sampleTask);
      _calculateEstimatedDuration();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    super.dispose();
  }
}

class _TimestampDialog extends StatefulWidget {
  final Function(Timestamp) onTimestampAdded;

  const _TimestampDialog({required this.onTimestampAdded});

  @override
  State<_TimestampDialog> createState() => _TimestampDialogState();
}

class _TimestampDialogState extends State<_TimestampDialog> {
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  int _minutes = 0;
  int _seconds = 0;

  void _addTimestamp() {
    if (_descriptionController.text.trim().isEmpty) {
      return;
    }

    final timestamp = Timestamp(
      time: Duration(minutes: _minutes, seconds: _seconds),
      description: _descriptionController.text.trim(),
      notes: _notesController.text.trim().isEmpty 
          ? null 
          : _notesController.text.trim(),
    );

    widget.onTimestampAdded(timestamp);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Timestamp'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _minutes,
                  decoration: const InputDecoration(labelText: 'Minutes'),
                  items: List.generate(60, (index) => index)
                      .map((i) => DropdownMenuItem(value: i, child: Text('$i')))
                      .toList(),
                  onChanged: (value) => setState(() => _minutes = value ?? 0),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _seconds,
                  decoration: const InputDecoration(labelText: 'Seconds'),
                  items: List.generate(60, (index) => index)
                      .map((i) => DropdownMenuItem(value: i, child: Text('$i')))
                      .toList(),
                  onChanged: (value) => setState(() => _seconds = value ?? 0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'What happens at this timestamp?',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              hintText: 'Additional notes...',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _addTimestamp,
          child: const Text('Add'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}