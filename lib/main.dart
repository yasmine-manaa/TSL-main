import 'package:flutter/material.dart';
import 'pages/splash_screen.dart';
import 'pages/ai_detection_page.dart';
import 'services/backend_auth_service.dart';
import 'services/realtime_database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser la base de données
  final backendAuth = BackendAuthService();
  await backendAuth.initialize();
  
  // Initialiser Firebase Realtime Database
  RealtimeDatabaseService.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/ai-detection': (context) => const AIDetectionPage(),
      },
    );
  }
}
