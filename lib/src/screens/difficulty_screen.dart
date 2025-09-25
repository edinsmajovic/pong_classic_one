import 'package:flutter/material.dart';
import '../game/difficulty.dart';
import '../app.dart';
import 'game_screen.dart';

class DifficultyScreen extends StatelessWidget {
  const DifficultyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final purchase = InheritedPurchase.of(context);
    final hasPremium = purchase.hasPremium;

    return Scaffold(
      appBar: AppBar(title: const Text('DIFFICULTY'), centerTitle: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: Difficulty.values.map((d) {
            final cfg = DifficultyConfigs.configFor(d, hasPremium: hasPremium);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: SizedBox(
                width: 320,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _colorFor(d, locked: cfg.locked),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.all(16),
                  ),
                  onPressed: cfg.locked
                      ? () async {
                          await purchase.buyRemoveAds();
                        }
                      : () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => GameScreen(difficulty: d)),
                          );
                        },
                  child: Column(
                    children: [
                      Text(_titleFor(d), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      if (cfg.locked)
                        const Text('PREMIUM ONLY', style: TextStyle(fontSize: 12, color: Colors.redAccent))
                      else
                        Text(_descFor(d), style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _colorFor(Difficulty d, {required bool locked}) {
    if (locked) return Colors.grey;
    switch (d) {
      case Difficulty.beginner:
        return Colors.green;
      case Difficulty.intermediate:
        return Colors.yellow;
      case Difficulty.expert:
        return Colors.orange;
      case Difficulty.insane:
        return Colors.red;
    }
  }

  String _titleFor(Difficulty d) => d.name.toUpperCase();
  String _descFor(Difficulty d) {
    switch (d) {
      case Difficulty.beginner:
        return 'Slow ball • Large paddles • Easy AI';
      case Difficulty.intermediate:
        return 'Medium speed • Normal paddles • Smart AI';
      case Difficulty.expert:
        return 'Fast ball • Small paddles • Hard AI';
      case Difficulty.insane:
        return 'Ultra fast • Tiny paddles • Perfect AI';
    }
  }
}
