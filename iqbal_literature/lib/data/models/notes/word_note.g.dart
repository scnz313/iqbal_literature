// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'word_note.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WordNoteAdapter extends TypeAdapter<WordNote> {
  @override
  final int typeId = 4;

  @override
  WordNote read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WordNote(
      poemId: fields[0] as int,
      word: fields[1] as String,
      position: fields[2] as int,
      note: fields[3] as String,
      createdAt: fields[4] as DateTime,
      verse: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, WordNote obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.poemId)
      ..writeByte(1)
      ..write(obj.word)
      ..writeByte(2)
      ..write(obj.position)
      ..writeByte(3)
      ..write(obj.note)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.verse);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WordNoteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
