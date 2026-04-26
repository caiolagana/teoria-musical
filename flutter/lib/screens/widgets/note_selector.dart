import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/music_theory.dart';

class NoteSelector extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelect;

  const NoteSelector({super.key, this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final allNotes = <_NoteEntry>[];
    for (final g in noteGroups) {
      if (g.natural != null) allNotes.add(_NoteEntry(g.natural!, false));
      if (g.sharp != null) allNotes.add(_NoteEntry(g.sharp!, true));
      if (g.flat != null) allNotes.add(_NoteEntry(g.flat!, true));
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: allNotes.map((e) => _noteChip(e.name, e.isAccidental)).toList(),
    );
  }

  Widget _noteChip(String note, bool isAccidental) {
    final isActive = selected == note;
    return GestureDetector(
      onTap: () => onSelect(note),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.accent
              : isAccidental
                  ? const Color(0xFF111111)
                  : AppColors.surface,
          border: Border.all(color: isActive ? AppColors.accent : AppColors.border),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          note,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            color: isActive
                ? AppColors.black
                : isAccidental
                    ? const Color(0xFFAAAAAA)
                    : AppColors.text,
          ),
        ),
      ),
    );
  }
}

class _NoteEntry {
  final String name;
  final bool isAccidental;
  const _NoteEntry(this.name, this.isAccidental);
}
