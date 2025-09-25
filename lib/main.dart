import 'package:flutter/material.dart';

void main() {
  runApp(const PongApp());
}

class PongApp extends StatelessWidget {
  const PongApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pong Classic One',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.green,
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: Colors.white, fontSize: 32, fontFamily: 'monospace'),
          displayMedium: TextStyle(color: Colors.white, fontSize: 24, fontFamily: 'monospace'),
          bodyLarge: TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'monospace'),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.black,
            textStyle: const TextStyle(fontSize: 18, fontFamily: 'monospace'),
          ),
        ),
      ),
      home: const MenuScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Retro PONG title
            Text(
              'PONG',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontSize: 64,
                letterSpacing: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'CLASSIC ONE',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontSize: 16,
                letterSpacing: 4,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 60),
            
            // Menu buttons
            SizedBox(
              width: 200,
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GameScreen(difficulty: Difficulty.beginner),
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
                        MaterialPageRoute(builder: (context) => const DifficultyScreen()),
                      );
                    },
                    child: const Text('DIFFICULTY'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingsScreen()),
                      );
                    },
                    child: const Text('SETTINGS'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum Difficulty { beginner, intermediate, expert, insane }

class DifficultyScreen extends StatelessWidget {
  const DifficultyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
  title: const Text('DIFFICULTY'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildDifficultyButton(context, Difficulty.beginner, 'BEGINNER', 'Slow ball • Large paddles • Easy AI'),
            const SizedBox(height: 16),
            _buildDifficultyButton(context, Difficulty.intermediate, 'INTERMEDIATE', 'Medium speed • Normal paddles • Smart AI'),
            const SizedBox(height: 16),
            _buildDifficultyButton(context, Difficulty.expert, 'EXPERT', 'Fast ball • Small paddles • Hard AI'),
            const SizedBox(height: 16),
            _buildDifficultyButton(context, Difficulty.insane, 'INSANE', 'Ultra fast • Tiny paddles • Perfect AI'),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyButton(BuildContext context, Difficulty difficulty, String title, String description) {
    Color color;
    switch (difficulty) {
      case Difficulty.beginner:
        color = Colors.green;
        break;
      case Difficulty.intermediate:
        color = Colors.yellow;
        break;
      case Difficulty.expert:
        color = Colors.orange;
        break;
      case Difficulty.insane:
        color = Colors.red;
        break;
    }

    return SizedBox(
      width: 300,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.all(16),
        ),
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => GameScreen(difficulty: difficulty),
            ),
          );
        },
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(description, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('SETTINGS'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'Settings will be implemented here:\n\n• Sound Effects ON/OFF\n• Music ON/OFF\n• Control Sensitivity\n• Theme Selection',
          style: TextStyle(color: Colors.white, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class GameScreen extends StatelessWidget {
  final Difficulty difficulty;
  
  const GameScreen({super.key, required this.difficulty});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'GAME SCREEN',
              style: Theme.of(context).textTheme.displayLarge,
            ),
            const SizedBox(height: 20),
            Text(
              'Difficulty: ${difficulty.name.toUpperCase()}',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 40),
            const Text(
              'Game implementation coming next!',
              style: TextStyle(color: Colors.green, fontSize: 18),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('BACK TO MENU'),
            ),
          ],
        ),
      ),
    );
  }
}