import 'dart:math';
import 'dart:typed_data';

class PitchResult {
  final double frequency;
  final String note;
  final int octave;
  final double cents;

  const PitchResult({
    required this.frequency,
    required this.note,
    required this.octave,
    required this.cents,
  });
}

class DetectionResult {
  final PitchResult? pitch;
  final Float64List cmnd;

  const DetectionResult({this.pitch, required this.cmnd});
}

class PitchDetector {
  final int sampleRate;
  final double threshold;
  final double discardedInitialNoise;

  bool _wasSilent = true;

  static const _noteNames = [
    'C', 'C#', 'D', 'D#', 'E', 'F',
    'F#', 'G', 'G#', 'A', 'A#', 'B',
  ];

  PitchDetector({
    required this.sampleRate,
    this.threshold = 0.15,
    this.discardedInitialNoise = 0.1, // Porcentagem inicial do buffer descartada para cálculo da nota
  });

  DetectionResult? detect(List<double> buffer) {
    if (buffer.length < 512) return null;

    final cmnd = _computeCmnd(buffer);

    if (_rms(buffer) < 0.002) {
      _wasSilent = true;
      return DetectionResult(cmnd: cmnd);
    }

    Float64List pitchCmnd;
    if (_wasSilent) {
      final trimCount = (buffer.length * discardedInitialNoise).round();
      pitchCmnd = _computeCmnd(buffer.sublist(trimCount));
    } else {
      pitchCmnd = cmnd;
    }
    _wasSilent = false;

    final period = _findPeriod(pitchCmnd);
    if (period == null) return DetectionResult(cmnd: cmnd);

    final frequency = sampleRate / period;
    if (frequency < 60 || frequency > 1500) {
      return DetectionResult(cmnd: cmnd);
    }

    return DetectionResult(
      pitch: _frequencyToResult(frequency),
      cmnd: cmnd,
    );
  }

  double _rms(List<double> buffer) {
    var sum = 0.0;
    for (final s in buffer) {
      sum += s * s;
    }
    return sqrt(sum / buffer.length);
  }

  Float64List _computeCmnd(List<double> buffer) {
    final halfLen = buffer.length ~/ 2;
    final diff = Float64List(halfLen);

    for (int tau = 0; tau < halfLen; tau++) {
      var sum = 0.0;
      for (int j = 0; j < halfLen; j++) {
        final d = buffer[j] - buffer[j + tau];
        sum += d * d;
      }
      diff[tau] = sum;
    }

    diff[0] = 1.0;
    var runningSum = 0.0;
    for (int tau = 1; tau < halfLen; tau++) {
      runningSum += diff[tau];
      diff[tau] = diff[tau] * tau / runningSum;
    }

    return diff;
  }

  double? _findPeriod(Float64List cmnd) {
    final halfLen = cmnd.length;
    int? tauEstimate;
    for (int tau = 2; tau < halfLen; tau++) {
      if (cmnd[tau] < threshold) {
        while (tau + 1 < halfLen && cmnd[tau + 1] < cmnd[tau]) {
          tau++;
        }
        tauEstimate = tau;
        break;
      }
    }

    if (tauEstimate == null) return null;
    return _parabolicInterpolation(cmnd, tauEstimate);
  }

  double _parabolicInterpolation(Float64List data, int tau) {
    if (tau < 1 || tau >= data.length - 1) return tau.toDouble();

    final s0 = data[tau - 1];
    final s1 = data[tau];
    final s2 = data[tau + 1];
    final adjustment = (s0 - s2) / (2 * (s0 - 2 * s1 + s2));

    return tau + adjustment;
  }

  PitchResult _frequencyToResult(double frequency) {
    final midiNote = 69.0 + 12.0 * (log(frequency / 440.0) / ln2);
    final roundedMidi = midiNote.round();
    final cents = (midiNote - roundedMidi) * 100;
    final noteIndex = roundedMidi % 12;
    final octave = (roundedMidi ~/ 12) - 1;

    return PitchResult(
      frequency: frequency,
      note: _noteNames[noteIndex],
      octave: octave,
      cents: cents,
    );
  }
}
