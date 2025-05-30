import 'package:challenge3/ui/home_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const FlipCardGame());
}

class FlipCardGame extends StatelessWidget {
  const FlipCardGame({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flip Card Memory Game',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
