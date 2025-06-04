// lib/ui/game_play_screen.dart

import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:challenge3/config/grid_config.dart';
import 'package:flutter/material.dart';
import '../config/card_images.dart';

/// Manages coins for the entire session.
class CoinManager {
  static int coins = 20; // starting amount
  static const int revealCost = 5;

  /// Spend coins to reveal cards. Returns true if spent.
  static bool spendForReveal() {
    if (coins >= revealCost) {
      coins -= revealCost;
      return true;
    }
    return false;
  }
}

class GameScreen extends StatefulWidget {
  final int startingLevel;
  const GameScreen({super.key, this.startingLevel = 1});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  static const double _defaultCardW = 100;
  static const double _defaultAspect = 0.8;
  static const double _spacing = 8;

  late int level;
  final Map<int, int> fruitsPerLevel = {1: 2, 2: 6, 3: 15};

  late List<String> cardData;
  List<bool> cardFlipped = [];
  List<bool> cardMatched = [];
  List<int> selectedIndices = [];
  int matchedPairs = 0;

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
    final fruits = CardImages.pickRandom(fruitsPerLevel[level]!);
    cardData = [...fruits, ...fruits]..shuffle(Random());

    cardFlipped = List.filled(cardData.length, false);
    cardMatched = List.filled(cardData.length, false);
    selectedIndices.clear();
    matchedPairs = 0;
    lineStart = lineEnd = null;

    cardKeys.clear();
    for (var i = 0; i < cardData.length; i++) {
      cardKeys[i] = GlobalKey();
    }

    setState(() {});
  }

  void _onCardTap(int index) {
    if (cardFlipped[index] || selectedIndices.length == 2 || cardMatched[index]) {
      return;
    }

    setState(() {
      cardFlipped[index] = true;
      selectedIndices.add(index);
    });

    if (selectedIndices.length == 2) {
      Future.delayed(const Duration(milliseconds: 800), () {
        final i = selectedIndices[0], j = selectedIndices[1];
        if (cardData[i] == cardData[j]) {
          // Correct match → mark matched and increment coin
          cardMatched[i] = cardMatched[j] = true;
          matchedPairs++;

          // ADD THIS LINE to give 1 coin per correct match:
          CoinManager.coins += 1;
        } else {
          cardFlipped[i] = cardFlipped[j] = false;
        }
        selectedIndices.clear();
        setState(() {});

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

  /// Reveal all unmatched cards for [durationMs] ms, spending 5 coins.
  void _revealAllCardsTemporarily(int durationMs) {
    if (!CoinManager.spendForReveal()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough coins to reveal!')),
      );
      return;
    }

    // Flip all unmatched cards face‐up
    final toReveal = <int>[];
    for (var i = 0; i < cardData.length; i++) {
      if (!cardMatched[i] && !cardFlipped[i]) {
        toReveal.add(i);
      }
    }
    if (toReveal.isEmpty) return;

    setState(() {
      for (var idx in toReveal) {
        cardFlipped[idx] = true;
      }
    });

    Future.delayed(Duration(milliseconds: durationMs), () {
      setState(() {
        for (var idx in toReveal) {
          if (!cardMatched[idx]) {
            cardFlipped[idx] = false;
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final W = mq.size.width - 16;
    final H = mq.size.height -
        kToolbarHeight -
        mq.padding.top -
        mq.padding.bottom -
        16;

    final defaultCols = max(1, (W + _spacing) ~/ (_defaultCardW + _spacing));
    final defaultRows = (cardData.length / defaultCols).ceil();
    final totalDefaultH =
        defaultRows * (_defaultCardW / _defaultAspect) + (defaultRows - 1) * _spacing;

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
        automaticallyImplyLeading: true,
        title: Text('Level $level – Match the Fruits'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: GestureDetector(
              onTap: () {
                // Spend coins to reveal all cards for 1 second
                _revealAllCardsTemporarily(1000);
                setState(() {});
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.monetization_on, color: Colors.yellowAccent),
                      const SizedBox(width: 4),
                      Text(
                        'Coins: ${CoinManager.coins}',
                        style: const TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Click Coin to reveal fruit',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
        ],
      ),
    );
  }
}
