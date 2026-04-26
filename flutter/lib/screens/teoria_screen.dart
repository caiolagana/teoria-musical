import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/music_theory.dart';
import 'widgets/note_selector.dart';
import 'widgets/fretboard_widget.dart';

enum TeoriaMode { scale, chord }

class TeoriaScreen extends StatefulWidget {
  const TeoriaScreen({super.key});

  @override
  State<TeoriaScreen> createState() => _TeoriaScreenState();
}

class _TeoriaScreenState extends State<TeoriaScreen> {
  TeoriaMode _mode = TeoriaMode.scale;
  String? _selectedNote;

  String? _selectedScale;
  String? _selectedChord;

  void _setMode(TeoriaMode mode) {
    setState(() {
      _mode = mode;
      _selectedNote = null;
      _selectedScale = null;
      _selectedChord = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildModeTabs(),
          const SizedBox(height: 16),
          _buildPanel(
            title: 'NOTA FUNDAMENTAL',
            child: NoteSelector(
              selected: _selectedNote,
              onSelect: (n) => setState(() => _selectedNote = n),
            ),
          ),
          if (_mode == TeoriaMode.scale) ...[
            const SizedBox(height: 12),
            _buildPanel(
              title: 'TIPO DE ESCALA',
              child: _buildTypeSelector(
                names: scaleFormulas.keys.toList(),
                selected: _selectedScale,
                onSelect: (n) => setState(() => _selectedScale = n),
              ),
            ),
          ],
          if (_mode == TeoriaMode.chord) ...[
            const SizedBox(height: 12),
            _buildPanel(
              title: 'TIPO DE ACORDE',
              child: _buildTypeSelector(
                names: chordFormulas.keys.toList(),
                selected: _selectedChord,
                onSelect: (n) => setState(() => _selectedChord = n),
              ),
            ),
          ],
          const SizedBox(height: 12),
          _buildResult(),
        ],
      ),
    );
  }

  Widget _buildModeTabs() {
    return Row(
      children: [
        _modeTab('Escalas', TeoriaMode.scale),
        const SizedBox(width: 8),
        _modeTab('Acordes', TeoriaMode.chord),
      ],
    );
  }

  Widget _modeTab(String label, TeoriaMode mode) {
    final isActive = _mode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => _setMode(mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? AppColors.accent : AppColors.background,
            border: Border.all(color: isActive ? AppColors.accent : AppColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              color: isActive ? AppColors.black : AppColors.textDim,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPanel({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColors.textDim,
            letterSpacing: 1,
          )),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildTypeSelector({
    required List<String> names,
    required String? selected,
    required ValueChanged<String> onSelect,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: names.map((name) {
        final isActive = selected == name;
        return GestureDetector(
          onTap: () => onSelect(name),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isActive ? AppColors.accent : AppColors.surface,
              border: Border.all(color: isActive ? AppColors.accent : AppColors.border),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? AppColors.black : AppColors.text,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildResult() {
    if (_mode == TeoriaMode.scale) return _buildScaleResult();
    return _buildChordResult();
  }

  Widget _buildScaleResult() {
    if (_selectedNote == null || _selectedScale == null) return const SizedBox();
    final notes = buildScale(_selectedNote!, _selectedScale!);
    final diagrams = tunings.map((t) => buildFretboardDiagram(t, notes, _selectedNote!)).toList();
    final title = 'Escala $_selectedScale de $_selectedNote';

    return _resultPanel(
      title: title,
      children: [
        _noteBadges(notes),
        ...diagrams.map((d) => FretboardWidget(diagram: d)),
      ],
    );
  }

  Widget _buildChordResult() {
    if (_selectedNote == null || _selectedChord == null) return const SizedBox();
    final notes = buildChord(_selectedNote!, _selectedChord!);
    final frets = tunings.map((t) => chordFrets(t, notes)).toList();
    final diagrams = tunings.map((t) => buildFretboardDiagram(t, notes, _selectedNote!)).toList();
    final title = 'Acorde $_selectedNote $_selectedChord';

    return _resultPanel(
      title: title,
      children: [
        _noteBadges(notes),
        const SizedBox(height: 12),
        _buildChordFrets(frets),
        ...diagrams.map((d) => FretboardWidget(diagram: d)),
      ],
    );
  }

  Widget _resultPanel({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.accentDark),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColors.textDim,
            letterSpacing: 1,
          )),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _noteBadges(List<String> notes) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (int i = 0; i < notes.length; i++)
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              notes[i],
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.black),
            ),
          ),
      ],
    );
  }

  Widget _buildChordFrets(List<ChordFrets> fretsList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Posições nos instrumentos', style: TextStyle(fontSize: 14, color: AppColors.textDim)),
        const SizedBox(height: 8),
        ...fretsList.map((cf) => Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(cf.tuningLabel, style: const TextStyle(fontSize: 13, color: AppColors.text)),
              Text('(${cf.tuningStrings.join('-')})', style: const TextStyle(fontSize: 12, color: AppColors.textDim)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: cf.frets.map((f) => Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: f == null ? const Color(0xFF222222) : const Color(0xFF3A3A3A),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      f == null ? 'X' : '$f',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: f == null ? const Color(0xFF555555) : AppColors.text,
                      ),
                    ),
                  ),
                )).toList(),
              ),
            ],
          ),
        )),
      ],
    );
  }
}
