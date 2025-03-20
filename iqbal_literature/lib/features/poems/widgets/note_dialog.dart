import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/notes/word_note.dart';
import '../controllers/poem_controller.dart';

class NoteDialog extends StatefulWidget {
  final int poemId;
  final String word;
  final int position;
  final String verse;

  const NoteDialog({
    super.key,
    required this.poemId,
    required this.word,
    required this.position,
    required this.verse,
  });

  @override
  State<NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<NoteDialog> {
  final _noteController = TextEditingController();
  late final PoemController _poemController;
  bool _isExistingNote = false;

  @override
  void initState() {
    super.initState();
    _poemController = Get.find<PoemController>();
    _loadExistingNote();
  }

  void _loadExistingNote() {
    final existingNote = _poemController.getNoteByPoemId(
      widget.poemId,
      widget.word,
      widget.position,
    );
    if (existingNote != null) {
      _noteController.text = existingNote.note;
      _isExistingNote = true;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 8,
      backgroundColor: theme.colorScheme.surface,
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with word
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_isExistingNote ? 'Edit' : 'Add'} Note',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        _isExistingNote ? Icons.edit_note : Icons.note_add,
                        size: 18,
                        color: theme.colorScheme.primary.withOpacity(0.7),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '"${widget.word}"',
                        style: TextStyle(
                          fontFamily: 'JameelNooriNastaleeq',
                          fontSize: 24,
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Text field
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              margin: const EdgeInsets.only(bottom: 24),
              child: TextField(
                controller: _noteController,
                maxLines: 5,
                style: theme.textTheme.bodyLarge,
                cursorColor: theme.colorScheme.primary,
                decoration: InputDecoration(
                  hintText: 'Enter your note here...',
                  hintStyle: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_isExistingNote)
                  TextButton.icon(
                    onPressed: _deleteNote,
                    icon: Icon(
                      Icons.delete_outline,
                      color: theme.colorScheme.error,
                      size: 16,
                    ),
                    label: Text(
                      'Delete',
                      style: TextStyle(
                        color: theme.colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      minimumSize: const Size(60, 36),
                    ),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    minimumSize: const Size(60, 36),
                  ),
                ),
                const SizedBox(width: 4),
                ElevatedButton(
                  onPressed: _saveNote,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    minimumSize: const Size(60, 36),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.save, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Save',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _saveNote() {
    if (_noteController.text.trim().isNotEmpty) {
      final note = WordNote(
        poemId: widget.poemId,
        word: widget.word,
        position: widget.position,
        note: _noteController.text.trim(),
        createdAt: DateTime.now(),
        verse: widget.verse,
      );
      _poemController.saveNote(note);
      Navigator.pop(context);
    }
  }

  void _deleteNote() {
    final existingNote = _poemController.getNoteByPoemId(
      widget.poemId,
      widget.word,
      widget.position,
    );
    if (existingNote != null) {
      _poemController.deleteWordNote(existingNote);
      Navigator.pop(context);
    }
  }
}
