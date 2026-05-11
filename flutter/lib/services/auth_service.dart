import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;
  AuthService._();

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  String? _googlePhotoUrl;

  User? get currentUser => _auth.currentUser;
  bool get isSignedIn => currentUser != null && !currentUser!.isAnonymous;
  String? get displayName => currentUser?.displayName;
  String? get email => currentUser?.email;
  String? get photoUrl => _googlePhotoUrl ?? currentUser?.photoURL;

  Future<void> ensureAuthenticated() async {
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return false;

      _googlePhotoUrl = googleUser.photoUrl;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final anonymousUid = currentUser?.isAnonymous == true ? currentUser!.uid : null;

      if (currentUser != null && currentUser!.isAnonymous) {
        try {
          await currentUser!.linkWithCredential(credential);
        } on FirebaseAuthException catch (e) {
          if (e.code == 'credential-already-in-use') {
            await _auth.signInWithCredential(credential);
          } else {
            rethrow;
          }
        }
      } else {
        await _auth.signInWithCredential(credential);
      }

      if (currentUser != null && currentUser!.photoURL == null && _googlePhotoUrl != null) {
        await currentUser!.updatePhotoURL(_googlePhotoUrl);
        await currentUser!.reload();
      }

      if (anonymousUid != null && currentUser != null && anonymousUid != currentUser!.uid) {
        await _migratePurchases(anonymousUid, currentUser!.uid);
      }

      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) print('Google Sign-In error: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    _googlePhotoUrl = null;
    await GoogleSignIn().signOut();
    await _auth.signInAnonymously();
    notifyListeners();
  }

  Future<void> _migratePurchases(String fromUid, String toUid) async {
    try {
      final oldPurchases = await _firestore
          .collection('users')
          .doc(fromUid)
          .collection('purchases')
          .get();

      if (oldPurchases.docs.isEmpty) return;

      final batch = _firestore.batch();
      final newPurchasesRef = _firestore.collection('users').doc(toUid).collection('purchases');

      for (final doc in oldPurchases.docs) {
        batch.set(newPurchasesRef.doc(doc.id), doc.data(), SetOptions(merge: true));
      }

      await batch.commit();
    } catch (e) {
      if (kDebugMode) print('Purchase migration skipped: $e');
    }
  }
}
