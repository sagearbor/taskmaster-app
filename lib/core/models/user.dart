import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String displayName;
  final String? email;
  final DateTime createdAt;

  /// A fun emoji the user picked as their avatar (e.g. "🎉"). Optional —
  /// when null the avatar falls back to the first initial of [displayName].
  final String? avatarEmoji;

  /// Forward-compatible field for a hosted profile photo. Not used by the
  /// current avatar feature (no Firebase Storage), but persisted so future
  /// photo upload work is backward-compatible.
  final String? photoUrl;

  const User({
    required this.id,
    required this.displayName,
    this.email,
    required this.createdAt,
    this.avatarEmoji,
    this.photoUrl,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      displayName: map['displayName'] as String,
      email: map['email'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      // Nullable + backward-compatible: tolerate maps written before these
      // fields existed.
      avatarEmoji: map['avatarEmoji'] as String?,
      photoUrl: map['photoUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'displayName': displayName,
      'email': email,
      'createdAt': createdAt.toIso8601String(),
      'avatarEmoji': avatarEmoji,
      'photoUrl': photoUrl,
    };
  }

  User copyWith({
    String? id,
    String? displayName,
    String? email,
    DateTime? createdAt,
    String? avatarEmoji,
    String? photoUrl,
  }) {
    return User(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  @override
  List<Object?> get props =>
      [id, displayName, email, createdAt, avatarEmoji, photoUrl];
}
