import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
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
  double _smoothCents = 0;
  double _frequency = 0;
  String? _error;

  Float64List _cmndBuffer = Float64List(0);

  StreamSubscription<List<double>>? _audioSub;
  PitchDetector? _detector;
  List<double> _sampleBuffer = [];

  static const _alpha = 0.25;
  static const _bufferSize = 2 * 4096;

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

    final streamer = AudioStreamer();
    streamer.sampleRate = 44100;
    _detector = PitchDetector(sampleRate: 44100);

    _audioSub = streamer.audioStream.listen(
      _onAudioData,
      onError: (Object e) {
        setState(() {
          _isListening = false;
          _error = 'Erro no microfone: $e';
        });
      },
      cancelOnError: true,
    );

    streamer.actualSampleRate.then((rate) {
      final actualRate = rate.toInt();
      if (actualRate != 44100) {
        _detector = PitchDetector(sampleRate: actualRate);
      }
    });
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
      _cmndBuffer = Float64List(0);
    });
  }

  void _onAudioData(List<double> chunk) {
    if (_detector == null) return;

    _sampleBuffer.addAll(chunk);

    while (_sampleBuffer.length >= _bufferSize) {
      final samples = _sampleBuffer.sublist(0, _bufferSize);
      _sampleBuffer = _sampleBuffer.sublist(_bufferSize ~/ 2);

      final result = _detector?.detect(samples);
      if (!mounted) return;

      setState(() {
        if (result != null) {
          _cmndBuffer = result.cmnd;
          final pitch = result.pitch;
          if (pitch != null) {
            _note = pitch.note;
            _octave = pitch.octave;
            _cents = pitch.cents;
            _smoothCents = _smoothCents * (1 - _alpha) + _cents * _alpha;
            _frequency = pitch.frequency;
          } else {
            _note = '--';
            _cents = 0;
            _smoothCents = 0;
            _frequency = 0;
          }
        } else {
          _note = '--';
          _cents = 0;
          _smoothCents = 0;
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
            const SizedBox(height: 8),
            _buildGauge(),
            const SizedBox(height: 12),
            _buildNoteDisplay(),
            const SizedBox(height: 4),
            _buildFrequencyDisplay(),
            const SizedBox(height: 12),
            _buildDeviationBar(),
            const SizedBox(height: 16),
            _buildGraphs(),
            const Spacer(),
            if (_error != null) _buildError(),
            _buildToggleButton(),
            const SizedBox(height: 32),
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
          cents: _isListening ? _smoothCents : 0,
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
              cents: _isListening ? _smoothCents : 0,
              active: _isListening && _note != '--',
              accentColor: _deviationColor,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isListening && _note != '--'
              ? '${_smoothCents >= 0 ? '+' : ''}${_smoothCents.toStringAsFixed(1)} cents'
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

  Widget _buildGraphs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CMND (YIN)',
              style: TextStyle(fontSize: 10, color: AppColors.textDim),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: CustomPaint(
                size: Size.infinite,
                painter: _CmndPainter(
                  cmnd: _cmndBuffer,
                  threshold: _detector?.threshold ?? 0.15,
                ),
              ),
            ),
          ],
        ),
      ),
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

// ---------------------------------------------------------------------------
// Painters
// ---------------------------------------------------------------------------

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

class _CmndPainter extends CustomPainter {
  final Float64List cmnd;
  final double threshold;

  _CmndPainter({required this.cmnd, required this.threshold});

  static const _maxDisplay = 1.5;
  static const _maxTau = 800;

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = AppColors.surface
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(4),
      ),
      bgPaint,
    );

    // Threshold line
    final thresholdY = (threshold / _maxDisplay) * size.height;
    final thresholdPaint = Paint()
      ..color = AppColors.accent.withAlpha(120)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, thresholdY),
      Offset(size.width, thresholdY),
      thresholdPaint,
    );

    if (cmnd.isEmpty) return;

    final displayTau = cmnd.length.clamp(0, _maxTau);
    if (displayTau < 3) return;

    final paint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    final pixelCount = size.width.toInt();

    for (int x = 0; x < pixelCount; x++) {
      final tau = 2 + ((x / size.width) * (displayTau - 2)).toInt();
      if (tau >= cmnd.length) break;

      final y =
          (cmnd[tau].clamp(0.0, _maxDisplay) / _maxDisplay * size.height);

      if (x == 0) {
        path.moveTo(x.toDouble(), y);
      } else {
        path.lineTo(x.toDouble(), y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CmndPainter old) =>
      !identical(old.cmnd, cmnd) || old.threshold != threshold;
}
