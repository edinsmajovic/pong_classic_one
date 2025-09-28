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
  // Speed-up banner state
  String? _speedBannerText;
  bool _speedBannerVisible = false;
  int _lastSpeedStep = 0;

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
          // Ensure UI reflects the final score before showing dialog
          setState(() {
            playerScore = player;
            aiScore = ai;
          });
          Future.microtask(() => _showGameOverDialog(playerWon: playerWon, finalPlayer: player, finalAi: ai));
        },
        onSpeedUp: (multiplier, step) {
          if (!mounted) return;
          final m = multiplier.toStringAsFixed(2);
          setState(() {
            _lastSpeedStep = step;
            _speedBannerText = 'Speed up x$m';
            _speedBannerVisible = true;
          });
          Future.delayed(const Duration(milliseconds: 1600), () {
            if (!mounted) return;
            // Only hide if no newer step arrived meanwhile
            if (_lastSpeedStep == step) {
              setState(() {
                _speedBannerVisible = false;
              });
            }
          });
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
        // Always clear the scheduling flag so future scores can update
        _scoreUpdateScheduled = false;
        if (!mounted) return;
        // Update the UI score even if the game just ended so 11 is visible
        setState(() {
          playerScore = player;
          aiScore = ai;
        });
        // Game over now handled by onGameOver callback from PongGame
      });
    }
  }

  void _showGameOverDialog({required bool playerWon, required int finalPlayer, required int finalAi}) {
    if (_dialogShown || !mounted) return;
    _dialogShown = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(playerWon ? 'YOU WIN' : 'YOU LOSE'),
        content: Text('Final Score: $finalPlayer - $finalAi'),
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
      _scoreUpdateScheduled = false; // reset guards
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
                  // Speed-up floating banner
                  Positioned(
                    top: 52,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                      child: AnimatedOpacity(
                        opacity: _speedBannerVisible ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        child: Center(
                          child: AnimatedScale(
                            scale: _speedBannerVisible ? 1.0 : 0.98,
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOut,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white24, width: 1),
                              ),
                              child: Text(
                                _speedBannerText ?? '',
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                              ),
                            ),
                          ),
                        ),
                      ),
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
