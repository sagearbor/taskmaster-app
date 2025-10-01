# King of the Mountain Avatar System

## Overview

The King of the Mountain avatar system is a physics-based mini-game that displays in the game lobby. Players' profile photos become avatar heads that autonomously climb platforms trying to reach the top.

## Features

- **Real Player Avatars**: Uses player profile photos as avatar heads (currently displays initials as fallback)
- **NPC Avatars**: Spawns animal emoji-faced NPCs (🐶🐱🐭🐹🐰🦊🐻🐼) when fewer than 10 players
- **Autonomous Movement**: Avatars intelligently climb platforms using pathfinding AI
- **Physics-Based**: Uses Forge2D for realistic gravity, collisions, and pushing
- **King of the Mountain**: Avatar at the top gets a crown
- **Toggle Visibility**: Can show/hide avatars with button in lobby

## Architecture

### Core Components

1. **KingOfMountainGame** (`king_of_mountain_game.dart`)
   - Main game class extending Forge2DGame
   - Manages all avatars, platforms, and game state
   - Handles king detection

2. **PlayerAvatar** (`components/player_avatar.dart`)
   - Base avatar component for real players
   - Implements autonomous climbing AI
   - Renders avatar with head (initials) and body
   - Handles physics and collisions

3. **NPCAvatar** (`components/npc_avatar.dart`)
   - Extends PlayerAvatar
   - Shows emoji face instead of initials
   - Slightly different AI behavior (more random)

4. **PlatformComponent** (`components/platform_component.dart`)
   - Static platforms at different heights
   - Ground, middle platforms, and peak
   - Peak platform marked as gold/yellow

5. **AvatarGameOverlay** (`presentation/widgets/avatar_game_overlay.dart`)
   - Widget that overlays avatars on game lobby
   - Only shows when game status is 'lobby'
   - Provides toggle button

## Usage

The avatar system is automatically integrated into the GameLobbyView:

```dart
return AvatarGameOverlay(
  game: game,
  child: YourLobbyContent(),
);
```

## Configuration

### Avatar Limits
- Maximum 10 avatars total
- Real players fill slots first
- NPCs fill remaining slots (up to 8)

### Physics Parameters
- Gravity: 30 (pulls avatars down)
- Move Speed: 100 units/sec
- Jump Force: 300
- Max Speed: 150

### Platform Heights
- Ground: worldHeight - 50
- Platform 1: worldHeight - 250
- Platform 2: worldHeight - 450
- Platform 3: worldHeight - 650
- Peak: worldHeight - 900

## Future Enhancements

### Planned (from DEVELOPMENT_CHECKLIST.md Phase 10.6)
- [ ] Manual control mode (click/drag to control avatar)
- [ ] Camera integration for real face photos
- [ ] Multiple game modes (Race to Top, Last Standing)
- [ ] Power-ups (super jump, speed boost, push immunity)
- [ ] Avatar customization (body types, colors)
- [ ] Seasonal events (holiday costumes)

### Technical Improvements
- [ ] Optimize for low-end devices
- [ ] Add sound effects
- [ ] Haptic feedback
- [ ] Particle effects for jumps/falls
- [ ] Better collision detection

## Dependencies

```yaml
dependencies:
  flame: ^1.18.0           # Game engine
  flame_forge2d: ^0.16.0   # Physics engine
```

## Testing

Run tests:
```bash
flutter test test/features/avatars/
```

## Performance

- Target: 60 FPS on web
- Works with up to 10 avatars simultaneously
- Graceful degradation on low-end devices (can disable)
- ~1MB bundle size increase

## Notes

- Avatar system only displays in lobby (status == 'lobby')
- Physics engine paused when overlay is hidden
- Game disposed properly when leaving lobby
- Compatible with all platforms (web, mobile, desktop)
