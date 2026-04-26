import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/music_theory.dart';

class FretboardWidget extends StatelessWidget {
  final FretboardDiagram diagram;

  const FretboardWidget({super.key, required this.diagram});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(diagram.tuningLabel, style: const TextStyle(fontSize: 14, color: AppColors.textDim)),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: _buildTable(),
        ),
      ],
    );
  }

  Widget _buildTable() {
    final fretNums = List.generate(maxFret + 1, (i) => i);

    return Table(
      defaultColumnWidth: const FixedColumnWidth(32),
      columnWidths: const {0: IntrinsicColumnWidth()},
      children: [
        TableRow(
          children: [
            const SizedBox(),
            ...fretNums.map((f) => _headerCell(f)),
          ],
        ),
        ...diagram.rows.map((row) => TableRow(
          children: [
            _stringLabel(row),
            ...row.cells.map((cell) => _fretCell(cell)),
          ],
        )),
      ],
    );
  }

  Widget _headerCell(int fret) {
    return Container(
      padding: const EdgeInsets.only(bottom: 6),
      decoration: fret == 0
          ? const BoxDecoration(border: Border(right: BorderSide(color: AppColors.textDim, width: 1)))
          : null,
      alignment: Alignment.center,
      child: Text('$fret', style: const TextStyle(fontSize: 11, color: AppColors.textDim)),
    );
  }

  Widget _stringLabel(FretboardRow row) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Text(
        '${row.openNote} (${row.stringNumber}a)',
        textAlign: TextAlign.right,
        style: const TextStyle(fontSize: 12, color: AppColors.textDim),
      ),
    );
  }

  Widget _fretCell(FretboardCell cell) {
    return Container(
      height: 28,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: cell.fret == 0 ? const Color(0xFF666666) : const Color(0xFF222222),
            width: cell.fret == 0 ? 2 : 1,
          ),
          bottom: const BorderSide(color: Color(0xFF1A1A1A)),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(height: 1, color: const Color(0xFF333333)),
          if (cell.note != null)
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cell.isRoot ? AppColors.accent : const Color(0xFF3A3A3A),
              ),
              alignment: Alignment.center,
              child: Text(
                cell.note!,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: cell.isRoot ? FontWeight.w700 : FontWeight.w500,
                  color: cell.isRoot ? AppColors.black : AppColors.text,
                ),
              ),
            )
          else
            const Text('·', style: TextStyle(color: Color(0xFF333333), fontSize: 14)),
        ],
      ),
    );
  }
}
