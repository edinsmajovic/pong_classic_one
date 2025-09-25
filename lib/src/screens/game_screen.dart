import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'dart:ui' show FontFeature; // for tabular figures
import '../game/pong_game.dart';
import '../game/difficulty.dart';
import '../app.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.difficulty});
  final Difficulty difficulty;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  PongGame? game; // created after we can read purchase state
  int playerScore = 0;
  int aiScore = 0;
  bool _initialized = false;
  bool _gameOver = false;
  bool _dialogShown = false;
  bool _scoreUpdateScheduled = false;

  // Drag state
  double? _dragStartPaddleY;
  double? _dragStartGlobalY;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final purchase = InheritedPurchase.of(context);
      final cfg = DifficultyConfigs.configFor(
        widget.difficulty,
        hasPremium: purchase.hasPremium,
      );
      game = PongGame(
        difficultyConfig: cfg,
        onScore: _handleScore,
        onGameOver: ({required bool playerWon, required int player, required int ai}) {
          if (!mounted) return;
          _gameOver = true;
          Future.microtask(() => _showGameOverDialog(playerWon));
        },
      );
      _initialized = true;
    }
  }

  void _handleScore(int player, int ai) {
    if (!mounted || _gameOver) return;
    if (!_scoreUpdateScheduled) {
      _scoreUpdateScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _gameOver) return;
        _scoreUpdateScheduled = false;
        setState(() {
          playerScore = player;
          aiScore = ai;
        });
        // Game over now handled by onGameOver callback from PongGame
      });
    }
  }

  void _showGameOverDialog(bool playerWon) {
    if (_dialogShown || !mounted) return;
    _dialogShown = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(playerWon ? 'YOU WIN' : 'YOU LOSE'),
        content: Text('Final Score: $playerScore - $aiScore'),
        actions: [
          TextButton(
            onPressed: () {
              if (!mounted) return;
              Navigator.pop(context); // dialog
              Navigator.pop(context); // back to menu
            },
            child: const Text('MENU'),
          ),
          ElevatedButton(
            onPressed: () {
              if (!mounted) return;
              Navigator.pop(context); // dialog
              _restart();
            },
            child: const Text('RETRY'),
          ),
        ],
      ),
    );
  }

  void _restart() {
    setState(() {
      playerScore = 0;
      aiScore = 0;
      _gameOver = false;
      _dialogShown = false;
    });
    game!
      ..playerScore = 0
      ..aiScore = 0
      ..resetBall()
      ..resumeEngine();
  }

  @override
  Widget build(BuildContext context) {
    if (game == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: GestureDetector(
        onVerticalDragStart: (details) {
          final box = context.findRenderObject() as RenderBox?;
          if (box == null || game == null || !game!.isInitialized) return;
          final local = box.globalToLocal(details.globalPosition);
          _dragStartGlobalY = local.dy;
          _dragStartPaddleY = game!.playerPaddle.position.y;
        },
        onVerticalDragUpdate: (details) {
          if (game == null || !game!.isInitialized || _dragStartGlobalY == null || _dragStartPaddleY == null) return;
          final box = context.findRenderObject() as RenderBox?;
          if (box == null) return;
          final local = box.globalToLocal(details.globalPosition);
          final delta = local.dy - _dragStartGlobalY!;
          final targetY = _dragStartPaddleY! + delta;
          game!.onPlayerDrag(targetY);
        },
        onVerticalDragEnd: (_) {
          _dragStartGlobalY = null;
          _dragStartPaddleY = null;
        },
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black, Color(0xFF041B04)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  CustomPaint(
                    painter: _CenterLinePainter(),
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                  ),
                  GameWidget(game: game!),
                  Positioned(
                    top: 8,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$playerScore',
                          style: const TextStyle(
                            fontSize: 32,
                            color: Colors.white,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(width: 30),
                        Text(
                          '$aiScore',
                          style: const TextStyle(
                            fontSize: 32,
                            color: Colors.white54,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CenterLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 4;
    const segment = 18.0;
    const gap = 14.0;
    double y = 0;
    final x = size.width / 2;
    while (y < size.height) {
      canvas.drawLine(Offset(x, y), Offset(x, (y + segment).clamp(0, size.height)), paint);
      y += segment + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
