import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'difficulty.dart';

/// Main game class
class PongGame extends FlameGame with HasCollisionDetection {
  PongGame({
    required this.difficultyConfig,
    required this.onScore,
    required this.onGameOver,
    this.onSpeedUp,
  });

  final DifficultyConfig difficultyConfig;
  final void Function(int player, int ai) onScore;
  final void Function({required bool playerWon, required int player, required int ai}) onGameOver;
  final void Function(double totalMultiplier, int step)? onSpeedUp;

  /// Convenience getter so UI code can still call game.targetScore
  int get targetScore => difficultyConfig.targetScore;

  late Paddle playerPaddle;
  late Paddle aiPaddle;
  late Ball ball;

  int playerScore = 0;
  int aiScore = 0;

  // Indicates whether core components (paddles, ball) have been created.
  bool _initialized = false;
  bool get isInitialized => _initialized;

  // Anti double-score cooldown after a point (seconds)
  final Timer _scoreCooldownTimer = Timer(0.4, autoStart: false);
  // Periodic speed-up every 30 seconds
  Timer? _speedUpTimer; // created after ball is initialized
  int _speedUpSteps = 0;

  // Cached paints (less GC)
  final Paint _whitePaint = Paint()..color = const Color(0xFFFFFFFF);

  // Scene constants
  static const double _paddleXMargin = 30.0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Defer creation until we have a non-zero size in onGameResize.
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // First-time initialization when we receive a valid size
  if (!_initialized && size.x > 0 && size.y > 0) {
      playerPaddle = Paddle(
        isPlayer: true,
        heightFactor: difficultyConfig.paddleHeightFactor,
        color: _whitePaint,
      )..anchor = Anchor.center
       ..position = Vector2(_paddleXMargin, size.y / 2);

      aiPaddle = Paddle(
        isPlayer: false,
        heightFactor: difficultyConfig.paddleHeightFactor,
        color: _whitePaint,
      )..anchor = Anchor.center
       ..position = Vector2(size.x - _paddleXMargin, size.y / 2);

        ball = Ball(
          baseSpeed: difficultyConfig.ballSpeed,
          color: _whitePaint,
          diameter: difficultyConfig.ballSize,
        )..anchor = Anchor.center
         ..position = size / 2;

  addAll([playerPaddle, aiPaddle, ball]);
      _initialized = true;
      // Start periodic speed increase (10% every 30 seconds)
      _speedUpTimer = Timer(30, repeat: true, autoStart: true, onTick: () {
        ball.increaseGlobalSpeed(1.10);
        _speedUpSteps++;
        onSpeedUp?.call(ball.globalSpeedMultiplier, _speedUpSteps);
      });
    }

    if (_initialized) {
      // Adjust paddle heights to the new screen height
      playerPaddle.size.y = size.y * playerPaddle.heightFactor;
      aiPaddle.size.y = size.y * aiPaddle.heightFactor;
      playerPaddle.syncHitbox();
      aiPaddle.syncHitbox();
      playerPaddle.clamp(size.y);
      aiPaddle.clamp(size.y);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_initialized) return; // wait until components are ready
    _scoreCooldownTimer.update(dt);
    _speedUpTimer?.update(dt);

    // --- AI movement (smooth) ---
    // Dead-zone to avoid jitter, then limit acceleration.
    final double dy = ball.position.y - aiPaddle.position.y;
    const double deadZone = 6.0; // px
    if (dy.abs() > deadZone) {
      final desiredVel = dy.sign * difficultyConfig.aiMaxSpeed;
      // Simple model: dV = clamp(accel * dt)
      final maxDeltaV = difficultyConfig.aiMaxAccel * dt;
      final currentVel = aiPaddle.currentVelY;
      final deltaV = (desiredVel - currentVel)
          .clamp(-maxDeltaV, maxDeltaV);
      final newVel = currentVel + deltaV;
      aiPaddle.currentVelY = newVel;
      aiPaddle.position.y += newVel * dt;
    } else {
      // slow down toward 0
      final currentVel = aiPaddle.currentVelY;
      final decel = difficultyConfig.aiMaxAccel * dt;
      if (currentVel.abs() <= decel) {
        aiPaddle.currentVelY = 0;
      } else {
        aiPaddle.currentVelY = currentVel - decel * currentVel.sign;
      }
    }

    // Clamp paddle positions
    aiPaddle.clamp(size.y);
    playerPaddle.clamp(size.y);

    // --- Point check (ball passed left/right boundary) ---
    if (!_scoreCooldownTimer.isRunning()) {
      final half = ball.size.x / 2;
      if (ball.position.x < -half) {
        _registerScore(playerScored: false);
      } else if (ball.position.x > size.x + half) {
        _registerScore(playerScored: true);
      }
    }
  }

  /// Called from Flutter gesture layer to move the player paddle.
  /// [worldDy] should already be converted to game/world coordinates if needed.
  void onPlayerDrag(double worldDy) {
    playerPaddle.position.y = worldDy;
    playerPaddle.clamp(size.y);
  }

  void _resetBall({required bool towardPlayer}) {
    ball.position = size / 2;
    ball.reset(towardPlayer: towardPlayer);
    _scoreCooldownTimer.start(); // short safeguard against double scoring
  }

  void _registerScore({required bool playerScored}) {
    if (playerScored) {
      playerScore++;
    } else {
      aiScore++;
    }

    onScore(playerScore, aiScore);

    // End of round?
    if (playerScore >= difficultyConfig.targetScore ||
        aiScore >= difficultyConfig.targetScore) {
      pauseEngine();
      onGameOver(
        playerWon: playerScore > aiScore,
        player: playerScore,
        ai: aiScore,
      );
      return;
    }

    // New serve toward the player who conceded the point
    _resetBall(towardPlayer: !playerScored);
  }

  /// Public wrapper for resetting the ball toward a random side (default toward AI).
  void resetBall() => _resetBall(towardPlayer: false);
}

/// Paddle component
class Paddle extends PositionComponent
  with HasGameReference<PongGame>, CollisionCallbacks {
  Paddle({
    required this.isPlayer,
    required this.heightFactor,
    required Paint color,
  }) : _paint = color;

  final bool isPlayer;
  final double heightFactor;
  final Paint _paint;
  RectangleHitbox? _hitbox;
  

  // For smooth AI movement (player doesn't use)
  double currentVelY = 0.0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final width = game.difficultyConfig.paddleWidth;
    size = Vector2(width, game.size.y * heightFactor);
    anchor = Anchor.center;
    // Centered hitbox that matches the visual rect
  _hitbox = RectangleHitbox(size: size, anchor: Anchor.center);
  add(_hitbox!);
  }

  // Keep hitbox in sync when the paddle size changes (e.g., on resize)
  void syncHitbox() {
    final hb = _hitbox;
    if (hb == null) return; // onLoad may not have run yet
    hb
      ..size = size
      ..position = Vector2.zero()
      ..anchor = Anchor.center;
  }

  void clamp(double screenHeight) {
    final half = size.y / 2;
    position.y = position.y.clamp(half, screenHeight - half);
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset.zero,
        width: size.x,
        height: size.y,
      ),
      _paint,
    );
  }
}

/// Ball
class Ball extends PositionComponent with HasGameReference<PongGame>, CollisionCallbacks {
  Ball({
    required this.baseSpeed,
    required Paint color,
    double? diameter,
  }) : _paint = color,
       _diameter = diameter;

  final double baseSpeed;
  final Paint _paint;
  final double? _diameter;
  double _globalSpeedMultiplier = 1.0; // grows over time
  double get globalSpeedMultiplier => _globalSpeedMultiplier;

  Vector2 velocity = Vector2.zero();
  final Random _rng = Random();

  // Tuning
  static const double _maxSpeedMultiplier = 2.6; // limit runaway speed
  static const double _minHorizontalRatio = 0.32; // % of baseSpeed that must remain horizontal
  static const double _speedGrowthPerHit = 1.03;
  static const double _maxSpinAngleDeg = 50; // +/- from perfectly horizontal

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final d = _diameter ?? 12;
    size = Vector2.all(d);
    anchor = Anchor.center;
    // Ensure the hitbox matches current size/shape
    add(CircleHitbox());
    reset();
  }

  void reset({bool towardPlayer = false}) {
    // Initial angle: slight vertical variation
    final angle = (_rng.nextDouble() * pi / 3) - pi / 6;
    final dir = towardPlayer ? pi : 0;
    velocity = Vector2(cos(dir + angle), sin(dir + angle)) * (baseSpeed * _globalSpeedMultiplier);
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Integrate position
    position += velocity * dt;

    final half = size.x / 2;
  final h = game.size.y;

    // Bounce off top/bottom walls (accounting for radius)
    if (position.y < half) {
      position.y = half;
      velocity.y = -velocity.y;
    } else if (position.y > h - half) {
      position.y = h - half;
      velocity.y = -velocity.y;
    }

    // Limit speed to avoid tunneling
    final maxSpeed = baseSpeed * _maxSpeedMultiplier * _globalSpeedMultiplier;
    if (velocity.length > maxSpeed) {
      velocity.scaleTo(maxSpeed);
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Paddle) {
      _bounceFrom(other, intersectionPoints: intersectionPoints);
    }
  }

  void _bounceFrom(Paddle paddle, {Set<Vector2>? intersectionPoints}) {
  // Speed before impact
    final incomingSpeed = velocity.length;
    final lower = baseSpeed * 0.9 * _globalSpeedMultiplier;
    final upper = baseSpeed * _maxSpeedMultiplier * _globalSpeedMultiplier;
    final targetSpeed = (incomingSpeed * _speedGrowthPerHit).clamp(lower, upper);

    final horizontalDir = -velocity.x.sign;

    // Offset -1..1 (top = -1, bottom = +1) based on actual contact point if available
    double contactY;
    if (intersectionPoints != null && intersectionPoints.isNotEmpty) {
      // Average intersection point for stability when multiple points
      final Vector2 avg = intersectionPoints.reduce((a, b) => a + b) /
          intersectionPoints.length.toDouble();
      contactY = avg.y;
    } else {
      contactY = position.y;
    }
    double offset = (contactY - paddle.position.y) / (paddle.size.y / 2);
    offset = offset.clamp(-1.0, 1.0);

    // Spin angle based on contact offset
    final maxAngleRad = _maxSpinAngleDeg * pi / 180.0;
    final angle = offset * maxAngleRad;

    // New velocity vector from polar components
    double newVx = cos(angle) * targetSpeed * horizontalDir;
    double newVy = sin(angle) * targetSpeed;

    // Minimum horizontal component to prevent the ball from becoming "vertical"
    final minHoriz = baseSpeed * _minHorizontalRatio * _globalSpeedMultiplier;
    if (newVx.abs() < minHoriz) {
      newVx = minHoriz * newVx.sign;
      final remaining = (targetSpeed * targetSpeed - newVx * newVx).clamp(0, double.infinity);
      newVy = newVy.sign * sqrt(remaining);
    }

    velocity
      ..x = newVx
      ..y = newVy;

    // Push the ball slightly away from the paddle to prevent sticking
    final separation = (size.x / 2) + (paddle.size.x / 2) + 0.5;
    position.x = paddle.isPlayer
        ? paddle.position.x + separation
        : paddle.position.x - separation;
  }

  @override
  void render(Canvas canvas) {
    final radius = size.x / 2;
    canvas.drawCircle(Offset.zero, radius, _paint);
  }

  // Called by game every 30s to speed up gameplay
  void increaseGlobalSpeed(double factor) {
    if (factor <= 0) return;
    _globalSpeedMultiplier *= factor;
    // Immediately scale current velocity so the change is felt right away
    velocity.scale(factor);
  }
}
