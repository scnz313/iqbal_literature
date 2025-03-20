import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/notes/word_note.dart';

class WordNoteRepository {
  static const String _notesBoxName = 'word_notes';
  late Box<WordNote> _notesBox;
  bool _isInitialized = false;

  Future<void> _initializeBox() async {
    if (!_isInitialized) {
      // Check if the box is already open
      if (Hive.isBoxOpen(_notesBoxName)) {
        _notesBox = Hive.box<WordNote>(_notesBoxName);
        _isInitialized = true;
        debugPrint('📝 Word note repository: using already open box');
        return;
      }

      try {
        _notesBox = await Hive.openBox<WordNote>(_notesBoxName);
        _isInitialized = true;
        debugPrint('📝 Word note repository: initialized successfully');
      } catch (e) {
        debugPrint('❌ Error initializing word note repository: $e');
        // If box is locked, close and try again (potential recovery)
        if (e.toString().contains('lockfile')) {
          await Hive.deleteBoxFromDisk(_notesBoxName);
          _notesBox = await Hive.openBox<WordNote>(_notesBoxName);
          _isInitialized = true;
          debugPrint('📝 Word note repository: recovered from lock error');
        } else {
          rethrow;
        }
      }
    }
  }

  // ... rest of the existing code ...
}
