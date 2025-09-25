enum Difficulty { beginner, intermediate, expert, insane }

class DifficultyConfig {
  final double ballSpeed;
  final double aiMaxSpeed;
  final double paddleHeightFactor; // relative to screen height
  final bool locked;
  const DifficultyConfig({
    required this.ballSpeed,
    required this.aiMaxSpeed,
    required this.paddleHeightFactor,
    required this.locked,
  });
}

class DifficultyConfigs {
  static DifficultyConfig configFor(Difficulty d, {required bool hasPremium}) {
    switch (d) {
      case Difficulty.beginner:
        return const DifficultyConfig(ballSpeed: 220, aiMaxSpeed: 140, paddleHeightFactor: 0.22, locked: false);
      case Difficulty.intermediate:
        return const DifficultyConfig(ballSpeed: 300, aiMaxSpeed: 200, paddleHeightFactor: 0.18, locked: false);
      case Difficulty.expert:
        return DifficultyConfig(ballSpeed: 380, aiMaxSpeed: 260, paddleHeightFactor: 0.15, locked: !hasPremium);
      case Difficulty.insane:
        return DifficultyConfig(ballSpeed: 470, aiMaxSpeed: 380, paddleHeightFactor: 0.12, locked: !hasPremium);
    }
  }
}
