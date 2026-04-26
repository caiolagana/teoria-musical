import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/score.dart';

class ScoreService {
  final _collection = FirebaseFirestore.instance.collection('scores');

  Stream<List<Score>> getScores() {
    return _collection.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => Score.fromFirestore(doc.id, doc.data()))
        .toList());
  }

  Future<Score?> getScore(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return Score.fromFirestore(doc.id, doc.data()!);
  }
}
