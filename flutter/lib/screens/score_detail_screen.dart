import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/score.dart';
import '../models/music_theory.dart';

const _allKeys = [
  'C', 'C#', 'D', 'Eb', 'E', 'F',
  'F#', 'G', 'Ab', 'A', 'Bb', 'B',
];

class ScoreDetailScreen extends StatefulWidget {
  final Score score;

  const ScoreDetailScreen({super.key, required this.score});

  @override
  State<ScoreDetailScreen> createState() => _ScoreDetailScreenState();
}

class _ScoreDetailScreenState extends State<ScoreDetailScreen> {
  late String? _selectedKey;
  late int _semitones;

  @override
  void initState() {
    super.initState();
    _selectedKey = widget.score.originalKey;
    _semitones = 0;
  }

  void _onKeyChanged(String? newKey) {
    if (newKey == null || widget.score.originalKey == null) return;
    setState(() {
      _selectedKey = newKey;
      _semitones = (noteValue(newKey) - noteValue(widget.score.originalKey!)) % 12;
    });
  }

  String _transpose(String chord) {
    if (_semitones == 0 || _selectedKey == null) return chord;
    return transposeChord(chord, _semitones, _selectedKey!);
  }

  @override
  Widget build(BuildContext context) {
    final lines = _buildScoreLines();

    return Scaffold(
      appBar: AppBar(title: Text(widget.score.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: IntrinsicWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.score.artist,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.textDim)),
                if (widget.score.originalKey != null) ...[
                  const SizedBox(height: 16),
                  _buildKeySelector(),
                ],
                const SizedBox(height: 24),
                ...lines.map((line) => _buildLine(line)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeySelector() {
    return Row(
      children: [
        Text('Tom: ',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textDim)),
        DropdownButton<String>(
          value: _selectedKey,
          dropdownColor: AppColors.surface,
          style: const TextStyle(
            color: AppColors.accent,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          underline: Container(height: 1, color: AppColors.accent),
          items: _allKeys
              .map((k) => DropdownMenuItem(value: k, child: Text(k)))
              .toList(),
          onChanged: _onKeyChanged,
        ),
      ],
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
    final score = widget.score;
    final lines = score.lyrics.split('\n');
    final chordsByLine = <int, List<ChordMark>>{};

    int globalPos = 0;
    for (int i = 0; i < lines.length; i++) {
      final lineStart = globalPos;
      final lineEnd = globalPos + lines[i].length;
      final lineChords = score.chords
          .where((c) => c.position >= lineStart && c.position < lineEnd)
          .map((c) => ChordMark(chord: _transpose(c.chord), position: c.position - lineStart))
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
