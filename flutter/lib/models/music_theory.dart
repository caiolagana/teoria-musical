const chromaticSharps = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
const chromaticFlats = ['C', 'Db', 'D', 'Eb', 'E', 'F', 'Gb', 'G', 'Ab', 'A', 'Bb', 'B'];

const flatKeys = {
  'F', 'Bb', 'Eb', 'Ab', 'Db', 'Gb',
  'Dm', 'Gm', 'Cm', 'Fm', 'Bbm', 'Ebm',
};

final noteToValue = <String, int>{
  for (int i = 0; i < chromaticSharps.length; i++) chromaticSharps[i]: i,
  for (int i = 0; i < chromaticFlats.length; i++) chromaticFlats[i]: i,
};

const intervals = <String, int>{
  'uníssono': 0,
  'segunda menor': 1,
  'segunda maior': 2,
  'terça menor': 3,
  'terça maior': 4,
  'quarta justa': 5,
  'quarta aumentada': 6,
  'quinta diminuta': 6,
  'quinta justa': 7,
  'quinta aumentada': 8,
  'sexta menor': 8,
  'sexta maior': 9,
  'sétima menor': 10,
  'sétima maior': 11,
  'oitava': 12,
};

const _t = 2;
const _s = 1;

const scaleFormulas = <String, List<int>>{
  'maior': [_t, _t, _s, _t, _t, _t, _s],
  'menor natural': [_t, _s, _t, _t, _s, _t, _t],
  'menor harmônica': [_t, _s, _t, _t, _s, _t + _s, _s],
  'menor melódica': [_t, _s, _t, _t, _t, _t, _s],
  'pentatônica maior': [_t, _t, _t + _s, _t, _t + _s],
  'pentatônica menor': [_t + _s, _t, _t, _t + _s, _t],
  'blues': [_t + _s, _t, _s, _s, _t + _s, _t],
  'cromática': [_s, _s, _s, _s, _s, _s, _s, _s, _s, _s, _s, _s],
  'dórica': [_t, _s, _t, _t, _t, _s, _t],
  'frígia': [_s, _t, _t, _t, _s, _t, _t],
  'lídia': [_t, _t, _t, _s, _t, _t, _s],
  'mixolídia': [_t, _t, _s, _t, _t, _s, _t],
  'lócria': [_s, _t, _t, _s, _t, _t, _t],
};

const chordFormulas = <String, List<int>>{
  'maior': [0, 4, 7],
  'menor': [0, 3, 7],
  'diminuto': [0, 3, 6],
  'aumentado': [0, 4, 8],
  'maior com sétima maior': [0, 4, 7, 11],
  'dominante (7)': [0, 4, 7, 10],
  'menor com sétima': [0, 3, 7, 10],
  'meio-diminuto': [0, 3, 6, 10],
  'diminuto com sétima': [0, 3, 6, 9],
  'sus2': [0, 2, 7],
  'sus4': [0, 5, 7],
  'maior com nona': [0, 4, 7, 11, 14],
  'dominante com nona': [0, 4, 7, 10, 14],
  'menor com nona': [0, 3, 7, 10, 14],
};

class Tuning {
  final String name;
  final String label;
  final List<String> strings;
  const Tuning({required this.name, required this.label, required this.strings});
}

const tunings = [
  Tuning(name: 'viola_caipira_rio_abaixo', label: 'Viola Caipira (Rio Abaixo)', strings: ['G', 'D', 'G', 'B', 'D']),
  Tuning(name: 'viola_caipira_cebolao_D', label: 'Viola Caipira (Cebolão em D)', strings: ['A', 'D', 'F#', 'A', 'D']),
  Tuning(name: 'viola_caipira_cebolao_E', label: 'Viola Caipira (Cebolão em E)', strings: ['E', 'B', 'G#', 'E', 'B']),
  Tuning(name: 'violao', label: 'Violão', strings: ['E', 'A', 'D', 'G', 'B', 'E']),
];

const maxFret = 14;

class NoteGroup {
  final String? natural;
  final String? sharp;
  final String? flat;
  const NoteGroup({this.natural, this.sharp, this.flat});
}

const noteGroups = [
  NoteGroup(natural: 'C'),
  NoteGroup(sharp: 'C#', flat: 'Db'),
  NoteGroup(natural: 'D'),
  NoteGroup(sharp: 'D#', flat: 'Eb'),
  NoteGroup(natural: 'E'),
  NoteGroup(natural: 'F'),
  NoteGroup(sharp: 'F#', flat: 'Gb'),
  NoteGroup(natural: 'G'),
  NoteGroup(sharp: 'G#', flat: 'Ab'),
  NoteGroup(natural: 'A'),
  NoteGroup(sharp: 'A#', flat: 'Bb'),
  NoteGroup(natural: 'B'),
];

List<String> _chromaticFor(String root) {
  if (flatKeys.contains(root) || root.contains('b')) {
    return chromaticFlats;
  }
  return chromaticSharps;
}

int noteValue(String name) => noteToValue[name]!;

String noteName(int value, [String root = 'C']) {
  return _chromaticFor(root)[((value % 12) + 12) % 12];
}

List<String> buildScale(String root, String formulaName) {
  final formula = scaleFormulas[formulaName]!;
  final chromatic = _chromaticFor(root);
  int value = noteValue(root);
  final notes = [chromatic[value % 12]];
  for (final step in formula) {
    value += step;
    notes.add(chromatic[value % 12]);
  }
  return notes;
}

List<String> buildChord(String root, String formulaName) {
  final formula = chordFormulas[formulaName]!;
  final base = noteValue(root);
  final chromatic = _chromaticFor(root);
  return formula.map((interval) => chromatic[(base + interval) % 12]).toList();
}

int intervalBetween(String note1, String note2) {
  return ((noteValue(note2) - noteValue(note1)) % 12 + 12) % 12;
}

String intervalName(int semitones) {
  semitones = ((semitones % 12) + 12) % 12;
  for (final entry in intervals.entries) {
    if (entry.value == semitones) return entry.key;
  }
  return '$semitones semitons';
}

class FretboardCell {
  final String? note;
  final bool isRoot;
  final int fret;
  const FretboardCell({this.note, this.isRoot = false, required this.fret});
}

class FretboardRow {
  final String openNote;
  final int stringNumber;
  final List<FretboardCell> cells;
  const FretboardRow({required this.openNote, required this.stringNumber, required this.cells});
}

class FretboardDiagram {
  final String tuningName;
  final String tuningLabel;
  final String root;
  final List<FretboardRow> rows;
  const FretboardDiagram({required this.tuningName, required this.tuningLabel, required this.root, required this.rows});
}

FretboardDiagram buildFretboardDiagram(Tuning tuning, List<String> scaleNotes, String root) {
  final scaleValues = scaleNotes.map(noteValue).toSet();
  final rootValue = noteValue(root);
  final chromatic = _chromaticFor(root);

  final rows = <FretboardRow>[];
  for (int i = 0; i < tuning.strings.length; i++) {
    final openNote = tuning.strings[i];
    final openVal = noteValue(openNote);
    final cells = <FretboardCell>[];
    for (int fret = 0; fret <= maxFret; fret++) {
      final val = (openVal + fret) % 12;
      if (scaleValues.contains(val)) {
        cells.add(FretboardCell(note: chromatic[val], isRoot: val == rootValue, fret: fret));
      } else {
        cells.add(FretboardCell(fret: fret));
      }
    }
    rows.add(FretboardRow(openNote: openNote, stringNumber: i + 1, cells: cells));
  }

  return FretboardDiagram(tuningName: tuning.name, tuningLabel: tuning.label, root: root, rows: rows);
}

class ChordFrets {
  final String tuningLabel;
  final List<String> tuningStrings;
  final List<int?> frets;
  const ChordFrets({required this.tuningLabel, required this.tuningStrings, required this.frets});
}

ChordFrets chordFrets(Tuning tuning, List<String> chordNotes) {
  final chordValues = chordNotes.map(noteValue).toSet();
  final frets = tuning.strings.map((openNote) {
    final openVal = noteValue(openNote);
    for (int fret = 0; fret <= maxFret; fret++) {
      if (chordValues.contains((openVal + fret) % 12)) return fret;
    }
    return null;
  }).toList();
  return ChordFrets(tuningLabel: tuning.label, tuningStrings: tuning.strings, frets: frets);
}
