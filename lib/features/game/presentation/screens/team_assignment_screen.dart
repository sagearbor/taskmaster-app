import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/game.dart';
import '../../../../core/models/team.dart';
import '../../../../core/models/user.dart';
import '../bloc/game_bloc.dart';

class TeamAssignmentScreen extends StatefulWidget {
  final Game game;
  final List<User> players;

  const TeamAssignmentScreen({
    super.key,
    required this.game,
    required this.players,
  });

  @override
  State<TeamAssignmentScreen> createState() => _TeamAssignmentScreenState();
}

class _TeamAssignmentScreenState extends State<TeamAssignmentScreen> {
  List<Team> teams = [];
  Map<String, String?> playerAssignments = {};
  
  final List<String> teamColors = [
    '#FF5722', // Red
    '#2196F3', // Blue
    '#4CAF50', // Green
    '#FF9800', // Orange
    '#9C27B0', // Purple
    '#00BCD4', // Cyan
  ];

  @override
  void initState() {
    super.initState();
    _initializeTeams();
  }

  void _initializeTeams() {
    final teamCount = widget.game.gameMode.teamCount;
    teams = List.generate(teamCount, (index) {
      return Team(
        id: 'team_${index + 1}',
        name: 'Team ${index + 1}',
        color: teamColors[index % teamColors.length],
        playerIds: [],
        totalScore: 0,
      );
    });

    // Initialize player assignments
    for (final player in widget.players) {
      playerAssignments[player.id] = null;
    }

    // Auto-assign if enabled
    if (widget.game.gameMode.autoAssignTeams) {
      _autoAssignTeams();
    }
  }

  void _autoAssignTeams() {
    final shuffledPlayers = List<User>.from(widget.players)..shuffle();
    
    for (int i = 0; i < shuffledPlayers.length; i++) {
      final teamIndex = i % teams.length;
      final player = shuffledPlayers[i];
      
      playerAssignments[player.id] = teams[teamIndex].id;
      teams[teamIndex] = teams[teamIndex].copyWith(
        playerIds: [...teams[teamIndex].playerIds, player.id],
      );
    }
    
    setState(() {});
  }

  void _assignPlayerToTeam(String playerId, String teamId) {
    // Remove player from current team
    final currentTeamId = playerAssignments[playerId];
    if (currentTeamId != null) {
      final currentTeamIndex = teams.indexWhere((t) => t.id == currentTeamId);
      if (currentTeamIndex != -1) {
        teams[currentTeamIndex] = teams[currentTeamIndex].copyWith(
          playerIds: teams[currentTeamIndex].playerIds
              .where((id) => id != playerId)
              .toList(),
        );
      }
    }

    // Add player to new team
    final newTeamIndex = teams.indexWhere((t) => t.id == teamId);
    if (newTeamIndex != -1) {
      teams[newTeamIndex] = teams[newTeamIndex].copyWith(
        playerIds: [...teams[newTeamIndex].playerIds, playerId],
      );
    }

    playerAssignments[playerId] = teamId;
    setState(() {});
  }

  void _updateTeamName(int teamIndex, String newName) {
    teams[teamIndex] = teams[teamIndex].copyWith(name: newName);
    setState(() {});
  }

  bool get _allPlayersAssigned {
    return playerAssignments.values.every((teamId) => teamId != null);
  }

  void _confirmTeams() {
    if (!_allPlayersAssigned) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please assign all players to teams'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    context.read<GameBloc>().add(
      UpdateGameTeams(gameId: widget.game.id, teams: teams),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Assignment'),
        actions: [
          TextButton(
            onPressed: _autoAssignTeams,
            child: const Text('Auto Assign'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Team Setup
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: teams.length,
              itemBuilder: (context, index) {
                final team = teams[index];
                final teamPlayers = widget.players
                    .where((p) => team.playerIds.contains(p.id))
                    .toList();

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Team Header
                        Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Color(int.parse(team.color.substring(1), radix: 16) + 0xFF000000),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: TextEditingController(text: team.name),
                                decoration: const InputDecoration(
                                  labelText: 'Team Name',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (value) => _updateTeamName(index, value),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Team Members
                        Text(
                          'Members (${teamPlayers.length})',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),

                        if (teamPlayers.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                'Drag players here',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: teamPlayers.map((player) {
                              return DragTarget<String>(
                                onAccept: (playerId) {
                                  _assignPlayerToTeam(playerId, team.id);
                                },
                                builder: (context, candidateData, rejectedData) {
                                  return Draggable<String>(
                                    data: player.id,
                                    feedback: Material(
                                      child: Chip(
                                        label: Text(player.displayName),
                                        backgroundColor: Colors.blue[100],
                                      ),
                                    ),
                                    childWhenDragging: Opacity(
                                      opacity: 0.5,
                                      child: Chip(
                                        label: Text(player.displayName),
                                      ),
                                    ),
                                    child: Chip(
                                      label: Text(player.displayName),
                                      backgroundColor: Color(int.parse(team.color.substring(1), radix: 16) + 0xFF000000).withOpacity(0.1),
                                    ),
                                  );
                                },
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Unassigned Players
          if (widget.players.any((p) => playerAssignments[p.id] == null))
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Unassigned Players',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.players
                        .where((p) => playerAssignments[p.id] == null)
                        .map((player) {
                      return Draggable<String>(
                        data: player.id,
                        feedback: Material(
                          child: Chip(
                            label: Text(player.displayName),
                            backgroundColor: Colors.blue[100],
                          ),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.5,
                          child: Chip(
                            label: Text(player.displayName),
                          ),
                        ),
                        child: Chip(
                          label: Text(player.displayName),
                          backgroundColor: Colors.grey[200],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

          // Confirm Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _allPlayersAssigned ? _confirmTeams : null,
                child: Text(
                  _allPlayersAssigned 
                      ? 'Confirm Teams' 
                      : 'Assign all players to continue',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}