import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'difficulty.dart';

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

  late Paddle playerPaddle;
  late Paddle aiPaddle;
  late Ball ball;

  int playerScore = 0;
  int aiScore = 0;

  bool _initialized = false;
  bool get isInitialized => _initialized;

  final Timer _scoreCooldownTimer = Timer(0.4, autoStart: false);
  Timer? _speedUpTimer;
  int _speedUpSteps = 0;

  static const double _paddleXMargin = 30.0;

  double _aiTargetY = 0;
  double _aiDecisionTimer = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);

    if (!_initialized && size.x > 0 && size.y > 0) {
      // Add arena decoration inside the Flame world to guarantee perfect alignment
      add(ArenaDecoration()..priority = -10);

      playerPaddle = Paddle(
        isPlayer: true,
        heightFactor: difficultyConfig.paddleHeightFactor,
        color: Paint()..color = Colors.white,
      )..anchor = Anchor.center
       ..position = Vector2(_paddleXMargin, size.y / 2);

      aiPaddle = Paddle(
        isPlayer: false,
        heightFactor: difficultyConfig.paddleHeightFactor,
        color: Paint()..color = Colors.white,
      )..anchor = Anchor.center
       ..position = Vector2(size.x - _paddleXMargin, size.y / 2);

      ball = Ball(
        baseSpeed: difficultyConfig.ballSpeed,
        color: Paint()..color = Colors.white,
        diameter: difficultyConfig.ballSize,
      )..anchor = Anchor.center
       ..position = size / 2;

      addAll([playerPaddle, aiPaddle, ball]);
      _initialized = true;

      // koriguj X sada kada paddle.size.x postoji (posle onLoad)
      playerPaddle.position.x = _paddleXMargin + playerPaddle.size.x / 2;
      aiPaddle.position.x = size.x - _paddleXMargin - aiPaddle.size.x / 2;

      _speedUpTimer = Timer(30, repeat: true, autoStart: true, onTick: () {
        ball.increaseGlobalSpeed(1.10);
        _speedUpSteps++;
        onSpeedUp?.call(ball.globalSpeedMultiplier, _speedUpSteps);
      });
    }

    if (_initialized) {
      playerPaddle.size.y = size.y * playerPaddle.heightFactor;
      aiPaddle.size.y = size.y * aiPaddle.heightFactor;

      playerPaddle.position.x = _paddleXMargin + playerPaddle.size.x / 2;
      aiPaddle.position.x = size.x - _paddleXMargin - aiPaddle.size.x / 2;

      playerPaddle.syncHitbox();
      aiPaddle.syncHitbox();
      playerPaddle.clamp(size.y);
      aiPaddle.clamp(size.y);

      if (ball.position.x < 0 || ball.position.x > size.x) {
        ball.position = size / 2;
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_initialized) return;

    _scoreCooldownTimer.update(dt);
    _speedUpTimer?.update(dt);

    // AI meta
    _aiDecisionTimer -= dt;
    if (_aiDecisionTimer <= 0) {
      _aiDecisionTimer += difficultyConfig.aiReactionTime;

      double predictedY = ball.position.y;
      if (ball.velocity.x > 0.0) {
        final distanceX = (aiPaddle.position.x - ball.position.x).clamp(1, double.infinity);
        final timeToReach = distanceX / ball.velocity.x.abs();
        predictedY = ball.position.y + ball.velocity.y * timeToReach;

        final h = size.y;
        if (h > 0) {
          double period = 2 * h;
          double modY = predictedY % period;
          if (modY < 0) modY += period;
          if (modY > h) modY = period - modY;
          predictedY = modY;
        }
      }

      final blend = difficultyConfig.aiAnticipation;
      double aimY = predictedY * blend + ball.position.y * (1 - blend);

      if (difficultyConfig.aiErrorStd > 0) {
        final u1 = max(Random().nextDouble(), 1e-6);
        final u2 = Random().nextDouble();
        final z0 = sqrt(-2.0 * log(u1)) * cos(2 * pi * u2);
        aimY += z0 * difficultyConfig.aiErrorStd;
      }

      final half = aiPaddle.size.y / 2;
      _aiTargetY = aimY.clamp(half, size.y - half);
    }

    // AI pomeranje
    final double dy = _aiTargetY - aiPaddle.position.y;
    const double deadZone = 6.0;
    if (dy.abs() > deadZone) {
      final playerLead = (playerScore - aiScore).clamp(0, 100);
      final adaptiveFactor = 1 + playerLead * difficultyConfig.aiAdaptiveBoost;
      final maxSpeed = difficultyConfig.aiMaxSpeed * adaptiveFactor;
      final desiredVel = dy.sign * maxSpeed;
      final maxDeltaV = difficultyConfig.aiMaxAccel * dt;
      final currentVel = aiPaddle.currentVelY;
      final deltaV = (desiredVel - currentVel).clamp(-maxDeltaV, maxDeltaV);
      final newVel = currentVel + deltaV;
      aiPaddle.currentVelY = newVel;
      aiPaddle.position.y += newVel * dt;
    } else {
      final currentVel = aiPaddle.currentVelY;
      final decel = difficultyConfig.aiMaxAccel * dt;
      if (currentVel.abs() <= decel) {
        aiPaddle.currentVelY = 0;
      } else {
        aiPaddle.currentVelY = currentVel - decel * currentVel.sign;
      }
    }

    aiPaddle.clamp(size.y);
    playerPaddle.clamp(size.y);

    // Poeni
    if (!_scoreCooldownTimer.isRunning()) {
      final half = ball.size.x / 2;
      if (ball.position.x < -half) {
        _registerScore(playerScored: false);
      } else if (ball.position.x > size.x + half) {
        _registerScore(playerScored: true);
      }
    }
  }

  /// Pomeri igračevu palicu za delta u WORLD koordinatama (bez snap-a).
  void nudgePlayer(double worldDeltaY) {
    playerPaddle.position.y += worldDeltaY;
    playerPaddle.clamp(size.y);
  }

  /// (Zadržiš i ako negde želiš apsolutno, ali je više ne koristimo iz UI-a)
  void onPlayerDrag(double worldY) {
    playerPaddle.position.y = worldY;
    playerPaddle.clamp(size.y);
  }

  void _resetBall({required bool towardPlayer}) {
    ball.position = size / 2;
    ball.reset(towardPlayer: towardPlayer);
    _scoreCooldownTimer.start();
  }

  void _registerScore({required bool playerScored}) {
    if (playerScored) {
      playerScore++;
    } else {
      aiScore++;
    }

    onScore(playerScore, aiScore);

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

    _resetBall(towardPlayer: !playerScored);
  }

  void resetBall() => _resetBall(towardPlayer: false);
}

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

  double currentVelY = 0.0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final width = game.difficultyConfig.paddleWidth;
    size = Vector2(width, game.size.y * heightFactor);
    anchor = Anchor.center;
    // Align hitbox with visual rect drawn from top-left of the local bounds
    _hitbox = RectangleHitbox(size: size, anchor: Anchor.topLeft)
      ..position = Vector2.zero();
    add(_hitbox!);
  }

  void syncHitbox() {
    final hb = _hitbox;
    if (hb == null) return;
    hb
      ..size = size
      ..position = Vector2.zero()
      ..anchor = Anchor.topLeft;
  }

  void clamp(double screenHeight) {
    final half = size.y / 2;
    const double eps = 2.0; // slightly larger inset for crisp visual boundary
    position.y = position.y.clamp(half + eps, screenHeight - half - eps);
  }

  @override
  void render(Canvas canvas) {
    // With anchor = center, Flame translates the canvas so local origin is the
    // top-left of this component's bounds. Draw from top-left to match hitbox.
    final prevAA = _paint.isAntiAlias;
    _paint.isAntiAlias = false;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      _paint,
    );
    _paint.isAntiAlias = prevAA;
  }
}

/// Draws the arena border and center dashed line within the Flame world
class ArenaDecoration extends Component with HasGameReference<PongGame> {
  late final Paint _borderPaint;
  late final Paint _linePaint;

  @override
  Future<void> onLoad() async {
    _borderPaint = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    _linePaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 4;
  }

  @override
  void render(Canvas canvas) {
    final sz = game.size;
    // Border
    canvas.drawRect(
      Rect.fromLTWH(0, 0, sz.x, sz.y),
      _borderPaint,
    );

    // Center dashed line
    const double segment = 18.0;
    const double gap = 14.0;
    final double x = sz.x / 2;
    double y = 0;
    while (y < sz.y) {
      final double y2 = (y + segment).clamp(0, sz.y);
      canvas.drawLine(Offset(x, y), Offset(x, y2), _linePaint);
      y += segment + gap;
    }
  }
}

class Ball extends PositionComponent
    with HasGameReference<PongGame>, CollisionCallbacks {
  Ball({
    required this.baseSpeed,
    required Paint color,
    double? diameter,
  })  : _paint = color,
        _diameter = diameter;

  final double baseSpeed;
  final Paint _paint;
  final double? _diameter;
  double _globalSpeedMultiplier = 1.0;
  double get globalSpeedMultiplier => _globalSpeedMultiplier;

  Vector2 velocity = Vector2.zero();
  final Random _rng = Random();

  static const double _maxSpeedMultiplier = 2.6;
  static const double _minHorizontalRatio = 0.32;
  static const double _speedGrowthPerHit = 1.03;
  static const double _maxSpinAngleDeg = 50;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final d = _diameter ?? 12;
    size = Vector2.all(d);
    anchor = Anchor.center;
    add(CircleHitbox());
    reset();
  }

  void reset({bool towardPlayer = false}) {
    final angle = (_rng.nextDouble() * pi / 3) - pi / 6;
    final dir = towardPlayer ? pi : 0;
    velocity =
        Vector2(cos(dir + angle), sin(dir + angle)) * (baseSpeed * _globalSpeedMultiplier);
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += velocity * dt;

    final half = size.x / 2;
    final h = game.size.y;

    if (position.y < half) {
      position.y = half;
      velocity.y = -velocity.y;
    } else if (position.y > h - half) {
      position.y = h - half;
      velocity.y = -velocity.y;
    }

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
    final incomingSpeed = velocity.length;
    final lower = baseSpeed * 0.9 * _globalSpeedMultiplier;
    final upper = baseSpeed * _maxSpeedMultiplier * _globalSpeedMultiplier;
    final targetSpeed = (incomingSpeed * _speedGrowthPerHit).clamp(lower, upper);

    final horizontalDir = -velocity.x.sign;

    double contactY = position.y;
    if (intersectionPoints != null && intersectionPoints.isNotEmpty) {
      final avg = intersectionPoints.reduce((a, b) => a + b) /
          intersectionPoints.length.toDouble();
      contactY = avg.y;
    }
    double offset = (contactY - paddle.position.y) / (paddle.size.y / 2);
    offset = offset.clamp(-1.0, 1.0);

    final maxAngleRad = _maxSpinAngleDeg * pi / 180.0;
    final angle = offset * maxAngleRad;

    double newVx = cos(angle) * targetSpeed * horizontalDir;
    double newVy = sin(angle) * targetSpeed;

    final minHoriz = baseSpeed * _minHorizontalRatio * _globalSpeedMultiplier;
    if (newVx.abs() < minHoriz) {
      newVx = minHoriz * newVx.sign;
      final remaining =
          (targetSpeed * targetSpeed - newVx * newVx).clamp(0, double.infinity);
      newVy = newVy.sign * sqrt(remaining);
    }

    velocity
      ..x = newVx
      ..y = newVy;

    final separation = (size.x / 2) + (paddle.size.x / 2) + 0.5;
    position.x = paddle.isPlayer
        ? paddle.position.x + separation
        : paddle.position.x - separation;
  }

  @override
  void render(Canvas canvas) {
    // With anchor = center, draw the ball centered at the local origin.
    final radius = size.x / 2;
    canvas.drawCircle(Offset.zero, radius, _paint);
  }

  void increaseGlobalSpeed(double factor) {
    if (factor <= 0) return;
    _globalSpeedMultiplier *= factor;
    velocity.scale(factor);
  }
}