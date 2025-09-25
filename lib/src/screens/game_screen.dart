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
  late PongGame game;
  int playerScore = 0;
  int aiScore = 0;

  @override
  void initState() {
    super.initState();
    final purchase = InheritedPurchase.of(context);
    final cfg = DifficultyConfigs.configFor(widget.difficulty, hasPremium: purchase.hasPremium);
    game = PongGame(
      difficultyConfig: cfg,
      onScore: (p, a) {
        setState(() {
          playerScore = p;
          aiScore = a;
        });
        if (p >= game.targetScore || a >= game.targetScore) {
          Future.microtask(() => _showGameOverDialog(p >= game.targetScore));
        }
      },
    );
  }

  void _showGameOverDialog(bool playerWon) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(playerWon ? 'YOU WIN' : 'YOU LOSE'),
        content: Text('Final Score: $playerScore - $aiScore'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // dialog
              Navigator.pop(context); // game screen
            },
            child: const Text('MENU'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // dialog
              setState(() {
                playerScore = 0;
                aiScore = 0;
              });
              game.playerScore = 0;
              game.aiScore = 0;
              game.resetBall();
            },
            child: const Text('RETRY'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                GameWidget(game: game),
                Positioned(
                  top: 8,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$playerScore', style: const TextStyle(fontSize: 32, color: Colors.white)),
                      const SizedBox(width: 30),
                      Text('$aiScore', style: const TextStyle(fontSize: 32, color: Colors.white54)),
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
    );
  }
}
