// lib/screens/home_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:challenge3/ui/game_play_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _startGame(BuildContext context, int level) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(startingLevel: level),
      ),
    );
  }

  void _exitGame() => exit(0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // no backgroundColor needed; decoration covers it
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/game_background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Flip Cards Memory Game',
                style: TextStyle(
                  fontSize: 28,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              for (var lvl = 1; lvl <= 3; lvl++) ...[
                ElevatedButton(
                  onPressed: () => _startGame(context, lvl),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 48, vertical: 14),
                    backgroundColor: Colors.green.withOpacity(0.8),
                  ),
                  child: Text(
                    'Start Level $lvl',
                    style: const TextStyle(fontSize: 20, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _exitGame,
                style: ElevatedButton.styleFrom(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 48, vertical: 14),
                  backgroundColor: Colors.red.withOpacity(0.8),
                ),
                child: const Text(
                  'Exit',
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
