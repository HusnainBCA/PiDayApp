import 'package:flutter/material.dart';
import 'package:pidayapp/screens/admin_home_screen.dart';
import 'package:pidayapp/screens/quiz_setup_screen.dart';
import 'package:pidayapp/screens/leaderboard_screen.dart';
import 'package:pidayapp/services/pi_background.dart';
import 'package:pidayapp/services/bug_report_dialog.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pi Day App'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
              );
            },
            icon: const Icon(Icons.leaderboard),
            tooltip: 'View Leaderboard',
          ),
          IconButton(
            onPressed: () =>
                BugReportDialog.show(context, screenName: 'Home Screen'),
            icon: const Icon(Icons.bug_report),
            tooltip: 'Report a Bug',
          ),
        ],
      ),
      body: PiBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Grand Dashboard',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8E2157)),
              ),
              const SizedBox(height: 12),
              const Text(
                'Welcome back, Mr Afsar.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
                  );
                },
                icon: const Icon(Icons.admin_panel_settings,
                    color: Colors.white, size: 28),
                label: const Text('Open Teacher Panel'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 25),
                  textStyle: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                  backgroundColor: const Color(0xFF8E2157),
                  foregroundColor: Colors.white,
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
              ),
              const SizedBox(height: 60),
              Padding(
                padding: const EdgeInsets.only(right: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const QuizSetupScreen()),
                        );
                      },
                      icon: const Icon(Icons.preview_outlined, size: 18),
                      label: const Text('Student View'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        foregroundColor: const Color(0xFF5C0632),
                        side: const BorderSide(color: Color(0xFF5C0632)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
