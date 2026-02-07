import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:pidayapp/screens/home_screen.dart';
import 'package:pidayapp/screens/authorization_screen.dart';
import 'package:pidayapp/screens/quiz_setup_screen.dart';
import 'package:pidayapp/services/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Ensure DB is ready (only for mobile)
  if (!kIsWeb) {
    await DatabaseHelper.instance.database;
  }
  await DatabaseHelper.instance.seedDatabaseIfNeeded();

  runApp(const QuizApp());
}

class QuizApp extends StatelessWidget {
  const QuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pi Day App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8E2157),
          primary: const Color(0xFF8E2157),
          secondary: const Color(0xFF5C0632),
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF8E2157),
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
      ),
      initialRoute: '/auth',
      routes: {
        '/': (context) => const HomeScreen(),
        '/auth': (context) => const AuthorizationScreen(),
        '/quiz-setup': (context) => const QuizSetupScreen(),
      },
    );
  }
}
