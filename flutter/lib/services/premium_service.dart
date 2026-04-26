import 'package:flutter/foundation.dart';

const freeScales = {'maior', 'menor natural'};
const freeChords = {'maior', 'menor'};

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

  bool canAccessScale(String name) => _isPremium || isScaleFree(name);
  bool canAccessChord(String name) => _isPremium || isChordFree(name);
}
