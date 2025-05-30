// lib/ui/game_play_screen.dart

import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../config/card_images.dart';

class GameScreen extends StatefulWidget {
  /// Starting level (1, 2 or 3)
  final int startingLevel;
  const GameScreen({super.key, this.startingLevel = 1});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  // Level state
  late int level;
  final Map<int, int> fruitsPerLevel = {1: 2, 2: 6, 3: 15};

  // Holds the asset paths for each card in the grid
  late List<String> cardData;
  List<bool> cardFlipped = [];
  List<bool> cardMatched = [];
  List<int> selectedIndices = [];
  int matchedPairs = 0;

  // For drawing the connecting line
  final Map<int, GlobalKey> cardKeys = {};
  final GlobalKey stackKey = GlobalKey();
  Offset? lineStart, lineEnd;

  @override
  void initState() {
    super.initState();
    // Clamp to 1–3 just in case
    level = widget.startingLevel.clamp(1, 3);
    _initializeGame();
  }

  void _initializeGame() {
    // Pick N random fruit asset paths for this level
    final fruits = CardImages.pickRandom(fruitsPerLevel[level]!);
    // Duplicate & shuffle for matching pairs
    cardData = [...fruits, ...fruits]..shuffle(Random());

    cardFlipped = List.filled(cardData.length, false);
    cardMatched = List.filled(cardData.length, false);
    selectedIndices.clear();
    matchedPairs = 0;
    lineStart = lineEnd = null;

    // Create a GlobalKey for each card so we can locate its center
    cardKeys.clear();
    for (var i = 0; i < cardData.length; i++) {
      cardKeys[i] = GlobalKey();
    }

    setState(() {});
  }

  void _onCardTap(int index) {
    // Ignore taps during reveal or on already flipped/matched cards
    if (cardFlipped[index] || selectedIndices.length == 2 || cardMatched[index]) {
      return;
    }

    setState(() {
      cardFlipped[index] = true;
      selectedIndices.add(index);
    });

    if (selectedIndices.length == 2) {
      // Compute line endpoints after the current frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final aBox = cardKeys[selectedIndices[0]]!
            .currentContext!
            .findRenderObject() as RenderBox;
        final bBox = cardKeys[selectedIndices[1]]!
            .currentContext!
            .findRenderObject() as RenderBox;

        // Global centers of each card
        final aGlobal = aBox.localToGlobal(aBox.size.center(Offset.zero));
        final bGlobal = bBox.localToGlobal(bBox.size.center(Offset.zero));

        // Convert to Stack-local coordinates
        final stackBox = stackKey.currentContext!.findRenderObject() as RenderBox;
        setState(() {
          lineStart = stackBox.globalToLocal(aGlobal);
          lineEnd   = stackBox.globalToLocal(bGlobal);
        });
      });

      // Delay then check for match
      Future.delayed(const Duration(milliseconds: 800), () {
        final i = selectedIndices[0], j = selectedIndices[1];
        if (cardData[i] == cardData[j]) {
          cardMatched[i] = cardMatched[j] = true;
          matchedPairs++;
        } else {
          cardFlipped[i] = cardFlipped[j] = false;
        }
        selectedIndices.clear();
        setState(() {
          lineStart = lineEnd = null;
        });

        // If level complete, show dialog
        if (matchedPairs == fruitsPerLevel[level]) {
          _showLevelDialog();
        }
      });
    }
  }

  void _showLevelDialog() {
    final isFinal = level == 3;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isFinal ? 'All Levels Complete!' : 'Level $level Complete'),
        content: Text(isFinal
            ? 'You’ve matched every fruit! Restart at Level 1?'
            : 'Great job! Proceed to Level ${level + 1}?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              level = isFinal ? 1 : level + 1;
              _initializeGame();
            },
            child: Text(isFinal ? 'Restart Level 1' : 'Go to Level ${level + 1}'),
          )
        ],
      ),
    );
  }

  Widget _buildCard(int index) {
    // Empty space for matched cards
    if (cardMatched[index]) return const SizedBox();

    final isFlipped = cardFlipped[index];
    return GestureDetector(
      onTap: () => _onCardTap(index),
      child: Container(
        key: cardKeys[index],
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            isFlipped ? cardData[index] : CardImages.cardBack,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine # of columns by screen width
    final crossCount = MediaQuery.sizeOf(context).width ~/ 100;
    return Scaffold(
      backgroundColor: Colors.indigo[900],
      appBar: AppBar(
        title: Text('Level ${level} – Match the Fruits'),
      ),
      body: Stack(
        key: stackKey,
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/game_background.png',
              fit: BoxFit.cover,
            ),
          ),
          // Grid of cards
          Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: .8,
              ),
              itemCount: cardData.length,
              itemBuilder: (_, i) => _buildCard(i),
            ),
          ),

          // Draw connecting line
          if (lineStart != null && lineEnd != null)
            Positioned.fill(
              child: CustomPaint(
                painter: _LinePainter(lineStart!, lineEnd!),
              ),
            ),
        ],
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  final Offset start, end;
  _LinePainter(this.start, this.end);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.yellowAccent
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    canvas.drawLine(start, end, paint);
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) =>
      old.start != start || old.end != end;
}
