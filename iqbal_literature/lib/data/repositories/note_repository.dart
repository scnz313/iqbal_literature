import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/notes/word_note.dart';
import 'dart:async';

class NoteRepository {
  static const String _notesBoxName = 'word_notes';
  static const String _poemNotesPrefix = 'poem_notes_';

  // Singleton instance
  static final NoteRepository _instance = NoteRepository._internal();

  // Factory constructor
  factory NoteRepository() {
    return _instance;
  }

  // Private constructor
  NoteRepository._internal();

  late Box<WordNote> _box;
  bool _isInitializing = false;
  final Completer<void> _initializationCompleter = Completer<void>();

  // Initialize Hive box for notes
  Future<void> _initializeBox() async {
    try {
      // First check if box is already open
      if (Hive.isBoxOpen('word_notes')) {
        _box = Hive.box<WordNote>('word_notes');
        debugPrint('✅ Using already open box');
        return;
      }

      // If already initializing, wait for completion
      if (_isInitializing) {
        debugPrint('⏳ Box initialization already in progress, waiting...');
        await _initializationCompleter.future;
        return;
      }

      _isInitializing = true;
      debugPrint('🔄 Initializing word_notes box');

      try {
        _box = await Hive.openBox<WordNote>('word_notes');
        debugPrint('✅ Box opened successfully');
      } catch (e) {
        debugPrint('⚠️ Error opening box: $e');
        if (e.toString().contains('already open')) {
          debugPrint('🔄 Attempting to get already open box directly');
          try {
            _box = Hive.box<WordNote>('word_notes');
            debugPrint('✅ Successfully got already open box');
          } catch (innerError) {
            debugPrint('❌ Failed to get already open box: $innerError');
            // Try to close and reopen
            await Hive.close();
            _box = await Hive.openBox<WordNote>('word_notes');
          }
        } else {
          rethrow;
        }
      } finally {
        _isInitializing = false;
        if (!_initializationCompleter.isCompleted) {
          _initializationCompleter.complete();
        }
      }
    } catch (e) {
      debugPrint('❌ Critical error in box initialization: $e');
      _isInitializing = false;
      // Provide an empty box as fallback
      if (!_initializationCompleter.isCompleted) {
        _initializationCompleter.completeError(e);
      }
      rethrow;
    }
  }

  // Add this getter to safely access the box
  Future<Box<WordNote>> get _safeBox async {
    await _initializeBox();
    if (!_box.isOpen) {
      debugPrint('🔁 Box closed unexpectedly, reinitializing...');
      await _initializeBox();
    }
    return _box;
  }

  // Add a new note for a word in a poem
  Future<void> addNote({
    required int poemId,
    required String word,
    required int position,
    required String note,
    required String verse,
  }) async {
    final box = await _safeBox;
    try {
      final wordNote = WordNote(
        poemId: poemId,
        word: word,
        position: position,
        note: note,
        createdAt: DateTime.now(),
        verse: verse,
      );

      await box.add(wordNote);

      debugPrint('✅ Added note for word "$word" in poem $poemId');
    } catch (e) {
      debugPrint('❌ Error adding note: $e');
      rethrow;
    }
  }

  // Update an existing note
  Future<void> updateNote(WordNote oldNote, String newNoteText) async {
    final box = await _safeBox;
    try {
      final updatedNote = oldNote.copyWith(
        note: newNoteText,
        createdAt: DateTime.now(), // Update timestamp
      );

      await box.put(updatedNote.key, updatedNote);

      debugPrint(
          '✅ Updated note for word "${oldNote.word}" in poem ${oldNote.poemId}');
    } catch (e) {
      debugPrint('❌ Error updating note: $e');
      rethrow;
    }
  }

  // Delete a note
  Future<void> deleteNote(WordNote note) async {
    final box = await _safeBox;
    try {
      await box.delete(note.key);

      debugPrint(
          '✅ Deleted note for word "${note.word}" in poem ${note.poemId}');
    } catch (e) {
      debugPrint('❌ Error deleting note: $e');
      rethrow;
    }
  }

  // Get all notes for a specific poem
  Future<List<WordNote>> getNotesForPoem(int poemId) async {
    final box = await _safeBox;
    try {
      final notes = box.values.where((note) => note.poemId == poemId).toList();
      debugPrint('📝 Loaded ${notes.length} notes for poem $poemId');
      return notes;
    } catch (e) {
      debugPrint('❌ Error getting notes: $e');
      return [];
    }
  }

  // Get a note for a specific word in a poem
  Future<WordNote?> getNoteForWord(
      int poemId, String word, int position) async {
    final box = await _safeBox;
    try {
      final notes = await getNotesForPoem(poemId);

      for (final note in notes) {
        if (note.position == position && note.word == word) {
          debugPrint('📝 Found note for word "$word" in poem $poemId');
          return note;
        }
      }

      debugPrint(
          '⚠️ No note found for word "$word" at position $position in poem $poemId');
      return null;
    } catch (e) {
      debugPrint('❌ Error getting note for word: $e');
      return null;
    }
  }

  // Helper method to get consistent key for a poem's notes
  String _getPoemKey(int poemId) => '$_poemNotesPrefix$poemId';

  // Clear all notes (for testing/debugging)
  Future<void> clearAllNotes() async {
    final box = await _safeBox;
    if (box.isOpen) {
      await box.clear();
      debugPrint('🧹 Cleared all notes');
    }
  }
}
