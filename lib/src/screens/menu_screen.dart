import 'package:flutter/material.dart';
import '../services/ads_service.dart';
import '../game/difficulty.dart';
import 'difficulty_screen.dart';
import 'game_screen.dart';
import 'settings_screen.dart';
import '../app.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key, required this.adsService});
  final AdsService adsService;

  @override
  Widget build(BuildContext context) {
    final purchase = InheritedPurchase.of(context);
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('PONG', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 64, letterSpacing: 8, fontWeight: FontWeight.bold)),
                Text('CLASSIC ONE', style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 16, letterSpacing: 4, color: Colors.green)),
                const SizedBox(height: 60),
                SizedBox(
                  width: 220,
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GameScreen(difficulty: Difficulty.beginner),
                            ),
                          );
                        },
                        child: const Text('PLAY'),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DifficultyScreen(),
                            ),
                          );
                        },
                        child: const Text('DIFFICULTY'),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SettingsScreen(),
                            ),
                          );
                        },
                        child: const Text('SETTINGS'),
                      ),
                      const SizedBox(height: 32),
                      if (!purchase.adsRemoved)
                        TextButton(
                          onPressed: () async {
                            await purchase.buyRemoveAds();
                          },
                          child: const Text('REMOVE ADS / UNLOCK', style: TextStyle(color: Colors.green)),
                        )
                      else
                        const Text('PREMIUM ACTIVE', style: TextStyle(color: Colors.green)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (adsService.shouldShowBanner && !purchase.adsRemoved)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 48,
                color: Colors.green.shade900.withOpacity(0.3),
                alignment: Alignment.center,
                child: const Text('[ BANNER AD PLACEHOLDER ]', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ),
            )
        ],
      ),
    );
  }
}
