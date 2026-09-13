import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/services/offline_sync_service.dart';
import 'core/theme/app_theme.dart';
import 'screens/splash_screen.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await OfflineSyncService.instance.init();
  runApp(const TigaAngkatanApp());
}

class TigaAngkatanApp extends StatelessWidget {
  const TigaAngkatanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      title: 'Tiga Angkatan',
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
