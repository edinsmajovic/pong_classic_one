
class PurchaseService {
  bool _adsRemoved = false;
  bool get adsRemoved => _adsRemoved;

  // Simulate locked tiers (expert & insane)
  bool get hasPremium => _adsRemoved; // reuse flag for now

  Future<void> loadState() async {
    // Placeholder: load from persistent storage later
    await Future.delayed(const Duration(milliseconds: 50));
  }

  Future<void> buyRemoveAds() async {
    // Placeholder: integrate in-app purchases
    await Future.delayed(const Duration(milliseconds: 400));
    _adsRemoved = true;
  }
}
