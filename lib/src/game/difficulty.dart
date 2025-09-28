enum Difficulty { beginner, intermediate, expert, insane }

class DifficultyConfig {
  final double ballSpeed;
  final double aiMaxSpeed;
  final double paddleHeightFactor; // relative to screen height
  final double paddleWidth;        // paddle thickness in pixels
  final double aiMaxAccel; // added for smooth acceleration control
  final int targetScore;   // score needed to win
  final double ballSize;   // ball diameter in logical pixels
  final bool locked;
  const DifficultyConfig({
    required this.ballSpeed,
    required this.aiMaxSpeed,
    required this.paddleHeightFactor,
    required this.paddleWidth,
    required this.aiMaxAccel,
    required this.targetScore,
    required this.ballSize,
    required this.locked,
  });
}

class DifficultyConfigs {
  static DifficultyConfig configFor(Difficulty d, {required bool hasPremium}) {
    switch (d) {
      case Difficulty.beginner:
        return const DifficultyConfig(
          ballSpeed: 220,
          aiMaxSpeed: 140,
          paddleHeightFactor: 0.26,
          paddleWidth: 18,
          aiMaxAccel: 600,
          targetScore: 11,
          ballSize: 18,
          locked: false,
        );
      case Difficulty.intermediate:
        return const DifficultyConfig(
          ballSpeed: 300,
          aiMaxSpeed: 200,
          paddleHeightFactor: 0.18,
          paddleWidth: 14,
          aiMaxAccel: 750,
          targetScore: 11,
          ballSize: 11,
          locked: false,
        );
      case Difficulty.expert:
        return DifficultyConfig(
          ballSpeed: 380,
          aiMaxSpeed: 260,
          paddleHeightFactor: 0.15,
          paddleWidth: 12,
          aiMaxAccel: 900,
          targetScore: 11,
          ballSize: 10,
          locked: !hasPremium,
        );
      case Difficulty.insane:
        return DifficultyConfig(
          ballSpeed: 470,
          aiMaxSpeed: 380,
          paddleHeightFactor: 0.10,
          paddleWidth: 10,
          aiMaxAccel: 1100,
          targetScore: 11,
          ballSize: 9,
          locked: !hasPremium,
        );
    }
  }
}
