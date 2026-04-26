import 'package:flutter/foundation.dart';
import '../models/music_theory.dart';

const freeScales = {'maior', 'menor natural'};
const freeChords = {'maior', 'menor'};
const freeHarmonicFields = {'maior'};

class PremiumService extends ChangeNotifier {
  static final PremiumService _instance = PremiumService._();
  factory PremiumService() => _instance;
  PremiumService._();

  bool _isPremium = false;
  bool get isPremium => _isPremium;

  void setPremium(bool value) {
    _isPremium = value;
    notifyListeners();
  }

  bool isScaleFree(String name) => freeScales.contains(name);
  bool isChordFree(String name) => freeChords.contains(name);
  bool isHarmonicFieldFree(String name) => freeHarmonicFields.contains(name);
  bool isTuningFree(Tuning tuning) => tuning.free;

  bool canAccessScale(String name) => _isPremium || isScaleFree(name);
  bool canAccessChord(String name) => _isPremium || isChordFree(name);
  bool canAccessHarmonicField(String name) => _isPremium || isHarmonicFieldFree(name);
  bool canAccessTuning(Tuning tuning) => _isPremium || isTuningFree(tuning);
}
