import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/music_theory.dart';

class NoteSelector extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelect;

  const NoteSelector({super.key, this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children: noteGroups.map((g) => _buildGroup(g)).toList(),
    );
  }

  Widget _buildGroup(NoteGroup group) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (group.natural != null) _noteButton(group.natural!, false),
        if (group.sharp != null) _noteButton(group.sharp!, true),
        if (group.flat != null) _noteButton(group.flat!, true),
      ],
    );
  }

  Widget _noteButton(String note, bool isAccidental) {
    final isActive = selected == note;
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: GestureDetector(
        onTap: () => onSelect(note),
        child: Container(
          constraints: BoxConstraints(minWidth: isAccidental ? 36 : 42),
          padding: EdgeInsets.symmetric(
            horizontal: isAccidental ? 6 : 10,
            vertical: isAccidental ? 6 : 8,
          ),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.accent
                : isAccidental
                    ? const Color(0xFF111111)
                    : AppColors.surface,
            border: Border.all(color: isActive ? AppColors.accent : AppColors.border),
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Text(
            note,
            style: TextStyle(
              fontSize: isAccidental ? 12 : 14,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              color: isActive
                  ? AppColors.black
                  : isAccidental
                      ? const Color(0xFFAAAAAA)
                      : AppColors.text,
            ),
          ),
        ),
      ),
    );
  }
}
