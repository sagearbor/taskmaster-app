import 'package:equatable/equatable.dart';

enum GameModeType { individual, teamVsTeam, secretMissions }

class GameMode extends Equatable {
  final GameModeType type;
  final Map<String, dynamic> settings;

  const GameMode({
    required this.type,
    required this.settings,
  });

  factory GameMode.individual() {
    return const GameMode(
      type: GameModeType.individual,
      settings: {},
    );
  }

  factory GameMode.teamVsTeam({
    required int teamCount,
    required bool autoAssignTeams,
  }) {
    return GameMode(
      type: GameModeType.teamVsTeam,
      settings: {
        'teamCount': teamCount,
        'autoAssignTeams': autoAssignTeams,
      },
    );
  }

  factory GameMode.secretMissions({
    required bool enableSecretTasks,
    required int secretTaskCount,
  }) {
    return GameMode(
      type: GameModeType.secretMissions,
      settings: {
        'enableSecretTasks': enableSecretTasks,
        'secretTaskCount': secretTaskCount,
      },
    );
  }

  factory GameMode.fromMap(Map<String, dynamic> map) {
    return GameMode(
      type: GameModeType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => GameModeType.individual,
      ),
      settings: Map<String, dynamic>.from(map['settings'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'settings': settings,
    };
  }

  bool get isIndividual => type == GameModeType.individual;
  bool get isTeamVsTeam => type == GameModeType.teamVsTeam;
  bool get hasSecretMissions => type == GameModeType.secretMissions;

  int get teamCount => settings['teamCount'] as int? ?? 2;
  bool get autoAssignTeams => settings['autoAssignTeams'] as bool? ?? true;
  bool get enableSecretTasks => settings['enableSecretTasks'] as bool? ?? false;
  int get secretTaskCount => settings['secretTaskCount'] as int? ?? 1;

  @override
  List<Object> get props => [type, settings];
}