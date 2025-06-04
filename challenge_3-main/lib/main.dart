import 'package:flutter/material.dart';
import 'ui/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flip Cards Memory Game',
      theme: ThemeData(
        fontFamily: 'LuckiestGuy',
      ),
      home: const HomeScreen(),
    );
  }
}
