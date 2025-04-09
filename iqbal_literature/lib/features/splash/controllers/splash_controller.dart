import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../config/routes/app_routes.dart';
import '../../../data/repositories/poem_repository.dart';
import '../../../features/poems/models/poem.dart';

class SplashController extends GetxController {
  final PoemRepository _poemRepository;

  // Observable variables
  final RxString quoteText = ''.obs;
  final RxString quoteTranslation = ''.obs;
  final RxBool isQuoteLoaded = false.obs;
  final RxDouble loadingProgress = 0.0.obs;
  final RxBool contentVisible = false.obs;
  final RxBool isUrduQuote = false.obs;
  final RxBool isAnimationComplete = false.obs;
  final RxBool isReadyToNavigate = false.obs;

  // For randomizing quotes
  final Random _random = Random();

  // Timer for managing the splash screen duration
  Timer? _splashTimer;
  Timer? _progressTimer;

  // Minimum display time to ensure logo doesn't display too long
  static const minimumLogoTime = Duration(milliseconds: 500);

  // Base duration plus per-character time
  static const baseSplashDuration = Duration(milliseconds: 800);
  static const perCharacterTime = 30; // milliseconds per character

  // Min time to display completed quote
  static const minReadTime = Duration(milliseconds: 2500);

  // Computed splash duration
  late Duration _calculatedSplashDuration;

  // List of themes to filter quotes by
  final List<String> _themes = [
    'knowledge',
    'education',
    'learning',
    'muslim',
    'islam',
    'unity',
    'power',
    'strength',
    'leadership',
    'influence',
    'world',
    'global',
  ];

  // Urdu character range
  static final RegExp _urduRegex = RegExp(r'[\u0600-\u06FF]');

  SplashController({required PoemRepository poemRepository})
      : _poemRepository = poemRepository;

  @override
  void onInit() {
    super.onInit();
    _setupSplashScreen();
  }

  @override
  void onClose() {
    _splashTimer?.cancel();
    _progressTimer?.cancel();
    super.onClose();
  }

  void _setupSplashScreen() {
    // Set content visible immediately
    contentVisible.value = true;

    // Load quote immediately without waiting
    _loadRandomQuote();

    // Start with minimum logo time (just as a fallback)
    _startMinimumLogoTimer();
  }

  // Make sure we don't show the logo longer than necessary
  void _startMinimumLogoTimer() {
    Timer(minimumLogoTime, () {
      // If quote is already loaded, this won't affect anything
      // If quote is still loading, this ensures we show progress
      if (!isQuoteLoaded.value) {
        isQuoteLoaded.value = true;
        quoteText.value = "Loading wisdom...";
      }
    });
  }

  void _startProgressAnimation() {
    const interval = Duration(milliseconds: 50);

    _progressTimer = Timer.periodic(interval, (timer) {
      final totalDuration = _calculatedSplashDuration.inMilliseconds;
      loadingProgress.value += 1 / (totalDuration / interval.inMilliseconds);

      if (loadingProgress.value >= 1.0) {
        timer.cancel();
        loadingProgress.value = 1.0;

        // Wait the minimum read time after animation completes
        Timer(minReadTime, () {
          isReadyToNavigate.value = true;
          _navigateToHome();
        });
      }
    });
  }

  void onAnimationComplete() {
    isAnimationComplete.value = true;
    // If progress is already complete, navigate
    if (loadingProgress.value >= 1.0) {
      Timer(minReadTime, () {
        isReadyToNavigate.value = true;
        _navigateToHome();
      });
    }
  }

  void skipAndNavigate() {
    isReadyToNavigate.value = true;
    _navigateToHome();
  }

  void _navigateToHome() {
    if (isReadyToNavigate.value) {
      // Cancel any pending timers
      _splashTimer?.cancel();
      _progressTimer?.cancel();

      // Navigate to home
      Get.offAllNamed(Routes.home);
    }
  }

  // Check if text contains Urdu characters
  bool _isUrduText(String text) {
    return _urduRegex.hasMatch(text);
  }

  Future<void> _loadRandomQuote() async {
    try {
      // Get all poems
      final poems = await _getAllPoems();

      if (poems.isEmpty) {
        // Fallback if no poems are found
        final fallbackQuote =
            "Khudi ko kar buland itna, ke har taqdeer se pehle; Khuda bande se khud pooche, bata teri raza kya hai.";
        quoteText.value = fallbackQuote;
        isUrduQuote.value = _isUrduText(fallbackQuote);

        // Add translation for fallback Urdu quote
        if (isUrduQuote.value) {
          quoteTranslation.value =
              "Elevate yourself so high that God, before issuing every decree of destiny, asks you: Tell me, what is your wish?";
        }

        isQuoteLoaded.value = true;
        _calculateDuration(fallbackQuote);
        return;
      }

      // Filter poems that match our themes
      final filteredPoems = _filterPoemsByThemes(poems);

      // If no poems match our filter criteria, use any random poem
      final selectedPoems = filteredPoems.isNotEmpty ? filteredPoems : poems;

      // Select a random poem
      final randomPoem = selectedPoems[_random.nextInt(selectedPoems.length)];

      // Extract a meaningful quote from the poem
      final extractedQuote = _extractQuote(randomPoem);

      // Set the quote and check if it's Urdu
      quoteText.value = extractedQuote;
      isUrduQuote.value = _isUrduText(extractedQuote);

      // Add translation for Urdu quotes
      if (isUrduQuote.value) {
        quoteTranslation.value = _getTranslation(extractedQuote);
      } else {
        // For English quotes, we don't need a translation
        quoteTranslation.value = '';
      }

      isQuoteLoaded.value = true;

      // Calculate appropriate duration based on quote length
      _calculateDuration(extractedQuote);
    } catch (e) {
      debugPrint("Error loading random quote: $e");
      // Fallback quote in case of error
      final fallbackQuote =
          "The ultimate aim of the ego is not to see something, but to be something.";
      quoteText.value = fallbackQuote;
      isUrduQuote.value = false;
      quoteTranslation.value = '';
      isQuoteLoaded.value = true;
      _calculateDuration(fallbackQuote);
    }
  }

  void _calculateDuration(String quote) {
    // Calculate animation time based on quote length and translation length
    int characterCount = quote.length;

    // Add translation length if it exists
    if (isUrduQuote.value && quoteTranslation.value.isNotEmpty) {
      // Add translation characters but with less weight
      characterCount += (quoteTranslation.value.length * 0.5).toInt();
    }

    final animationTime = characterCount * perCharacterTime;

    // Set the total duration (base + animation time)
    _calculatedSplashDuration =
        baseSplashDuration + Duration(milliseconds: animationTime);

    // Start progress animation with calculated duration
    _startProgressAnimation();
  }

  Future<List<Poem>> _getAllPoems() async {
    try {
      final List<Poem> allPoems = [];

      // Try to get poems from books 1-5
      for (int i = 1; i <= 5; i++) {
        final bookPoems = await _poemRepository.getPoemsByBookId(i);
        allPoems.addAll(bookPoems);
      }

      return allPoems;
    } catch (e) {
      debugPrint("Error getting all poems: $e");
      return [];
    }
  }

  List<Poem> _filterPoemsByThemes(List<Poem> poems) {
    return poems.where((poem) {
      final poemText = poem.data.toLowerCase();
      return _themes.any((theme) => poemText.contains(theme.toLowerCase()));
    }).toList();
  }

  String _extractQuote(Poem poem) {
    // Split the poem into lines
    final lines = poem.cleanData.split('\n');

    // If the poem is short, use the whole poem
    if (lines.length <= 4) {
      return poem.cleanData;
    }

    // For longer poems, extract a meaningful segment (2-4 lines)
    final startIndex = _random.nextInt(lines.length - 3);
    final quoteLength = min(4, lines.length - startIndex);

    return lines.sublist(startIndex, startIndex + quoteLength).join('\n');
  }

  // Get translation for Urdu quotes
  String _getTranslation(String urduQuote) {
    // Map of known translations with more entries and simplified keys
    final Map<String, String> translations = {
      // Common Iqbal quotes with simplified keys for better matching
      "خودی":
          "Elevate yourself so high that God, before issuing every decree of destiny, asks you: Tell me, what is your wish?",
      "خواص محبت":
          "May Allah grant success to the special ones of love. Every drop is a river here, each eye is a river. In the mourning of this season, even the smallest eye weeps.",
      "ستاروں سے آگے":
          "Beyond the stars, there are more worlds. There are still more tests of love to come.",
      "تو شاہین":
          "You are a falcon, your flight is high in the skies; your way is different from that of other birds.",
      "شمع حق":
          "The candle of truth cannot be extinguished by the breath of falsehood.",
      "افرنگی":
          "The West's knowledge, the East's love - when combined, can transform the world.",
      "مسلم":
          "The Muslim, with deep conviction in the heart, has the power to transform the world.",
      "عقل و دل":
          "Heart gives depth to the intellect, and intellect gives clarity to the heart.",
      "درویش": "Poverty is not the absence of wealth, but the absence of need.",
      "اسلام": "Islam is itself a destiny, not just a message of destiny.",
      "محبت":
          "Love elevates a person to heights that even angels cannot reach.",
      "آزادی":
          "Freedom is the essence of life; without it, life is mere existence.",
      "شاعر":
          "The poet's eye sees what others cannot - the connection between heaven and earth.",
      "مومن":
          "A believer's heart contains treasures that kings cannot possess.",
      "جبریل":
          "Gabriel asks for my poetry in heaven, for it speaks truths that heaven has yet to know.",
      "روزگار":
          "In this world, recognition comes to those who make themselves necessary.",
    };

    // First try direct match (simplified)
    String simpleUrduQuote = urduQuote.replaceAll('\n', ' ').trim();

    // Check if any key is contained within the quote
    for (var key in translations.keys) {
      if (simpleUrduQuote.contains(key)) {
        return translations[key]!;
      }
    }

    // If we reach here, we couldn't find a matching translation
    // Let's add some specific translations for common fallback quotes
    if (simpleUrduQuote.contains("بلند")) {
      return "Elevate yourself so high that God, before issuing every decree of destiny, asks you: Tell me, what is your wish?";
    } else if (simpleUrduQuote.contains("محبت")) {
      return "Love is the foundation of life; it transforms both the lover and the beloved.";
    } else if (simpleUrduQuote.contains("عشق")) {
      return "Love is not just emotion; it's a transformative power that reshapes reality.";
    } else if (simpleUrduQuote.contains("حقیقت")) {
      return "Truth is not just what you see, but what exists beyond perception.";
    } else if (simpleUrduQuote.contains("خدا")) {
      return "The relationship between man and God is the ultimate reality that gives meaning to existence.";
    } else if (simpleUrduQuote.contains("دنیا")) {
      return "This world is merely a testing ground for the eternal journey of the soul.";
    }

    // Default translation messages with random selection
    final defaultMessages = [
      "This is a profound verse from Iqbal's poetry that speaks to the depth of human experience and spiritual awakening.",
      "Translation not available. Appreciate the beauty of the original verse."
    ];

    // Return a random message
    return defaultMessages[_random.nextInt(defaultMessages.length)];
  }
}
