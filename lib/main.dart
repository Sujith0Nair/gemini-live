import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:gemini_live_app/application/home_screen.dart';
import 'package:gemini_live_app/infrastructure/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const GeminiLiveApp());
}

class GeminiLiveApp extends StatelessWidget {
  const GeminiLiveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gemini Live',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF131314),
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFA8C7FA),
          secondary: Color(0xFFD3E3FD),
          surface: Color(0xFF131314),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
