import 'package:equatable/equatable.dart';

class VerseModel extends Equatable {
  /// Unique verse identifier in the format "ABBREV.CHAPTER.VERSE" e.g. "GEN.1.1".
  final String id;
  final String bookAbbrev;
  final String bookName;
  final int chapterNumber;
  final int verseNumber;
  final String text;
  final List<String> thematicTags;
  final bool isVerseOfDayCandidate;

  const VerseModel({
    required this.id,
    required this.bookAbbrev,
    required this.bookName,
    required this.chapterNumber,
    required this.verseNumber,
    required this.text,
    this.thematicTags = const [],
    this.isVerseOfDayCandidate = false,
  });

  /// Formatted citation, e.g. "Genesis 1:1".
  String get citation => '$bookName $chapterNumber:$verseNumber';

  factory VerseModel.fromJson(Map<String, dynamic> json) {
    return VerseModel(
      id: json['id'] as String,
      bookAbbrev: json['book_abbrev'] as String,
      bookName: json['book_name'] as String,
      chapterNumber: json['chapter_number'] as int,
      verseNumber: json['verse_number'] as int,
      text: json['text'] as String,
      thematicTags: (json['thematic_tags'] as List<dynamic>?)
              ?.map((t) => t as String)
              .toList() ??
          [],
      isVerseOfDayCandidate:
          json['is_verse_of_day_candidate'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'book_abbrev': bookAbbrev,
      'book_name': bookName,
      'chapter_number': chapterNumber,
      'verse_number': verseNumber,
      'text': text,
      'thematic_tags': thematicTags,
      'is_verse_of_day_candidate': isVerseOfDayCandidate,
    };
  }

  @override
  List<Object?> get props => [
        id,
        bookAbbrev,
        bookName,
        chapterNumber,
        verseNumber,
        text,
        thematicTags,
        isVerseOfDayCandidate,
      ];
}
