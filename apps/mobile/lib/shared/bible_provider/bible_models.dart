/// Typed models that mirror the FastAPI /bible/* response shapes.

class Translation {
  const Translation({
    required this.code,
    required this.name,
    required this.language,
    required this.license,
    required this.source,
  });

  final String code;
  final String name;
  final String language;
  final String license;
  final String source;

  factory Translation.fromJson(Map<String, dynamic> j) => Translation(
        code: j['code'] as String,
        name: j['name'] as String,
        language: j['language'] as String? ?? 'en',
        license: j['license'] as String? ?? '',
        source: j['source'] as String? ?? '',
      );
}

class Book {
  const Book({
    required this.osisCode,
    required this.name,
    required this.order,
    required this.chapterCount,
    required this.chapterNumbers,
  });

  final String osisCode;
  final String name;
  final int order;
  final int chapterCount;

  /// Chapter numbers actually present in this translation (sorted asc).
  /// Sample data may have only chapter 3 of John — clients should navigate
  /// to the first entry here, not assume chapter 1 exists.
  final List<int> chapterNumbers;

  /// The first chapter that exists, or 1 if the field is missing (older API).
  int get firstChapter =>
      chapterNumbers.isNotEmpty ? chapterNumbers.first : 1;

  /// All chapter numbers a client can navigate to. Prefers the explicit
  /// `chapterNumbers` list (handles partial seed data); falls back to
  /// `1..chapterCount` when the backend doesn't return it.
  List<int> get chaptersAvailable => chapterNumbers.isNotEmpty
      ? chapterNumbers
      : [for (var i = 1; i <= chapterCount; i++) i];

  factory Book.fromJson(Map<String, dynamic> j) => Book(
        osisCode: j['osis_code'] as String,
        name: j['name'] as String,
        order: (j['order'] as num).toInt(),
        chapterCount: (j['chapter_count'] as num).toInt(),
        chapterNumbers: ((j['chapter_numbers'] as List?) ?? const [])
            .map((n) => (n as num).toInt())
            .toList(),
      );
}

/// Books grouped by testament (Old / New).
class BookList {
  const BookList({
    required this.translation,
    required this.oldTestament,
    required this.newTestament,
  });

  final String translation;
  final List<Book> oldTestament;
  final List<Book> newTestament;

  /// Both testaments concatenated in canonical order.
  List<Book> get allBooks => [...oldTestament, ...newTestament];

  /// Lookup by OSIS code; returns null if not present in this translation.
  Book? findByOsis(String osisCode) {
    for (final b in allBooks) {
      if (b.osisCode == osisCode) return b;
    }
    return null;
  }

  factory BookList.fromJson(Map<String, dynamic> j) {
    final t = (j['testaments'] as Map).cast<String, dynamic>();
    List<Book> read(String key) => ((t[key] as List?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map(Book.fromJson)
        .toList();
    return BookList(
      translation: j['translation'] as String,
      oldTestament: read('OT'),
      newTestament: read('NT'),
    );
  }
}

class Verse {
  const Verse({required this.number, required this.text});
  final int number;
  final String text;

  factory Verse.fromJson(Map<String, dynamic> j) => Verse(
        number: (j['number'] as num).toInt(),
        text: j['text'] as String,
      );
}

class Chapter {
  const Chapter({
    required this.translation,
    required this.bookCode,
    required this.bookName,
    required this.chapter,
    required this.verses,
  });

  final String translation;
  final String bookCode;
  final String bookName;
  final int chapter;
  final List<Verse> verses;

  factory Chapter.fromJson(Map<String, dynamic> j) => Chapter(
        translation: j['translation'] as String,
        bookCode: j['book'] as String,
        bookName: j['book_name'] as String? ?? j['book'] as String,
        chapter: (j['chapter'] as num).toInt(),
        verses: (j['verses'] as List)
            .cast<Map<String, dynamic>>()
            .map(Verse.fromJson)
            .toList(),
      );
}

class SearchHit {
  const SearchHit({
    required this.reference,
    required this.translation,
    required this.book,
    required this.chapter,
    required this.verse,
    required this.text,
    this.rank,
  });

  final String reference;
  final String translation;
  final String book;
  final int chapter;
  final int verse;
  final String text;
  final double? rank;

  factory SearchHit.fromJson(Map<String, dynamic> j) => SearchHit(
        reference: j['reference'] as String,
        translation: j['translation'] as String,
        book: j['book'] as String,
        chapter: (j['chapter'] as num).toInt(),
        verse: (j['verse'] as num).toInt(),
        text: j['text'] as String,
        rank: (j['rank'] as num?)?.toDouble(),
      );
}
