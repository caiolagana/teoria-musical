import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/music_theory.dart';

class TuningService {
  static final TuningService _instance = TuningService._();
  factory TuningService() => _instance;
  TuningService._();

  final _collection = FirebaseFirestore.instance.collection('tunings');

  List<Tuning> _tunings = [];
  bool _loaded = false;

  List<Tuning> get tunings => _loaded && _tunings.isNotEmpty ? _tunings : fallbackTunings;

  Future<void> load() async {
    if (_loaded) return;
    try {
      final snapshot = await _collection.get();
      _tunings = snapshot.docs
          .map((doc) => Tuning.fromFirestore(doc.id, doc.data()))
          .toList();
    } catch (_) {
      _tunings = [];
    }
    _loaded = true;
  }

  Future<void> refresh() async {
    _loaded = false;
    await load();
  }
}
