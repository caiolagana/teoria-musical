import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';
import 'services/tuning_service.dart';
import 'services/purchase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await AuthService().ensureAuthenticated();
  await TuningService().load();
  await PurchaseService().init();
  runApp(const MusicaioApp());
}

class MusicaioApp extends StatelessWidget {
  const MusicaioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Musicaio',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: const HomeScreen(),
    );
  }
}
