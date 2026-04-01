import 'package:equatable/equatable.dart';

class ReadingProgressModel extends Equatable {
  final String userId;
  final String bookAbbrev;
  final int lastChapterRead;
  final int lastVerseRead;
  final DateTime lastReadAt;

  /// Value from 0.0 to 1.0.
  final double completionPercent;

  const ReadingProgressModel({
    required this.userId,
    required this.bookAbbrev,
    required this.lastChapterRead,
    required this.lastVerseRead,
    required this.lastReadAt,
    required this.completionPercent,
  });

  factory ReadingProgressModel.fromJson(Map<String, dynamic> json) {
    return ReadingProgressModel(
      userId: json['user_id'] as String,
      bookAbbrev: json['book_abbrev'] as String,
      lastChapterRead: json['last_chapter_read'] as int,
      lastVerseRead: json['last_verse_read'] as int,
      lastReadAt: DateTime.parse(json['last_read_at'] as String),
      completionPercent:
          (json['completion_percent'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'book_abbrev': bookAbbrev,
      'last_chapter_read': lastChapterRead,
      'last_verse_read': lastVerseRead,
      'last_read_at': lastReadAt.toIso8601String(),
      'completion_percent': completionPercent,
    };
  }

  ReadingProgressModel copyWith({
    String? userId,
    String? bookAbbrev,
    int? lastChapterRead,
    int? lastVerseRead,
    DateTime? lastReadAt,
    double? completionPercent,
  }) {
    return ReadingProgressModel(
      userId: userId ?? this.userId,
      bookAbbrev: bookAbbrev ?? this.bookAbbrev,
      lastChapterRead: lastChapterRead ?? this.lastChapterRead,
      lastVerseRead: lastVerseRead ?? this.lastVerseRead,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      completionPercent: completionPercent ?? this.completionPercent,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        bookAbbrev,
        lastChapterRead,
        lastVerseRead,
        lastReadAt,
        completionPercent,
      ];
}
