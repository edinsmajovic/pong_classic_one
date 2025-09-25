import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'difficulty.dart';

class PongGame extends FlameGame with HasCollisionDetection {
  PongGame({required this.difficultyConfig, required this.onScore});

  final DifficultyConfig difficultyConfig;
  final void Function(int player, int ai) onScore;

  late Paddle playerPaddle;
  late Paddle aiPaddle;
  late Ball ball;

  int playerScore = 0;
  int aiScore = 0;
  final int targetScore = 11;

  @override
  Future<void> onLoad() async {
    playerPaddle = Paddle(isPlayer: true, heightFactor: difficultyConfig.paddleHeightFactor)
      ..position = Vector2(30, size.y / 2);
    aiPaddle = Paddle(isPlayer: false, heightFactor: difficultyConfig.paddleHeightFactor)
      ..position = Vector2(size.x - 30, size.y / 2);
    ball = Ball(baseSpeed: difficultyConfig.ballSpeed)
      ..position = size / 2;

    addAll([playerPaddle, aiPaddle, ball]);
  }

  void resetBall({bool towardPlayer = false}) {
    ball.reset(towardPlayer: towardPlayer);
  }

  void registerScore(bool playerScored) {
    if (playerScored) {
      playerScore++;
      resetBall(towardPlayer: false);
    } else {
      aiScore++;
      resetBall(towardPlayer: true);
    }
    onScore(playerScore, aiScore);
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Simple AI follow
    final dy = ball.position.y - aiPaddle.position.y;
    final direction = dy.sign;
    final move = direction * difficultyConfig.aiMaxSpeed * dt;
    if (dy.abs() < move.abs()) {
      aiPaddle.position.y = ball.position.y;
    } else {
      aiPaddle.position.y += move;
    }
    aiPaddle.clamp(size.y);
    playerPaddle.clamp(size.y);

    // Check scoring (ball out of bounds)
    if (ball.position.x < 0) {
      registerScore(false);
    } else if (ball.position.x > size.x) {
      registerScore(true);
    }
  }
}

class Paddle extends PositionComponent {
  Paddle({required this.isPlayer, required this.heightFactor});
  final bool isPlayer;
  final double heightFactor;
  static const double paddleWidth = 14;

  @override
  Future<void> onLoad() async {
    size = Vector2(paddleWidth, (parent as PongGame).size.y * heightFactor);
    anchor = Anchor.center;
  }

  void clamp(double screenHeight) {
    final half = size.y / 2;
    position.y = position.y.clamp(half, screenHeight - half);
  }

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromCenter(center: Offset.zero, width: size.x, height: size.y);
    final paint = Paint()..color = const Color(0xFFFFFFFF);
    canvas.drawRect(rect, paint);
  }
}

class Ball extends PositionComponent {
  Ball({required this.baseSpeed});
  final double baseSpeed;
  Vector2 velocity = Vector2.zero();
  final Random _rng = Random();

  @override
  Future<void> onLoad() async {
    size = Vector2.all(12);
    anchor = Anchor.center;
    reset();
  }

  void reset({bool towardPlayer = false}) {
    final angle = (_rng.nextDouble() * pi / 3) - pi / 6; // small vertical variation
    final dir = towardPlayer ? pi : 0;
    velocity = Vector2(cos(dir + angle), sin(dir + angle)) * baseSpeed;
  }

  @override
  void update(double dt) {
    position += velocity * dt;
  final parentSize = (parent as PongGame).size;
    // Bounce on top/bottom
    if (position.y < 0) {
      position.y = 0;
      velocity.y = -velocity.y;
    } else if (position.y > parentSize.y) {
      position.y = parentSize.y;
      velocity.y = -velocity.y;
    }

    // Paddle collisions (simple AABB)
    final game = parent as PongGame;
    if (_collides(game.playerPaddle) && velocity.x < 0) {
      _bounceFrom(game.playerPaddle);
    } else if (_collides(game.aiPaddle) && velocity.x > 0) {
      _bounceFrom(game.aiPaddle);
    }
  }

  bool _collides(Paddle paddle) {
    final paddleRect = Rect.fromCenter(
      center: Offset(paddle.position.x, paddle.position.y),
      width: paddle.size.x,
      height: paddle.size.y,
    );
    final ballRect = Rect.fromCenter(
      center: Offset(position.x, position.y),
      width: size.x,
      height: size.y,
    );
    return paddleRect.overlaps(ballRect);
  }

  void _bounceFrom(Paddle paddle) {
    velocity.x = -velocity.x * 1.03; // slight speed increase per hit
    // Add spin based on impact position
    final offset = (position.y - paddle.position.y) / (paddle.size.y / 2);
    velocity.y += offset * 60;
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = const Color(0xFFFFFFFF);
    canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: size.x, height: size.y), paint);
  }
}
