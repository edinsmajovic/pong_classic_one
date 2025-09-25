import 'package:flutter/material.dart';
import 'screens/menu_screen.dart';
import 'services/purchase_service.dart';
import 'services/ads_service.dart';

class PongApp extends StatefulWidget {
  const PongApp({super.key});

  @override
  State<PongApp> createState() => _PongAppState();
}

class _PongAppState extends State<PongApp> {
  final purchaseService = PurchaseService();
  final adsService = AdsService();

  @override
  void initState() {
    super.initState();
    adsService.initialize();
    purchaseService.loadState();
  }

  @override
  Widget build(BuildContext context) {
    return InheritedPurchase(
      service: purchaseService,
      child: MaterialApp(
        title: 'Pong Classic One',
        theme: ThemeData.dark().copyWith(
          primaryColor: Colors.green,
          scaffoldBackgroundColor: Colors.black,
          textTheme: const TextTheme(
            displayLarge: TextStyle(color: Colors.white, fontSize: 32, fontFamily: 'monospace'),
            displayMedium: TextStyle(color: Colors.white, fontSize: 24, fontFamily: 'monospace'),
            bodyLarge: TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'monospace'),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.black,
              textStyle: const TextStyle(fontSize: 18, fontFamily: 'monospace'),
            ),
          ),
        ),
        debugShowCheckedModeBanner: false,
        home: MenuScreen(adsService: adsService),
      ),
    );
  }
}

class InheritedPurchase extends InheritedWidget {
  final PurchaseService service;
  const InheritedPurchase({super.key, required this.service, required super.child});

  static PurchaseService of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<InheritedPurchase>()!.service;

  @override
  bool updateShouldNotify(covariant InheritedPurchase oldWidget) =>
      oldWidget.service != service;
}
