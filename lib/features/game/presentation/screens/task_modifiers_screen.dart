import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/task.dart';
import '../../../../core/models/task_modifier.dart';
import '../bloc/game_bloc.dart';

class TaskModifiersScreen extends StatefulWidget {
  final Task task;
  final String gameId;

  const TaskModifiersScreen({
    super.key,
    required this.task,
    required this.gameId,
  });

  @override
  State<TaskModifiersScreen> createState() => _TaskModifiersScreenState();
}

class _TaskModifiersScreenState extends State<TaskModifiersScreen> {
  List<TaskModifier> availableModifiers = [];
  List<TaskModifier> selectedModifiers = [];
  
  @override
  void initState() {
    super.initState();
    _loadModifiers();
    selectedModifiers = List.from(widget.task.modifiers);
  }

  void _loadModifiers() {
    availableModifiers = TaskModifierGenerator.getCompatibleModifiers(
      widget.task.taskType.name,
    );
    setState(() {});
  }

  void _addRandomModifier() {
    final compatibleModifiers = TaskModifierGenerator.getCompatibleModifiers(
      widget.task.taskType.name,
    );
    
    final availableToAdd = compatibleModifiers.where((modifier) {
      return !selectedModifiers.any((selected) => selected.type == modifier.type);
    }).toList();

    if (availableToAdd.isNotEmpty) {
      final randomModifier = availableToAdd[
        DateTime.now().millisecondsSinceEpoch % availableToAdd.length
      ];
      setState(() {
        selectedModifiers.add(randomModifier);
      });
    }
  }

  void _toggleModifier(TaskModifier modifier) {
    setState(() {
      if (selectedModifiers.any((m) => m.type == modifier.type)) {
        selectedModifiers.removeWhere((m) => m.type == modifier.type);
      } else {
        selectedModifiers.add(modifier);
      }
    });
  }

  void _removeModifier(TaskModifier modifier) {
    setState(() {
      selectedModifiers.removeWhere((m) => m.type == modifier.type);
    });
  }

  void _applyModifiers() {
    final updatedTask = widget.task.copyWith(modifiers: selectedModifiers);
    context.read<GameBloc>().add(
      UpdateTaskModifiers(
        gameId: widget.gameId,
        taskId: widget.task.id,
        modifiers: selectedModifiers,
      ),
    );
    Navigator.of(context).pop(updatedTask);
  }

  int get totalPointsMultiplier {
    return selectedModifiers.fold(1, (total, modifier) => total * modifier.pointsMultiplier);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Modifiers'),
        actions: [
          IconButton(
            onPressed: _addRandomModifier,
            icon: const Icon(Icons.casino),
            tooltip: 'Add Random Modifier',
          ),
        ],
      ),
      body: Column(
        children: [
          // Task Preview
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.task.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.task.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.task.taskType == TaskType.video 
                            ? Colors.red.withOpacity(0.1)
                            : Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: widget.task.taskType == TaskType.video 
                              ? Colors.red
                              : Colors.blue,
                        ),
                      ),
                      child: Text(
                        widget.task.taskType == TaskType.video ? 'Video' : 'Puzzle',
                        style: TextStyle(
                          color: widget.task.taskType == TaskType.video 
                              ? Colors.red[700]
                              : Colors.blue[700],
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Points Multiplier: ${totalPointsMultiplier}x',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: totalPointsMultiplier > 1 ? Colors.green[700] : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Selected Modifiers
          if (selectedModifiers.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active Modifiers (${selectedModifiers.length})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: selectedModifiers.map((modifier) {
                      return Chip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(modifier.name),
                            if (modifier.pointsMultiplier != 1) ...[
                              const SizedBox(width: 4),
                              Text(
                                '${modifier.pointsMultiplier}x',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ],
                        ),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () => _removeModifier(modifier),
                        backgroundColor: Colors.orange[100],
                        deleteIconColor: Colors.orange[700],
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Available Modifiers
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Text(
                  'Available Modifiers',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ...availableModifiers.map((modifier) {
                  final isSelected = selectedModifiers.any((m) => m.type == modifier.type);
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Row(
                        children: [
                          Expanded(child: Text(modifier.name)),
                          if (modifier.pointsMultiplier != 1)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${modifier.pointsMultiplier}x',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                ),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Text(modifier.description),
                      leading: Icon(
                        isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: isSelected ? Colors.green : Colors.grey,
                      ),
                      onTap: () => _toggleModifier(modifier),
                      tileColor: isSelected ? Colors.green[50] : null,
                    ),
                  );
                }).toList(),
              ],
            ),
          ),

          // Apply Button
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (selectedModifiers.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber[300]!),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Preview with Modifiers:',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...selectedModifiers.map((modifier) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              '• ${modifier.description}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _applyModifiers,
                    child: Text(
                      selectedModifiers.isEmpty 
                          ? 'Continue Without Modifiers'
                          : 'Apply ${selectedModifiers.length} Modifier${selectedModifiers.length != 1 ? 's' : ''}',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}