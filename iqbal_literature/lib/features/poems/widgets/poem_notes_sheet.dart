import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/poem_controller.dart';
import '../../../data/models/notes/word_note.dart';
import '../../../data/repositories/note_repository.dart';
import 'note_dialog.dart';

class PoemNotesSheet extends StatefulWidget {
  final int poemId;
  final String poemTitle;

  const PoemNotesSheet({
    super.key,
    required this.poemId,
    required this.poemTitle,
  });

  @override
  State<PoemNotesSheet> createState() => _PoemNotesSheetState();
}

class _PoemNotesSheetState extends State<PoemNotesSheet> {
  late Future<List<WordNote>> _notesFuture;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  void _loadNotes() {
    try {
      // Check if NoteRepository is registered
      if (!Get.isRegistered<NoteRepository>()) {
        // Register it if not found
        Get.put(NoteRepository());
      }

      setState(() {
        _notesFuture =
            Get.find<NoteRepository>().getNotesForPoem(widget.poemId);
      });
    } catch (e) {
      debugPrint('❌ Error loading notes: $e');
      setState(() {
        _notesFuture = Future.value([]);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<WordNote>>(
      future: _notesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading notes: ${snapshot.error}'),
          );
        }

        final notes = snapshot.data ?? [];

        if (notes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.note_alt_outlined,
                  size: 48,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(height: 16),
                const Text('No notes yet'),
                const SizedBox(height: 8),
                const Text(
                  'Double-tap any word to add a note',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: notes.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final note = notes[index];
            return _buildNoteCard(context, note);
          },
        );
      },
    );
  }

  Widget _buildNoteCard(BuildContext context, WordNote note) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(
          note.word,
          style: const TextStyle(
            fontFamily: 'JameelNooriNastaleeq',
            fontSize: 18,
          ),
          textDirection: TextDirection.rtl,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(note.note),
            const SizedBox(height: 4),
            Text(
              'Verse: ${note.verse}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => NoteDialog(
                poemId: note.poemId,
                word: note.word,
                position: note.position,
                verse: note.verse,
              ),
            ).then((_) => _loadNotes());
          },
        ),
      ),
    );
  }
}
