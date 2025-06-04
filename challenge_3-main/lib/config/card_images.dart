// lib/config/card_images.dart

class CardImages {
  /// Path to the “back of card” image asset
  static String cardBack = 'assets/images/card_back.png';

  /// All available fruit/front images
  /// – Make sure you update your pubspec.yaml with these under `assets:`
  static List<String> fruitFronts = [
    'assets/images/fruits/apple.png',
    'assets/images/fruits/banana.png',
    'assets/images/fruits/grapes.png',
    'assets/images/fruits/strawberry.png',
    'assets/images/fruits/watermelon.png',
    'assets/images/fruits/cherry.png',
    'assets/images/fruits/pineapple.png',
    'assets/images/fruits/mango.png',
    'assets/images/fruits/kiwi.png',
    'assets/images/fruits/peach.png',
    'assets/images/fruits/lemon.png',
    'assets/images/fruits/melon.png',
    'assets/images/fruits/green_apple.png',
    'assets/images/fruits/orange.png',
    'assets/images/fruits/pear.png',
  ];

  /// Call this to pick N random fruits (for levels 1–3)
  static List<String> pickRandom(int count) {
    final copy = List<String>.from(fruitFronts)..shuffle();
    return copy.take(count).toList();
  }
}
