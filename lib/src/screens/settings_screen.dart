import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SETTINGS'), centerTitle: true),
      body: const Center(
        child: Text(
          'Settings coming soon:\n\n• Sound Effects\n• Music\n• Control Sensitivity\n• Themes',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
