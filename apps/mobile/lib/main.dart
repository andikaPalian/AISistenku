import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_theme.dart';
import 'screens/shell_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const TigaAngkatanApp());
}

class TigaAngkatanApp extends StatelessWidget {
  const TigaAngkatanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tiga Angkatan',
      theme: AppTheme.lightTheme,
      home: const ShellScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
