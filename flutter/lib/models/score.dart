class ChordMark {
  final String chord;
  final int position;

  ChordMark({required this.chord, required this.position});

  factory ChordMark.fromMap(Map<String, dynamic> map) {
    return ChordMark(
      chord: map['chord'] as String,
      position: map['position'] as int,
    );
  }
}

class Score {
  final String id;
  final String title;
  final String artist;
  final String lyrics;
  final List<ChordMark> chords;
  final bool free;
  final String? productId;
  final double price;
  final String? originalKey;

  Score({
    required this.id,
    required this.title,
    required this.artist,
    required this.lyrics,
    required this.chords,
    this.free = true,
    this.productId,
    this.price = 0,
    this.originalKey,
  });

  static double _parsePrice(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  factory Score.fromFirestore(String id, Map<String, dynamic> data) {
    final chordList = (data['chords'] as List<dynamic>?)
            ?.map((e) => ChordMark.fromMap(e as Map<String, dynamic>))
            .toList() ??
        [];
    return Score(
      id: id,
      title: data['title'] as String? ?? '',
      artist: data['artist'] as String? ?? '',
      lyrics: data['lyrics'] as String? ?? '',
      chords: chordList,
      free: data['free'] as bool? ?? true,
      productId: data['productId'] as String?,
      price: _parsePrice(data['price']),
      originalKey: data['originalKey'] as String?,
    );
  }
}
