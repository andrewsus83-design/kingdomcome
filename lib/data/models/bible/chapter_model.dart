import 'package:equatable/equatable.dart';
import 'verse_model.dart';

class ChapterModel extends Equatable {
  final String bookAbbrev;
  final String bookName;
  final int chapterNumber;
  final List<VerseModel> verses;

  const ChapterModel({
    required this.bookAbbrev,
    required this.bookName,
    required this.chapterNumber,
    required this.verses,
  });

  int get verseCount => verses.length;

  VerseModel? verseAt(int verseNumber) {
    try {
      return verses.firstWhere((v) => v.verseNumber == verseNumber);
    } catch (_) {
      return null;
    }
  }

  /// Formatted citation, e.g. "Genesis 1".
  String get citation => '$bookName $chapterNumber';

  factory ChapterModel.fromJson(Map<String, dynamic> json) {
    return ChapterModel(
      bookAbbrev: json['book_abbrev'] as String,
      bookName: json['book_name'] as String,
      chapterNumber: json['chapter_number'] as int,
      verses: (json['verses'] as List<dynamic>)
          .map((v) => VerseModel.fromJson(v as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'book_abbrev': bookAbbrev,
      'book_name': bookName,
      'chapter_number': chapterNumber,
      'verses': verses.map((v) => v.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [bookAbbrev, bookName, chapterNumber, verses];
}
