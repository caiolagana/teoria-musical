import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/music_theory.dart';
import '../services/auth_service.dart';
import '../services/premium_service.dart';
import '../services/purchase_service.dart';
import '../services/tuning_service.dart';
import 'widgets/note_selector.dart';
import 'widgets/fretboard_widget.dart';

enum TeoriaMode { scale, chord, harmonicField }

class TeoriaScreen extends StatefulWidget {
  const TeoriaScreen({super.key});

  @override
  State<TeoriaScreen> createState() => _TeoriaScreenState();
}

class _TeoriaScreenState extends State<TeoriaScreen> {
  final _premium = PremiumService();
  final _tuningService = TuningService();

  List<Tuning> get _tunings => _tuningService.tunings;
  TeoriaMode _mode = TeoriaMode.scale;
  String? _selectedNote;

  String? _selectedScale;
  String? _selectedChord;
  String? _selectedFieldType;

  @override
  void initState() {
    super.initState();
    _premium.addListener(_onPremiumChanged);
  }

  @override
  void dispose() {
    _premium.removeListener(_onPremiumChanged);
    super.dispose();
  }

  void _onPremiumChanged() => setState(() {});

  void _setMode(TeoriaMode mode) {
    setState(() {
      _mode = mode;
      _selectedNote = null;
      _selectedScale = null;
      _selectedChord = null;
      _selectedFieldType = null;
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
                canAccess: _premium.canAccessScale,
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
                canAccess: _premium.canAccessChord,
              ),
            ),
          ],
          if (_mode == TeoriaMode.harmonicField) ...[
            const SizedBox(height: 12),
            _buildPanel(
              title: 'TIPO',
              child: _buildTypeSelector(
                names: harmonicFieldTypes,
                selected: _selectedFieldType,
                onSelect: (n) => setState(() => _selectedFieldType = n),
                canAccess: _premium.canAccessHarmonicField,
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
        const SizedBox(width: 8),
        _modeTab('Harmônicos', TeoriaMode.harmonicField),
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
    required bool Function(String) canAccess,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: names.map((name) {
        final isActive = selected == name;
        final locked = !canAccess(name);
        return GestureDetector(
          onTap: () {
            if (locked) {
              _showPremiumDialog();
            } else {
              onSelect(name);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isActive ? AppColors.accent : locked ? const Color(0xFF121212) : AppColors.surface,
              border: Border.all(color: isActive ? AppColors.accent : locked ? const Color(0xFF222222) : AppColors.border),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (locked) const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Icon(Icons.lock, size: 13, color: Color(0xFF555555)),
                ),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    color: isActive ? AppColors.black : locked ? const Color(0xFF555555) : AppColors.text,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showLoginSuccess({VoidCallback? then}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Login realizado com sucesso',
            style: TextStyle(color: AppColors.text, fontSize: 18)),
        content: Text(
          AuthService().displayName ?? AuthService().email ?? '',
          style: const TextStyle(color: AppColors.textDim),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {});
              then?.call();
            },
            child: const Text('OK', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showPremiumDialog() {
    final auth = AuthService();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Premium',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            const Text(
              'Desbloqueie todas as escalas, acordes\ne campos harmônicos.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textDim),
            ),
            const SizedBox(height: 24),
            if (!auth.isSignedIn) ...[
              const Text(
                'Entre com sua conta Google para\nsalvar a compra de forma segura.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textDim),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    final success = await auth.signInWithGoogle();
                    if (success) {
                      await PurchaseService().reloadPurchases();
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        _showLoginSuccess(
                          then: _premium.isPremium ? null : _showPremiumDialog,
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.login),
                  label: const Text('Entrar com Google'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.black,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () async {
                  final success = await auth.signInWithGoogle();
                  if (success) {
                    await PurchaseService().reloadPurchases();
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      _showLoginSuccess();
                    }
                  }
                },
                child: const Text(
                  'Já comprou? Restaurar compras',
                  style: TextStyle(fontSize: 13, color: AppColors.textDim),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    PurchaseService().buyPremium();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.black,
                  ),
                  child: const Text('Fazer Upgrade — R\$ 14,90'),
                ),
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildResult() {
    if (_mode == TeoriaMode.scale) return _buildScaleResult();
    if (_mode == TeoriaMode.chord) return _buildChordResult();
    return _buildHarmonicFieldResult();
  }

  Widget _buildScaleResult() {
    if (_selectedNote == null || _selectedScale == null) return const SizedBox();
    final notes = buildScale(_selectedNote!, _selectedScale!);
    final title = 'Escala $_selectedScale de $_selectedNote';

    return _resultPanel(
      title: title,
      children: [
        _noteBadges(notes),
        ..._tunings.map((t) => _premium.canAccessTuning(t)
            ? FretboardWidget(diagram: buildFretboardDiagram(t, notes, _selectedNote!))
            : _lockedTuning(t)),
      ],
    );
  }

  Widget _buildChordResult() {
    if (_selectedNote == null || _selectedChord == null) return const SizedBox();
    final notes = buildChord(_selectedNote!, _selectedChord!);
    final accessibleTunings = _tunings.where((t) => _premium.canAccessTuning(t)).toList();
    final frets = accessibleTunings.map((t) => chordFrets(t, notes)).toList();
    final title = 'Acorde $_selectedNote $_selectedChord';

    return _resultPanel(
      title: title,
      children: [
        _noteBadges(notes),
        const SizedBox(height: 12),
        _buildChordFrets(frets),
        ..._tunings.map((t) => _premium.canAccessTuning(t)
            ? FretboardWidget(diagram: buildFretboardDiagram(t, notes, _selectedNote!))
            : _lockedTuning(t)),
      ],
    );
  }

  Widget _buildHarmonicFieldResult() {
    if (_selectedNote == null || _selectedFieldType == null) return const SizedBox();
    final chords = buildHarmonicField(_selectedNote!, _selectedFieldType!);
    final title = 'Campo harmônico $_selectedFieldType de $_selectedNote';

    return _resultPanel(
      title: title,
      children: [
        ...chords.map((chord) => Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 36,
                child: Text(
                  chord.degree,
                  style: const TextStyle(fontSize: 14, color: AppColors.textDim, fontWeight: FontWeight.w500),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  chord.label,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.black),
                ),
              ),
              const SizedBox(width: 12),
              ...chord.notes.map((note) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFF3A3A3A),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(note, style: const TextStyle(fontSize: 11, color: AppColors.text)),
                ),
              )),
            ],
          ),
        )),
      ],
    );
  }

  Widget _lockedTuning(Tuning tuning) {
    return GestureDetector(
      onTap: _showPremiumDialog,
      child: Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Row(
          children: [
            const Icon(Icons.lock, size: 14, color: Color(0xFF555555)),
            const SizedBox(width: 6),
            Text(tuning.label, style: const TextStyle(fontSize: 14, color: Color(0xFF555555))),
          ],
        ),
      ),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(cf.tuningLabel, style: const TextStyle(fontSize: 13, color: AppColors.text)),
                  const SizedBox(width: 6),
                  Text('(${cf.tuningStrings.join('-')})', style: const TextStyle(fontSize: 12, color: AppColors.textDim)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
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
