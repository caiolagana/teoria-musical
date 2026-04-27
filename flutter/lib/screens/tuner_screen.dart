import 'dart:async';
import 'dart:math';
import 'package:audio_streamer/audio_streamer.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/pitch_detector.dart';
import '../theme/app_theme.dart';

class TunerScreen extends StatefulWidget {
  const TunerScreen({super.key});

  @override
  State<TunerScreen> createState() => _TunerScreenState();
}

class _TunerScreenState extends State<TunerScreen> {
  bool _isListening = false;
  String _note = '--';
  int _octave = 4;
  double _cents = 0;
  double _frequency = 0;
  String? _error;

  int _chunksReceived = 0;
  double _rmsLevel = 0;
  double _maxSample = 0;
  String _yinStatus = 'aguardando';

  StreamSubscription<List<double>>? _audioSub;
  PitchDetector? _detector;
  List<double> _sampleBuffer = [];

  static const _bufferSize = 3 * 4096; // 93ms de áudio a cada 4096 amostras

  @override
  void dispose() {
    _stopListening();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      _stopListening();
    } else {
      await _startListening();
    }
  }

  Future<void> _startListening() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      setState(() => _error = 'Permissão de microfone negada');
      return;
    }

    setState(() {
      _error = null;
      _isListening = true;
    });

    _sampleBuffer = [];
    _chunksReceived = 0;

    AudioStreamer().sampleRate = 44100;
    _audioSub = AudioStreamer().audioStream.listen(
      _onAudioData,
      onError: (Object e) {
        setState(() {
          _isListening = false;
          _error = 'Erro no microfone: $e';
        });
      },
      cancelOnError: true,
    );

    final rate = await AudioStreamer().actualSampleRate;
    _detector = PitchDetector(sampleRate: rate.toInt());
  }

  void _stopListening() {
    _audioSub?.cancel();
    _audioSub = null;
    _sampleBuffer = [];
    setState(() {
      _isListening = false;
      _note = '--';
      _cents = 0;
      _frequency = 0;
    });
  }

  void _onAudioData(List<double> chunk) {
    _chunksReceived++;

    if (_detector == null) return;

    _sampleBuffer.addAll(chunk);

    while (_sampleBuffer.length >= _bufferSize) {
      final samples = _sampleBuffer.sublist(0, _bufferSize);
      _sampleBuffer = _sampleBuffer.sublist(_bufferSize ~/ 2);

      var sumSq = 0.0;
      var maxAbs = 0.0;
      for (final s in samples) {
        sumSq += s * s;
        final a = s.abs();
        if (a > maxAbs) maxAbs = a;
      }
      final rms = sqrt(sumSq / samples.length);

      final result = _detector?.detect(samples);
      if (!mounted) return;

      setState(() {
        _rmsLevel = rms;
        _maxSample = maxAbs;
        if (result != null) {
          _yinStatus = '${result.frequency.toStringAsFixed(1)} Hz → ${result.note}${result.octave}';
          _note = result.note;
          _octave = result.octave;
          _cents = result.cents;
          _frequency = result.frequency;
        } else {
          _yinStatus = rms < 0.002 ? 'silêncio (RMS baixo)' : 'sem pitch detectado';
          _note = '--';
          _cents = 0;
          _frequency = 0;
        }
      });
    }
  }

  String get _deviationLabel {
    if (!_isListening || _note == '--') return '';
    if (_cents.abs() < 5) return 'Afinado';
    return _cents < 0 ? 'Baixo' : 'Alto';
  }

  Color get _deviationColor {
    if (_cents.abs() < 5) return const Color(0xFF4CAF50);
    if (_cents.abs() < 20) return AppColors.accent;
    return const Color(0xFFEF5350);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Afinador')),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            _buildGauge(),
            const SizedBox(height: 32),
            _buildNoteDisplay(),
            const SizedBox(height: 8),
            _buildFrequencyDisplay(),
            const SizedBox(height: 24),
            _buildDeviationBar(),
            const Spacer(flex: 3),
            if (_error != null) _buildError(),
            _buildToggleButton(),
            const SizedBox(height: 16),
            if (_isListening) _buildDebugInfo(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildGauge() {
    return SizedBox(
      width: 280,
      height: 160,
      child: CustomPaint(
        painter: _GaugePainter(
          cents: _isListening ? _cents : 0,
          active: _isListening && _note != '--',
          accentColor: _deviationColor,
        ),
      ),
    );
  }

  Widget _buildNoteDisplay() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          _note,
          style: const TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.w200,
            letterSpacing: 2,
            color: AppColors.text,
          ),
        ),
        if (_isListening && _note != '--')
          Text(
            '$_octave',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w300,
              color: AppColors.textDim,
            ),
          ),
      ],
    );
  }

  Widget _buildFrequencyDisplay() {
    final freqText = _isListening && _frequency > 0
        ? '${_frequency.toStringAsFixed(1)} Hz'
        : '— Hz';
    return Text(
      freqText,
      style: const TextStyle(fontSize: 16, color: AppColors.textDim),
    );
  }

  Widget _buildDeviationBar() {
    return Column(
      children: [
        SizedBox(
          width: 260,
          height: 40,
          child: CustomPaint(
            painter: _DeviationBarPainter(
              cents: _isListening ? _cents : 0,
              active: _isListening && _note != '--',
              accentColor: _deviationColor,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isListening && _note != '--'
              ? '${_cents >= 0 ? '+' : ''}${_cents.toStringAsFixed(1)} cents'
              : '',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _deviationColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _deviationLabel,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _deviationColor,
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        _error!,
        style: const TextStyle(fontSize: 14, color: Color(0xFFEF5350)),
      ),
    );
  }

  Widget _buildDebugInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DEBUG',
            style: TextStyle(
              fontSize: 10,
              color: AppColors.accent,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Chunks: $_chunksReceived\n'
            'RMS: ${_rmsLevel.toStringAsFixed(6)}\n'
            'Max: ${_maxSample.toStringAsFixed(6)}\n'
            'Buffer: ${_sampleBuffer.length}\n'
            'YIN: $_yinStatus',
            style: const TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
              color: AppColors.textDim,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton() {
    return GestureDetector(
      onTap: _toggleListening,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isListening ? AppColors.accent : AppColors.surface,
          border: Border.all(
            color: _isListening ? AppColors.accent : AppColors.border,
            width: 2,
          ),
        ),
        child: Icon(
          _isListening ? Icons.mic : Icons.mic_off,
          size: 32,
          color: _isListening ? AppColors.black : AppColors.textDim,
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double cents;
  final bool active;
  final Color accentColor;

  _GaugePainter({
    required this.cents,
    required this.active,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 16;

    final trackPaint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi,
      pi,
      false,
      trackPaint,
    );

    _drawTicks(canvas, center, radius);

    if (active) {
      _drawNeedle(canvas, center, radius);
    }

    final dotPaint = Paint()
      ..color = active ? accentColor : AppColors.border
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 6, dotPaint);
  }

  void _drawTicks(Canvas canvas, Offset center, double radius) {
    final tickPaint = Paint()
      ..color = AppColors.textDim.withAlpha(100)
      ..strokeWidth = 1;

    final centerTickPaint = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 2;

    for (int i = 0; i <= 20; i++) {
      final angle = pi + (pi * i / 20);
      final isCenter = i == 10;
      final isMajor = i % 5 == 0;
      final innerMult = isCenter ? 0.78 : (isMajor ? 0.82 : 0.88);
      final inner = Offset(
        center.dx + radius * innerMult * cos(angle),
        center.dy + radius * innerMult * sin(angle),
      );
      final outer = Offset(
        center.dx + radius * 0.95 * cos(angle),
        center.dy + radius * 0.95 * sin(angle),
      );
      canvas.drawLine(inner, outer, isCenter ? centerTickPaint : tickPaint);
    }
  }

  void _drawNeedle(Canvas canvas, Offset center, double radius) {
    final clamped = cents.clamp(-50.0, 50.0);
    final angle = pi + (pi * (clamped + 50) / 100);

    final needlePaint = Paint()
      ..color = accentColor
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final tip = Offset(
      center.dx + radius * 0.75 * cos(angle),
      center.dy + radius * 0.75 * sin(angle),
    );
    canvas.drawLine(center, tip, needlePaint);
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.cents != cents || old.active != active || old.accentColor != accentColor;
}

class _DeviationBarPainter extends CustomPainter {
  final double cents;
  final bool active;
  final Color accentColor;

  _DeviationBarPainter({
    required this.cents,
    required this.active,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final y = size.height / 2;
    final barHeight = 6.0;

    final bgPaint = Paint()
      ..color = AppColors.border
      ..strokeCap = StrokeCap.round;
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(centerX, y), width: size.width, height: barHeight),
      const Radius.circular(3),
    );
    canvas.drawRRect(bgRect, bgPaint);

    final centerMark = Paint()
      ..color = AppColors.accent.withAlpha(150)
      ..strokeWidth = 2;
    canvas.drawLine(Offset(centerX, y - 12), Offset(centerX, y + 12), centerMark);

    if (active) {
      final clamped = cents.clamp(-50.0, 50.0);
      final indicatorX = centerX + (clamped / 50) * (size.width / 2 - 8);

      final indicatorPaint = Paint()
        ..color = accentColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(indicatorX, y), 10, indicatorPaint);

      final innerPaint = Paint()
        ..color = AppColors.black
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(indicatorX, y), 4, innerPaint);
    }
  }

  @override
  bool shouldRepaint(_DeviationBarPainter old) =>
      old.cents != cents || old.active != active || old.accentColor != accentColor;
}
