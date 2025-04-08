import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../../data/models/daily_verse/daily_verse.dart';
import '../../../services/api/gemini_api.dart';
import '../../../data/repositories/book_repository.dart';
import '../../../data/repositories/poem_repository.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:math';

class DailyVerseController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final BookRepository _bookRepository = Get.find<BookRepository>();
  final PoemRepository _poemRepository = Get.find<PoemRepository>();
  
  final Rx<DailyVerse?> currentVerse = Rx<DailyVerse?>(null);
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxBool isGeneratingInsights = false.obs;
  final RxBool isUsingLocalData = false.obs;
  final RxString generationSource = "".obs;

  @override
  void onInit() {
    super.onInit();
    loadDailyVerse();
  }

  Future<void> loadDailyVerse() async {
    try {
      isLoading.value = true;
      error.value = '';

      // Check if we already have today's verse in cache
      final verse = await _getLocalDailyVerse();
      if (verse != null) {
        currentVerse.value = verse;
        isUsingLocalData.value = true;
        debugPrint('📝 Using cached daily verse');
        
        // Try to generate insights if missing, but don't block the UI
        if (verse.aiInsights == null) {
          generateInsights();
        }
        return;
      }

      // Try to get verse from Firestore first (online mode)
      try {
        final today = DateTime.now();
        final startOfDay = DateTime(today.year, today.month, today.day);
        
        // Query for today's verse
        final querySnapshot = await _firestore
            .collection('daily_verses')
            .where('date', isGreaterThanOrEqualTo: startOfDay)
            .where('date', isLessThan: startOfDay.add(const Duration(days: 1)))
            .limit(1)
            .get();
            
        if (querySnapshot.docs.isNotEmpty) {
          currentVerse.value = DailyVerse.fromFirestore(querySnapshot.docs.first);
          // Save to local storage for offline access
          await _saveDailyVerseLocally(currentVerse.value!);
          
          // Generate AI insights if not already present
          if (currentVerse.value?.aiInsights == null) {
            generateInsights();
          }
          return;
        }
      } catch (e) {
        debugPrint('Cloud fetch error, will try local generation: $e');
      }

      // If no verse from Firestore, generate one from local poems
      await generateVerseFromLocalPoems();
      
    } catch (e) {
      error.value = 'Failed to load daily verse';
      debugPrint('Error loading daily verse: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> generateVerseFromLocalPoems() async {
    try {
      isLoading.value = true;
      isGeneratingInsights.value = true;
      generationSource.value = "Generating from local poems...";
      
      // Get all poems from local database
      final poems = await _poemRepository.getAllPoems();
      final books = await _bookRepository.getAllBooks();
      
      if (poems.isEmpty) {
        throw Exception('No poems available in local storage');
      }
      
      // Select a random poem for source material
      final random = Random();
      final randomPoem = poems[random.nextInt(poems.length)];
      
      // Find book info
      final book = books.firstWhere(
        (book) => book.id == randomPoem.bookId,
        orElse: () => books.first,
      );
      
      // Extract a meaningful verse from the poem using Gemini API
      final poemText = randomPoem.cleanData;
      final prompt = '''
Using this poem from Iqbal's works, extract a single profound verse (just 2-3 lines) that would make a good "daily wisdom" quote.
Choose lines that are meaningful on their own, can inspire someone, and contain a complete thought.

POEM:
$poemText

Create a response in this exact format:
VERSE:
[The selected 2-3 lines from the poem, in the original language]

TRANSLATION:
[English translation of the verse that captures its meaning accurately]

CONTEXT:
[Brief context about what these lines mean within the poem, 1-2 sentences]

THEME:
[Single word or short phrase that captures the main theme]
''';

      final response = await GeminiAPI.generateContent(
        prompt: prompt,
        temperature: 0.7,
        maxTokens: 1000,
      );
      
      // Parse the response
      final sections = _parseFormattedResponse(response);
      
      if (!sections.containsKey('VERSE') || !sections.containsKey('TRANSLATION')) {
        throw Exception('Failed to extract verse properly from Gemini response');
      }
      
      // Create a new daily verse from the extracted content
      final now = DateTime.now();
      final newVerse = DailyVerse(
        id: 'local_${DateFormat('yyyy_MM_dd').format(now)}',
        originalText: sections['VERSE'] ?? '',
        translation: sections['TRANSLATION'] ?? '',
        context: sections['CONTEXT'] ?? 'From ${randomPoem.title}',
        bookSource: book.name,
        date: now,
        theme: sections['THEME'] ?? 'Wisdom',
        isUrdu: true,
        aiInsights: null,
      );
      
      currentVerse.value = newVerse;
      generationSource.value = "Generated from ${randomPoem.title}";
      
      // Save to local storage
      await _saveDailyVerseLocally(newVerse);
      
      // Generate detailed insights
      generateInsights();
    } catch (e) {
      error.value = 'Failed to generate verse from local poems';
      debugPrint('Error generating verse from local poems: $e');
      
      // Fall back to random verse from Firestore
      await loadRandomVerse();
    } finally {
      isLoading.value = false;
      isGeneratingInsights.value = false;
    }
  }

  Map<String, String> _parseFormattedResponse(String response) {
    final result = <String, String>{};
    final regex = RegExp(r'(\w+):\s*([\s\S]*?)(?=\n\w+:|$)');
    final matches = regex.allMatches(response);
    
    for (final match in matches) {
      if (match.groupCount >= 2) {
        final key = match.group(1)?.trim();
        final value = match.group(2)?.trim();
        if (key != null && value != null && key.isNotEmpty && value.isNotEmpty) {
          result[key] = value;
        }
      }
    }
    
    return result;
  }

  Future<void> loadRandomVerse() async {
    try {
      isLoading.value = true;
      error.value = '';
      
      // Try online mode first
      try {
        final querySnapshot = await _firestore.collection('daily_verses').get();
        if (querySnapshot.docs.isNotEmpty) {
          final randomIndex = DateTime.now().millisecondsSinceEpoch % querySnapshot.docs.length;
          currentVerse.value = DailyVerse.fromFirestore(
            querySnapshot.docs[randomIndex],
          );
          // Save to local storage
          await _saveDailyVerseLocally(currentVerse.value!);
          return;
        }
      } catch (e) {
        debugPrint('Failed to load random verse from cloud: $e');
      }
      
      // If online fails, try to get a random verse from local storage
      await generateVerseFromLocalPoems();
      
    } catch (e) {
      error.value = 'Failed to load verse';
      debugPrint('Error loading verse: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> generateInsights() async {
    if (currentVerse.value == null) return;
    
    try {
      isGeneratingInsights.value = true;
      error.value = '';
      
      final verse = currentVerse.value!;
      
      // Create a prompt for verse analysis
      final prompt = '''
Analyze this verse from Allama Iqbal's literature and provide insights:

Original Text: ${verse.originalText}
Translation: ${verse.translation}
Source: ${verse.bookSource}
Theme: ${verse.theme}

Please provide:
1. A brief explanation of the verse's meaning (2-3 sentences)
2. Key themes and philosophical concepts (2-3 bullet points)
3. Historical or cultural context if relevant (2-3 sentences)
4. Practical wisdom or life lessons from this verse (2-3 sentences)

Format your response with these exact numbered sections.
''';

      // Generate insights using Gemini API
      final response = await GeminiAPI.generateContent(
        prompt: prompt,
        temperature: 0.7,
        maxTokens: 1000,
      );
      
      // Parse the response into structured insights
      final insights = _parseNumberedResponse(response);
      
      // Update the verse with new insights
      currentVerse.value = verse.copyWith(aiInsights: insights);
      
      // Update in local storage
      await _saveDailyVerseLocally(currentVerse.value!);
      
      // Try to update in Firestore if not a local verse
      if (!verse.id.startsWith('local_')) {
        try {
          await _firestore
              .collection('daily_verses')
              .doc(verse.id)
              .update({'aiInsights': insights});
        } catch (e) {
          debugPrint('Failed to update insights in Firestore: $e');
        }
      }
    } catch (e) {
      error.value = 'Failed to generate insights';
      debugPrint('Error generating insights: $e');
    } finally {
      isGeneratingInsights.value = false;
    }
  }

  Map<String, String> _parseNumberedResponse(String response) {
    final insights = <String, String>{};
    
    final sections = response.split('\n\n');
    for (final section in sections) {
      if (section.startsWith('1.')) {
        insights['explanation'] = section.substring(2).trim();
      } else if (section.startsWith('2.')) {
        insights['themes'] = section.substring(2).trim();
      } else if (section.startsWith('3.')) {
        insights['context'] = section.substring(2).trim();
      } else if (section.startsWith('4.')) {
        insights['wisdom'] = section.substring(2).trim();
      }
    }
    
    return insights;
  }

  Future<DailyVerse?> _getLocalDailyVerse() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateFormat('yyyy_MM_dd').format(DateTime.now());
      
      // Check if we have today's verse
      if (!prefs.containsKey('daily_verse_date') || 
          prefs.getString('daily_verse_date') != today) {
        return null;
      }
      
      // Get verse data
      final id = prefs.getString('daily_verse_id') ?? '';
      final originalText = prefs.getString('daily_verse_original_text') ?? '';
      final translation = prefs.getString('daily_verse_translation') ?? '';
      final context = prefs.getString('daily_verse_context') ?? '';
      final bookSource = prefs.getString('daily_verse_book_source') ?? '';
      final theme = prefs.getString('daily_verse_theme') ?? '';
      final isUrdu = prefs.getBool('daily_verse_is_urdu') ?? true;
      
      // Get insights if available
      Map<String, String>? aiInsights;
      if (prefs.containsKey('daily_verse_insights_explanation')) {
        aiInsights = {
          'explanation': prefs.getString('daily_verse_insights_explanation') ?? '',
          'themes': prefs.getString('daily_verse_insights_themes') ?? '',
          'context': prefs.getString('daily_verse_insights_context') ?? '',
          'wisdom': prefs.getString('daily_verse_insights_wisdom') ?? '',
        };
      }
      
      return DailyVerse(
        id: id,
        originalText: originalText,
        translation: translation,
        context: context,
        bookSource: bookSource,
        date: DateTime.now(), // Use today's date
        theme: theme,
        isUrdu: isUrdu,
        aiInsights: aiInsights,
      );
    } catch (e) {
      debugPrint('Error getting local daily verse: $e');
      return null;
    }
  }

  Future<void> _saveDailyVerseLocally(DailyVerse verse) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateFormat('yyyy_MM_dd').format(DateTime.now());
      
      // Save verse date
      await prefs.setString('daily_verse_date', today);
      
      // Save verse data
      await prefs.setString('daily_verse_id', verse.id);
      await prefs.setString('daily_verse_original_text', verse.originalText);
      await prefs.setString('daily_verse_translation', verse.translation);
      await prefs.setString('daily_verse_context', verse.context);
      await prefs.setString('daily_verse_book_source', verse.bookSource);
      await prefs.setString('daily_verse_theme', verse.theme);
      await prefs.setBool('daily_verse_is_urdu', verse.isUrdu);
      
      // Save insights if available
      if (verse.aiInsights != null) {
        await prefs.setString(
          'daily_verse_insights_explanation',
          verse.aiInsights?['explanation'] ?? '',
        );
        await prefs.setString(
          'daily_verse_insights_themes',
          verse.aiInsights?['themes'] ?? '',
        );
        await prefs.setString(
          'daily_verse_insights_context',
          verse.aiInsights?['context'] ?? '',
        );
        await prefs.setString(
          'daily_verse_insights_wisdom',
          verse.aiInsights?['wisdom'] ?? '',
        );
      }
    } catch (e) {
      debugPrint('Error saving daily verse locally: $e');
    }
  }

  void shareVerse() {
    if (currentVerse.value != null) {
      final verse = currentVerse.value!;
      final shareText = '''
${verse.originalText}
${verse.translation}
From: ${verse.bookSource}
Theme: ${verse.theme}
${verse.aiInsights?['explanation'] ?? ''}
''';
      // Implement sharing functionality
      // You can use the share_plus package or platform-specific sharing
    }
  }
  
  Future<void> refreshVerse() async {
    await generateVerseFromLocalPoems();
  }
}
