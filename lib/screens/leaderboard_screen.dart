import 'package:flutter/material.dart';
import 'package:pidayapp/models/score.dart';
import 'package:pidayapp/services/database_helper.dart';
import 'package:pidayapp/services/pi_background.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        centerTitle: true,
      ),
      body: PiBackground(
        child: FutureBuilder<List<Score>>(
          future: DatabaseHelper.instance.getLeaderboard(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final scores = snapshot.data ?? [];

            return Column(
              children: [
                // Header Row
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  color: const Color(0xFF8E2157).withOpacity(0.1),
                  child: const Row(
                    children: [
                      SizedBox(
                          width: 40,
                          child: Text('Rank',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF8E2157)))),
                      SizedBox(width: 16),
                      Expanded(
                          child: Text('Name',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF8E2157)))),
                      Text('Points',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF8E2157))),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: scores.length + 1, // +1 for Mr Afsar
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        // Mr Afsar Boss Mode
                        return _buildLeaderboardTile(
                          rank: 1,
                          name: 'Mr Afsar',
                          points: 'More than you',
                          color: Colors.amber.shade700,
                          isMrAfsar: true,
                        );
                      }

                      final score = scores[index - 1];
                      final rank = index + 1;
                      Color color = Colors.grey.shade100;

                      if (rank == 2) color = Colors.blueGrey.shade200; // Silver
                      if (rank == 3) color = Colors.brown.shade300; // Bronze

                      return _buildLeaderboardTile(
                        rank: rank,
                        name: score.name,
                        points: '${score.points} pts',
                        color: color,
                        isMrAfsar: false,
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLeaderboardTile({
    required int rank,
    required String name,
    required String points,
    required Color color,
    required bool isMrAfsar,
  }) {
    return Card(
      elevation: isMrAfsar ? 8 : 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isMrAfsar
            ? BorderSide(color: Colors.amber.shade800, width: 2)
            : BorderSide.none,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              if (rank <= 3)
                BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                )
            ],
          ),
          child: Center(
            child: Text(
              rank.toString(),
              style: TextStyle(
                color: rank <= 3 ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
        title: Text(
          name,
          style: TextStyle(
            fontWeight: isMrAfsar ? FontWeight.bold : FontWeight.normal,
            fontSize: 18,
            color: isMrAfsar ? Colors.amber.shade900 : Colors.black87,
          ),
        ),
        trailing: Text(
          points,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isMrAfsar ? Colors.amber.shade900 : const Color(0xFF8E2157),
          ),
        ),
      ),
    );
  }
}
