
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class PurchaseService {
  static const _keyPremium = 'premium_unlocked';
  bool _adsRemoved = false;
  bool get adsRemoved => _adsRemoved;
  bool get hasPremium => _adsRemoved;

  final List<VoidCallback> _listeners = [];
  void addListener(VoidCallback cb) => _listeners.add(cb);
  void removeListener(VoidCallback cb) => _listeners.remove(cb);
  void _notify() { for (final l in List<VoidCallback>.from(_listeners)) { l(); } }

  Future<void> loadState() async {
    final prefs = await SharedPreferences.getInstance();
    _adsRemoved = prefs.getBool(_keyPremium) ?? false;
    _notify();
  }

  Future<void> buyRemoveAds() async {
    // Simulated purchase flow
    await Future.delayed(const Duration(milliseconds: 400));
    _adsRemoved = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPremium, true);
    _notify();
  }
}
