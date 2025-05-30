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
  // Default card size parameters
  static const double _defaultCardW = 100;
  static const double _defaultAspect = 0.8;
  static const double _spacing = 8;

  // Level state
  late int level;
  final Map<int, int> fruitsPerLevel = {1: 2, 2: 6, 3: 15};

  // Card data & flip/match state
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
    level = widget.startingLevel.clamp(1, 3);
    _initializeGame();
  }

  void _initializeGame() {
    // Pick N random fruit assets for this level
    final fruits = CardImages.pickRandom(fruitsPerLevel[level]!);
    cardData = [...fruits, ...fruits]..shuffle(Random());

    cardFlipped = List.filled(cardData.length, false);
    cardMatched = List.filled(cardData.length, false);
    selectedIndices.clear();
    matchedPairs = 0;
    lineStart = lineEnd = null;

    // Assign a GlobalKey to each card to find its position
    cardKeys.clear();
    for (var i = 0; i < cardData.length; i++) {
      cardKeys[i] = GlobalKey();
    }

    setState(() {});
  }

  void _onCardTap(int index) {
    if (cardFlipped[index] ||
        selectedIndices.length == 2 ||
        cardMatched[index]) return;

    setState(() {
      cardFlipped[index] = true;
      selectedIndices.add(index);
    });

    if (selectedIndices.length == 2) {
      // After layout, compute line endpoints
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final aBox = cardKeys[selectedIndices[0]]!
            .currentContext!
            .findRenderObject() as RenderBox;
        final bBox = cardKeys[selectedIndices[1]]!
            .currentContext!
            .findRenderObject() as RenderBox;

        final aGlobal = aBox.localToGlobal(aBox.size.center(Offset.zero));
        final bGlobal = bBox.localToGlobal(bBox.size.center(Offset.zero));

        final stackBox =
        stackKey.currentContext!.findRenderObject() as RenderBox;
        setState(() {
          lineStart = stackBox.globalToLocal(aGlobal);
          lineEnd = stackBox.globalToLocal(bGlobal);
        });
      });

      // Delay then check match
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

  /// Computes grid params so N cards fill W×H exactly.
  GridParams _computeGrid(double W, double H, int N) {
    if (N == 0 || W == 0 || H == 0) return GridParams(1, 1, 1.0);
    final aspect = W / H;
    final rawCols = sqrt(N * aspect);
    final cols = max(1, rawCols.floor());
    final rows = (N / cols).ceil();
    final cellW = W / cols;
    final cellH = H / rows;
    final childAspect = cellW / cellH;
    return GridParams(cols, rows, childAspect);
  }

  Widget _buildCard(int index) {
    if (cardMatched[index]) return const SizedBox();
    final isFlipped = cardFlipped[index];
    return GestureDetector(
      onTap: () => _onCardTap(index),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, anim) {
          final rotate = Tween(begin: pi, end: 0.0).animate(anim);
          return AnimatedBuilder(
            animation: rotate,
            child: child,
            builder: (_, child) {
              final isUnder = (ValueKey(isFlipped) != child!.key);
              var tilt = (rotate.value - pi / 2).abs() - pi / 2;
              tilt *= isUnder ? -0.003 : 0.003;
              final matrix = Matrix4.rotationY(rotate.value)
                ..setEntry(3, 0, tilt);
              return Transform(
                transform: matrix,
                alignment: Alignment.center,
                child: child,
              );
            },
          );
        },
        child: Container(
          key: ValueKey(isFlipped),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white, width: 2),
            image: DecorationImage(
              image: AssetImage(
                isFlipped ? cardData[index] : CardImages.cardBack,
              ),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate available width & height for the grid
    final mq = MediaQuery.of(context);
    final W = mq.size.width - 16; // horizontal padding
    final H = mq.size.height
        - kToolbarHeight
        - mq.padding.top
        - mq.padding.bottom
        - 16; // vertical padding

    // Default grid metrics
    final defaultCols =
    max(1, (W + _spacing) ~/ (_defaultCardW + _spacing));
    final defaultRows = (cardData.length / defaultCols).ceil();
    final totalDefaultH =
        defaultRows * (_defaultCardW / _defaultAspect) +
            (defaultRows - 1) * _spacing;

    // Choose default or auto-fit layout
    int cols;
    double childAspect;
    if (totalDefaultH <= H) {
      cols = defaultCols;
      childAspect = _defaultAspect;
    } else {
      final params = _computeGrid(W, H, cardData.length);
      cols = params.cols;
      childAspect = params.childAspect;
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Level ${level} – Match the Fruits'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        key: stackKey,
        children: [
          // Full-screen game background
          Positioned.fill(
            child: Image.asset(
              'assets/images/game_background.png',
              fit: BoxFit.cover,
            ),
          ),

          // Grid of cards
          Padding(
            padding: const EdgeInsets.all(8),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                childAspectRatio: childAspect,
                crossAxisSpacing: _spacing,
                mainAxisSpacing: _spacing,
              ),
              itemCount: cardData.length,
              itemBuilder: (_, i) => _buildCard(i),
            ),
          ),

          // Connecting line
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

class GridParams {
  final int cols, rows;
  final double childAspect;
  GridParams(this.cols, this.rows, this.childAspect);
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
