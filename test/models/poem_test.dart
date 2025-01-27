import 'package:flutter_test/flutter_test.dart';
import 'package:iqbal_literature/data/models/poem/poem.dart';

void main() {
  group('Poem Model Tests', () {
    test('should create Poem instance with valid data', () {
      final poem = const Poem(
        id: 1,
        bookId: 1,
        data: 'Test poem data',
        title: 'Test poem',
        orderBy: 1,
      );

      expect(poem.id, 1);
      expect(poem.bookId, 1);
      expect(poem.data, 'Test poem data');
      expect(poem.title, 'Test poem');
      expect(poem.orderBy, 1);
    });

    test('should create Poem from map', () {
      final map = {
        '_id': '1',
        'book_id': '1',
        'data': 'Test poem data',
        'title': 'Test poem',
        'order_by': 1,
      };

      final poem = Poem.fromMap(map);

      expect(poem.id, 1);
      expect(poem.bookId, 1);
      expect(poem.data, 'Test poem data');
      expect(poem.title, 'Test poem');
      expect(poem.orderBy, 1);
    });

    test('should convert Poem to map', () {
      final poem = const Poem(
        id: 1,
        bookId: 1,
        data: 'Test poem data',
        title: 'Test poem',
        orderBy: 1,
      );

      final map = poem.toMap();

      expect(map['_id'], '1');
      expect(map['book_id'], '1');
      expect(map['data'], 'Test poem data');
      expect(map['title'], 'Test poem');
      expect(map['order_by'], 1);
    });

    test('should compare poems correctly', () {
      final poem1 = const Poem(
        id: 1,
        bookId: 1,
        data: 'Test poem data',
        title: 'Test poem',
        orderBy: 1,
      );

      final poem2 = const Poem(
        id: 1,
        bookId: 1,
        data: 'Different data',
        title: 'Different title',
        orderBy: 2,
      );

      expect(poem1, poem2);
      expect(poem1.hashCode, poem2.hashCode);
    });

    test('should copy with new values', () {
      final poem = const Poem(
        id: 1,
        bookId: 1,
        data: 'Test poem data',
        title: 'Test poem',
        orderBy: 1,
      );

      final copiedPoem = poem.copyWith(
        title: 'New title',
        data: 'New data',
      );

      expect(copiedPoem.id, poem.id);
      expect(copiedPoem.bookId, poem.bookId);
      expect(copiedPoem.data, 'New data');
      expect(copiedPoem.title, 'New title');
      expect(copiedPoem.orderBy, poem.orderBy);
    });

    test('Poem fromMap', () {
      final poem = const Poem(
        id: '1',
        bookId: '1',
        title: 'Test Poem',
        data: 'Test Data',
        orderBy: 1,
      );

      expect(poem.id, '1');
      expect(poem.bookId, '1');
      // ...existing test code...
    });
  });
}