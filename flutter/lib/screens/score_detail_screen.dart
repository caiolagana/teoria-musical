import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/score.dart';

class ScoreDetailScreen extends StatelessWidget {
  final Score score;

  const ScoreDetailScreen({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    final lines = _buildScoreLines();

    return Scaffold(
      appBar: AppBar(title: Text(score.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(score.artist,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textDim)),
            const SizedBox(height: 24),
            ...lines.map((line) => _buildLine(line)),
          ],
        ),
      ),
    );
  }

  Widget _buildLine(_ScoreLine line) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (line.chordLine.isNotEmpty)
            Text(
              line.chordLine,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.accent,
                height: 1.2,
              ),
            ),
          Text(
            line.lyricLine,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
              color: AppColors.text,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  List<_ScoreLine> _buildScoreLines() {
    final lines = score.lyrics.split('\n');
    final chordsByLine = <int, List<ChordMark>>{};

    int globalPos = 0;
    for (int i = 0; i < lines.length; i++) {
      final lineStart = globalPos;
      final lineEnd = globalPos + lines[i].length;
      final lineChords = score.chords
          .where((c) => c.position >= lineStart && c.position < lineEnd)
          .map((c) => ChordMark(chord: c.chord, position: c.position - lineStart))
          .toList();
      if (lineChords.isNotEmpty) {
        chordsByLine[i] = lineChords;
      }
      globalPos = lineEnd + 1;
    }

    return List.generate(lines.length, (i) {
      final lineChords = chordsByLine[i] ?? [];
      var chordLine = '';
      if (lineChords.isNotEmpty) {
        final chars = List.filled(lines[i].length, ' ');
        for (final cm in lineChords) {
          for (int j = 0; j < cm.chord.length && cm.position + j < chars.length; j++) {
            chars[cm.position + j] = cm.chord[j];
          }
        }
        chordLine = chars.join().trimRight();
      }
      return _ScoreLine(chordLine: chordLine, lyricLine: lines[i]);
    });
  }
}

class _ScoreLine {
  final String chordLine;
  final String lyricLine;

  _ScoreLine({required this.chordLine, required this.lyricLine});
}
