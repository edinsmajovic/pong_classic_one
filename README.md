# Pong Classic One

A fast, clean Flutter + Flame take on the classic Pong. Tuned physics, multiple difficulty levels, smooth AI, and mobile/web support.

## Features

- Built with Flame (Flutter game engine) and Flutter widgets overlay
- Difficulty presets: Beginner, Intermediate, Expert, Insane
	- DifficultyConfig drives gameplay: ball speed/size, AI speed/accel, paddle height factor, paddle width, target score
- Circular ball with matching hitbox for pixel-accurate collisions
- Paddle thickness varies per difficulty (visuals match collision)
- Spin based on contact point (top/bottom of paddle) with angle caps and minimum horizontal speed to avoid vertical traps
- Score cooldown to prevent double-scores and re-serve behavior
- Simple, readable code structure and guardrails for initialization

## Controls

- Touch/drag (or mouse drag on web) vertically to move the player paddle
- First to target score (default 11) wins

## Run it locally

Requirements: Flutter SDK and a connected device/emulator or Chrome for web.

PowerShell (Windows):

```powershell
flutter pub get
# Run on a connected Android device/emulator
flutter run

# Or explicitly run for web
flutter run -d chrome
```

### Build

```powershell
# Android APK (release)
flutter build apk --release

# Web (release)
flutter build web
```

## Key files

- `lib/src/game/pong_game.dart` — Core game logic (paddles, ball, scoring, collisions)
- `lib/src/game/difficulty.dart` — DifficultyConfig and presets per level
- `lib/src/screens/game_screen.dart` — Flutter UI shell, gestures, score UI, game-over dialog
- `lib/main.dart` — App entry point

## Difficulty and tuning

Difficulty is selected in `GameScreen` using `DifficultyConfigs.configFor`. Each `DifficultyConfig` includes:

- `ballSpeed` — base speed of the ball
- `ballSize` — ball diameter in logical pixels
- `paddleHeightFactor` — paddle height relative to screen height
- `paddleWidth` — paddle thickness in pixels
- `aiMaxSpeed`, `aiMaxAccel` — AI movement tuning
- `targetScore` — points needed to win (default 11)

To tweak the feel, adjust the presets in `lib/src/game/difficulty.dart`.

## Notes and troubleshooting

- If you see dependency warnings, try:
	- `flutter pub get` (already done by run commands)
	- `flutter pub outdated` to review versions
- Flame APIs: this project uses `HasGameReference` and `onCollisionStart`. If you upgrade Flame, check for API changes.
- At very high speeds, if you ever notice edge tunneling through paddles, consider increasing `ballSize` slightly or reducing extreme speed multipliers.

## Credits

- Built with [Flutter](https://flutter.dev) and [Flame](https://flame-engine.org)
