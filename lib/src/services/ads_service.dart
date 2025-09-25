class AdsService {
  bool _initialized = false;
  bool get initialized => _initialized;

  // When running in widget tests we skip artificial delays to avoid pending timers.
  bool _isTestEnv = false;
  void _detectTest() {
    assert(() {
      _isTestEnv = true; // Only runs in debug/test
      return true;
    }());
  }

  Future<void> initialize() async {
    _detectTest();
    if (_isTestEnv) {
      _initialized = true;
      return;
    }
    await Future.delayed(const Duration(milliseconds: 150));
    _initialized = true;
  }

  bool get shouldShowBanner => _initialized; // later gate by purchase
  bool get shouldShowInterstitial => _initialized; // frequency capping later
}
