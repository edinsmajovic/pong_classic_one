class AdsService {
  bool _initialized = false;
  bool get initialized => _initialized;

  Future<void> initialize() async {
    await Future.delayed(const Duration(milliseconds: 150));
    _initialized = true;
  }

  bool get shouldShowBanner => _initialized; // later gate by purchase
  bool get shouldShowInterstitial => _initialized; // frequency capping later
}
