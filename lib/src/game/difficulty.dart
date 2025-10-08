enum Difficulty { beginner, intermediate, expert, insane }

class DifficultyConfig {
  final double ballSpeed;
  final double aiMaxSpeed;
  final double paddleHeightFactor; // relative to screen height
  final double paddleWidth;        // paddle thickness in pixels
  final double aiMaxAccel; // added for smooth acceleration control
  final int targetScore;   // score needed to win
  final double ballSize;   // ball diameter in logical pixels
  final double aiReactionTime; // seconds between AI decision updates
  final double aiAnticipation; // 0..1 blending factor toward predicted intercept
  final double aiErrorStd;     // random vertical error amplitude (pixels, approx)
  final double aiAdaptiveBoost; // per point player lead speed boost factor (capped)
  final bool locked;
  const DifficultyConfig({
    required this.ballSpeed,
    required this.aiMaxSpeed,
    required this.paddleHeightFactor,
    required this.paddleWidth,
    required this.aiMaxAccel,
    required this.targetScore,
    required this.ballSize,
    required this.aiReactionTime,
    required this.aiAnticipation,
    required this.aiErrorStd,
    required this.aiAdaptiveBoost,
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
          aiReactionTime: 0.32,
          aiAnticipation: 0.20,
          aiErrorStd: 34,
          aiAdaptiveBoost: 0.04,
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
          aiReactionTime: 0.24,
          aiAnticipation: 0.55,
          aiErrorStd: 18,
          aiAdaptiveBoost: 0.06,
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
          aiReactionTime: 0.18,
          aiAnticipation: 0.75,
          aiErrorStd: 9,
          aiAdaptiveBoost: 0.08,
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
          aiReactionTime: 0.12,
          aiAnticipation: 0.90,
          aiErrorStd: 4,
          aiAdaptiveBoost: 0.10,
          locked: !hasPremium,
        );
    }
  }
}
