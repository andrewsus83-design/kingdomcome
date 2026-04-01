import 'package:equatable/equatable.dart';

class BookModel extends Equatable {
  /// Sequential book ID (1–73 for Catholic canon).
  final int id;
  final String abbrev;
  final String name;

  /// "OT" for Old Testament, "NT" for New Testament.
  final String testament;

  /// 1-based canonical order within the Bible.
  final int bookOrder;

  final int chapterCount;
  final String description;

  const BookModel({
    required this.id,
    required this.abbrev,
    required this.name,
    required this.testament,
    required this.bookOrder,
    required this.chapterCount,
    required this.description,
  });

  bool get isOldTestament => testament == 'OT';
  bool get isNewTestament => testament == 'NT';

  factory BookModel.fromJson(Map<String, dynamic> json) {
    return BookModel(
      id: json['id'] as int,
      abbrev: json['abbrev'] as String,
      name: json['name'] as String,
      testament: json['testament'] as String,
      bookOrder: json['book_order'] as int,
      chapterCount: json['chapter_count'] as int,
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'abbrev': abbrev,
      'name': name,
      'testament': testament,
      'book_order': bookOrder,
      'chapter_count': chapterCount,
      'description': description,
    };
  }

  @override
  List<Object?> get props =>
      [id, abbrev, name, testament, bookOrder, chapterCount, description];
}
