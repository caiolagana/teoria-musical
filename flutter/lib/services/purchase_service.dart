import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../models/score.dart';
import 'premium_service.dart';

class PurchaseService extends ChangeNotifier {
  static final PurchaseService _instance = PurchaseService._();
  factory PurchaseService() => _instance;
  PurchaseService._();

  static const premiumProductId = 'musicaio_premium_upgrade';

  final _iap = InAppPurchase.instance;
  final _firestore = FirebaseFirestore.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  final Set<String> _purchasedScoreIds = {};
  bool get initialized => _initialized;
  bool _initialized = false;

  bool hasAccess(Score score) => score.free || _purchasedScoreIds.contains(score.id);

  Future<void> reloadPurchases() async {
    _purchasedScoreIds.clear();
    await _loadPurchasesFromFirestore();
  }

  Future<void> init() async {
    if (_initialized) return;

    await _loadPurchasesFromFirestore();

    if (await _iap.isAvailable()) {
      _subscription = _iap.purchaseStream.listen(_onPurchaseUpdate);
    }

    _initialized = true;
  }

  Future<void> buyPremium() async {
    if (!await _iap.isAvailable()) {
      if (kDebugMode) {
        await _grantPremium();
      }
      return;
    }

    final response = await _iap.queryProductDetails({premiumProductId});
    if (response.productDetails.isEmpty) return;

    final product = response.productDetails.first;
    final purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> buyScore(Score score) async {
    if (score.free || score.productId == null) return;

    if (!await _iap.isAvailable()) {
      if (kDebugMode) {
        await _grantAccess(score.id);
      }
      return;
    }

    final response = await _iap.queryProductDetails({score.productId!});
    if (response.productDetails.isEmpty) return;

    final product = response.productDetails.first;
    final purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyConsumable(purchaseParam: purchaseParam);
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        _verifyAndDeliver(purchase);
      }
      if (purchase.pendingCompletePurchase) {
        _iap.completePurchase(purchase);
      }
    }
  }

  Future<void> _verifyAndDeliver(PurchaseDetails purchase) async {
    if (purchase.productID == premiumProductId) {
      await _grantPremium();
      return;
    }

    final scoreId = _scoreIdFromProductId(purchase.productID);
    if (scoreId != null) {
      await _grantAccess(scoreId);
    }
  }

  Future<void> _grantPremium() async {
    PremiumService().setPremium(true);
    notifyListeners();

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('purchases')
        .doc('premium')
        .set({'purchasedAt': FieldValue.serverTimestamp()});
  }

  Future<void> _grantAccess(String scoreId) async {
    _purchasedScoreIds.add(scoreId);
    notifyListeners();

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('purchases')
        .doc(scoreId)
        .set({'purchasedAt': FieldValue.serverTimestamp()});
  }

  Future<void> _loadPurchasesFromFirestore() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('purchases')
        .get();

    for (final doc in snapshot.docs) {
      if (doc.id == 'premium') {
        PremiumService().setPremium(true);
      } else {
        _purchasedScoreIds.add(doc.id);
      }
    }
    notifyListeners();
  }

  String? _scoreIdFromProductId(String productId) {
    final prefix = 'score_';
    if (productId.startsWith(prefix)) {
      return productId.substring(prefix.length);
    }
    return null;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
