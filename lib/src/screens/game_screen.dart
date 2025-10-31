import 'package:flame/game.dart';
import 'package:flutter/material.dart';
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
  PongGame? game;
  int playerScore = 0;
  int aiScore = 0;
  bool _initialized = false;
  bool _gameOver = false;
  bool _dialogShown = false;
  bool _scoreUpdateScheduled = false;

  // Speed-up banner
  String? _speedBannerText;
  bool _speedBannerVisible = false;
  int _lastSpeedStep = 0;

  // Drag (absolute with preserved offset when touch starts on the paddle)
  final GlobalKey _arenaKey = GlobalKey(debugLabel: 'arena_key');
  final GlobalKey _gameKey = GlobalKey(debugLabel: 'game_widget_key');
  double? _dragOffsetWorldY; // difference between paddle center and finger in world coords

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
          setState(() {
            playerScore = player;
            aiScore = ai;
          });
          Future.microtask(() =>
              _showGameOverDialog(playerWon: playerWon, finalPlayer: player, finalAi: ai));
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
            if (_lastSpeedStep == step) {
              setState(() => _speedBannerVisible = false);
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
        _scoreUpdateScheduled = false;
        if (!mounted) return;
        setState(() {
          playerScore = player;
          aiScore = ai;
        });
      });
    }
  }

  void _showGameOverDialog({
    required bool playerWon,
    required int finalPlayer,
    required int finalAi,
  }) {
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
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('MENU'),
          ),
          ElevatedButton(
            onPressed: () {
              if (!mounted) return;
              Navigator.pop(context);
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
      _scoreUpdateScheduled = false;
    });
    game!
      ..playerScore = 0
      ..aiScore = 0
      ..resetBall()
      ..resumeEngine();
  }

  // --- Gesture helpers (delta-based) ---
  void _onDragStart(DragStartDetails details) {
    final box = _arenaKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || game == null || !game!.isInitialized) return;
    final local = box.globalToLocal(details.globalPosition);
    final hScreen = box.size.height;
    final hWorld = game!.size.y;
    final ratio = (hScreen > 0) ? (hWorld / hScreen) : 1.0;
    final worldY = local.dy * ratio;

    // If touch begins within the paddle, preserve the offset to avoid snap; else follow absolute
    final paddle = game!.playerPaddle;
    final half = paddle.size.y / 2;
    if (worldY >= paddle.position.y - half && worldY <= paddle.position.y + half) {
      _dragOffsetWorldY = paddle.position.y - worldY;
    } else {
      _dragOffsetWorldY = 0.0; // absolute follow
    }
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (game == null || !game!.isInitialized) return;
    final arenaBox = _arenaKey.currentContext?.findRenderObject() as RenderBox?;
    if (arenaBox == null) return;
    final local = arenaBox.globalToLocal(details.globalPosition);

    final hScreen = arenaBox.size.height;
    final hWorld = game!.size.y;
    final ratio = (hScreen > 0) ? (hWorld / hScreen) : 1.0;
    final worldY = local.dy * ratio;
    final targetY = worldY + (_dragOffsetWorldY ?? 0.0);
    game!.onPlayerDrag(targetY); // absolute follow with preserved offset
  }

  void _onDragEnd(DragEndDetails _) {
    _dragOffsetWorldY = null;
  }

  @override
  Widget build(BuildContext context) {
    if (game == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ======= SCORE BAR (fiksna visina po sadržaju) =======
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
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
                ],
              ),
            ),

            // Speed banner odmah ispod skora
            AnimatedOpacity(
              opacity: _speedBannerVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Center(
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

            // ======= ARENA (uzima sav preostali prostor) =======
            Expanded(
              child: GestureDetector(
                onVerticalDragStart: _onDragStart,
                onVerticalDragUpdate: _onDragUpdate,
                onVerticalDragEnd: _onDragEnd,
                child: Container(
                  key: _arenaKey, // referenca za tačne dimenzije arene (hScreen)
                  clipBehavior: Clip.hardEdge,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black, Color(0xFF041B04)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: GameWidget(key: _gameKey, game: game!),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
 