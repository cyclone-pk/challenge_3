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
      title: 'Flip Cards Memory Game',
      theme: ThemeData(
        // <-- Use LuckiestGuy everywhere
        fontFamily: 'LuckiestGuy',
        // You can also customize textTheme if needed:
        // textTheme: Theme.of(context).textTheme.apply(fontFamily: 'LuckiestGuy'),
      ),
      home: const HomeScreen(),
    );
  }
}
