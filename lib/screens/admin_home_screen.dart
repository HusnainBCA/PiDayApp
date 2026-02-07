import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:pidayapp/models/question.dart';
import 'package:pidayapp/models/score.dart';
import 'package:pidayapp/services/database_helper.dart';
import 'package:pidayapp/screens/add_question_screen.dart';
import 'package:pidayapp/data/sample_questions.dart';
import 'package:pidayapp/services/pi_background.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  late Future<List<Question>> _questionsFuture;
  late Future<List<Map<String, dynamic>>> _logsFuture;
  late Future<List<Map<String, dynamic>>> _bugsFuture;
  late Future<List<Map<String, dynamic>>> _requestsFuture;
  final TextEditingController _codeController = TextEditingController();
  bool _isSavingCode = false;

  @override
  void initState() {
    super.initState();
    _refreshAll();
    _loadCurrentCode();
  }

  void _refreshAll() {
    _refreshQuestions();
    _refreshLogs();
    _refreshBugs();
    _refreshRequests();
  }

  void _refreshQuestions() {
    setState(() {
      _questionsFuture = DatabaseHelper.instance.readAllQuestions();
    });
  }

  void _refreshLogs() {
    setState(() {
      _logsFuture = DatabaseHelper.instance.getLogs();
    });
  }

  void _refreshBugs() {
    setState(() {
      _bugsFuture = DatabaseHelper.instance.getBugReports();
    });
  }

  void _refreshRequests() {
    setState(() {
      _requestsFuture = DatabaseHelper.instance.getAccessRequests();
    });
  }

  Future<void> _loadCurrentCode() async {
    final code = await DatabaseHelper.instance.getSetting('daily_access_code');
    if (code != null) {
      _codeController.text = code;
    }
  }

  Future<void> _saveMasterLock(bool value) async {
    setState(() => _isSavingCode = true);
    await DatabaseHelper.instance
        .saveSetting('master_lock', value ? 'true' : 'false');
    if (mounted) {
      setState(() {
        _isSavingCode = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Master Protection ${value ? "ENABLED" : "DISABLED"}')),
      );
    }
  }

  Future<void> _approveStudent(String name) async {
    await DatabaseHelper.instance.approveStudent(name);
    _refreshRequests();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Approved: $name')),
      );
    }
  }

  Future<void> _resetApp() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset App Security?'),
        content: const Text(
            'This will clear the access code and lock the app for everyone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Reset', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.saveSetting('daily_access_code', '');
      await DatabaseHelper.instance.saveSetting('is_unlocked', 'false');
      _codeController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Security settings reset.')),
        );
      }
    }
  }

  Future<void> _deleteQuestion(int id) async {
    await DatabaseHelper.instance.delete(id);
    _refreshQuestions();
  }

  Future<void> _importSampleData() async {
    for (var q in sampleQuestions2016) {
      await DatabaseHelper.instance.create(q);
    }
    _refreshQuestions();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imported 2016 Sample Questions!')),
      );
    }
  }

  Future<void> _exportData() async {
    final questions = await DatabaseHelper.instance.readAllQuestions();
    final dataString = jsonEncode(questions.map((q) => q.toMap()).toList());

    // Generate the full content of the bundled_questions.dart file
    final fullFileContent = '''
// This file holds your questions for shipping the app.
// To update: Select ALL text in this file, delete it, and paste your new export.

const List<Map<String, dynamic>> bundledQuestions = $dataString;
''';

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Click Copy, then in "lib/data/bundled_questions.dart", press Ctrl+A (Select All) and Paste.'),
            const SizedBox(height: 10),
            Container(
              height: 200,
              width: double.maxFinite,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  fullFileContent,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: fullFileContent));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to Clipboard!')),
                );
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copy to Clipboard'),
          ),
        ],
      ),
    );
  }

  void _exportScores() async {
    final scores = await DatabaseHelper.instance.getAllScores();
    final jsonList = scores.map((s) => s.toMap()).toList();
    final jsonString = jsonEncode(jsonList);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Scores'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Copy this code and paste it into the "Import" section on another device to merge scores.'),
            const SizedBox(height: 16),
            Container(
              height: 150,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: SelectableText(jsonString,
                    style:
                        const TextStyle(fontFamily: 'monospace', fontSize: 10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
          ElevatedButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: jsonString));
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Scores Copied!')));
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copy to Clipboard'),
          ),
        ],
      ),
    );
  }

  void _importScores() {
    final TextEditingController importController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Scores'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Paste the score bundle code below to merge it with your local leaderboard.'),
            const SizedBox(height: 16),
            TextField(
              controller: importController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Paste code here...',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                final List<dynamic> jsonList =
                    jsonDecode(importController.text);
                final List<Score> newScores =
                    jsonList.map((j) => Score.fromMap(j)).toList();

                await DatabaseHelper.instance.mergeScores(newScores);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          'Successfully merged ${newScores.length} scores!')));
                  Navigator.pop(context);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Invalid code: $e'),
                        backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Merge Scores'),
          ),
        ],
      ),
    );
  }

  void _showQuestionDetails(BuildContext context, Question q) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Question Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Question Image
              if (q.imagePath != null && q.imagePath!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Column(
                    children: [
                      const Text('Question Image:',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(base64Decode(q.imagePath!),
                            fit: BoxFit.contain),
                      ),
                    ],
                  ),
                ),
              Text('Text:',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.indigo[900])),
              Text(q.text),
              const SizedBox(height: 12),
              Text('Options:',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.indigo[900])),
              ...q.options.asMap().entries.map((entry) {
                final isCorrect = entry.key == q.correctAnswerIndex;
                final letter = String.fromCharCode(65 + entry.key);
                final bool shouldHideText =
                    entry.value.trim().toUpperCase() == letter;

                return Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Row(
                    children: [
                      Icon(
                        isCorrect ? Icons.check_circle : Icons.circle_outlined,
                        size: 16,
                        color: isCorrect ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        letter,
                        style: TextStyle(
                          color: isCorrect ? Colors.green[800] : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (!shouldHideText) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: TextStyle(
                              color: isCorrect
                                  ? Colors.green[800]
                                  : Colors.black87,
                            ),
                          ),
                        ),
                      ]
                    ],
                  ),
                );
              }),
              const SizedBox(height: 12),
              Text('Difficulty: ',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.indigo[900])),
              Text(q.difficulty),

              const Divider(height: 24),
              Text('Solution:',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.amber[900])),
              const SizedBox(height: 8),

              // Solution Image
              if (q.solutionImagePath != null &&
                  q.solutionImagePath!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(base64Decode(q.solutionImagePath!),
                        fit: BoxFit.contain),
                  ),
                ),
              if (q.explanation.isNotEmpty)
                Text(q.explanation,
                    style: const TextStyle(
                        fontStyle: FontStyle.italic, color: Colors.black54)),
              if ((q.solutionImagePath == null ||
                      q.solutionImagePath!.isEmpty) &&
                  q.explanation.isEmpty)
                const Text('No detailed solution provided.',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Teacher Panel'),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: Colors.white,
            indicatorWeight: 4,
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            unselectedLabelStyle:
                TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
            padding: EdgeInsets.symmetric(horizontal: 8),
            tabs: [
              Tab(icon: Icon(Icons.quiz, size: 20), text: 'Questions'),
              Tab(icon: Icon(Icons.security, size: 20), text: 'Security'),
              Tab(icon: Icon(Icons.history, size: 20), text: 'Logins'),
              Tab(icon: Icon(Icons.bug_report, size: 20), text: 'Bugs'),
              Tab(icon: Icon(Icons.person_add, size: 20), text: 'Requests'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.upload_file),
              tooltip: 'Export Data',
              onPressed: _exportData,
            ),
          ],
        ),
        body: PiBackground(
          child: TabBarView(
            children: [
              _buildQuestionsTab(),
              _buildSecurityTab(),
              _buildLogsTab(),
              _buildBugsTab(),
              _buildRequestsTab(),
            ],
          ),
        ),
        floatingActionButton: Builder(builder: (context) {
          final tabIndex = DefaultTabController.of(context).index;
          return FloatingActionButton(
            child: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddQuestionScreen()),
              );
              _refreshQuestions();
            },
          );
        }),
      ),
    );
  }

  Widget _buildQuestionsTab() {
    return FutureBuilder<List<Question>>(
      future: _questionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final questions = snapshot.data ?? [];

        if (questions.isEmpty) {
          return const Center(
            child: Text(
              'No questions added yet.\nTap + to add one!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          itemCount: questions.length,
          itemBuilder: (context, index) {
            final q = questions[index];
            final hasImage = q.imagePath != null && q.imagePath!.isNotEmpty;
            final hasSolution =
                q.solutionImagePath != null && q.solutionImagePath!.isNotEmpty;

            return Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Stack(
                  children: [
                    Icon(hasImage ? Icons.image : Icons.text_fields,
                        color: const Color(0xFF8E2157), size: 30),
                    if (hasSolution)
                      const Positioned(
                        right: 0,
                        bottom: 0,
                        child: Icon(Icons.auto_awesome,
                            color: Colors.amber, size: 16),
                      ),
                  ],
                ),
                title: Text(
                  q.text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: q.difficulty == 'Easy'
                              ? Colors.green[50]
                              : (q.difficulty == 'Medium'
                                  ? Colors.orange[50]
                                  : Colors.red[50]),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: q.difficulty == 'Easy'
                                  ? Colors.green
                                  : (q.difficulty == 'Medium'
                                      ? Colors.orange
                                      : Colors.red)),
                        ),
                        child: Text(q.difficulty,
                            style: TextStyle(
                                fontSize: 12,
                                color: q.difficulty == 'Easy'
                                    ? Colors.green[800]
                                    : (q.difficulty == 'Medium'
                                        ? Colors.orange[800]
                                        : Colors.red[800]))),
                      ),
                    ],
                  ),
                ),
                onTap: () => _showQuestionDetails(context, q),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.grey),
                  onPressed: () => _deleteQuestion(q.id ?? -1),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSecurityTab() {
    return FutureBuilder<String?>(
      future: DatabaseHelper.instance.getSetting('master_lock'),
      builder: (context, snapshot) {
        final isLocked = snapshot.data == 'true';
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color:
                    isLocked ? const Color(0xFF8E2157) : Colors.grey.shade400,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(isLocked ? Icons.shield : Icons.shield_outlined,
                          color: Colors.white, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        isLocked
                            ? 'Master Protection: ON'
                            : 'Master Protection: OFF',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isLocked
                            ? 'Strict Mode: Students MUST be approved in the "Requests" tab to enter.'
                            : 'Open Mode: Students can access the quiz without approval.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SwitchListTile(
                title: const Text('Enable Master Protection',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                subtitle: const Text(
                    'Force students to request access and be individually approved.'),
                value: isLocked,
                activeColor: const Color(0xFF8E2157),
                onChanged: _isSavingCode ? null : (val) => _saveMasterLock(val),
              ),
              const SizedBox(height: 48),
              OutlinedButton.icon(
                onPressed: _resetApp,
                icon: const Icon(Icons.refresh),
                label: const Text('Reset All Data & Logs'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 48),
              const Text(
                'Manual Cloud Sync (Bridge)',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8E2157)),
              ),
              const SizedBox(height: 8),
              const Text(
                'Use this to sync scores between devices until full Cloud integration is enabled.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _exportScores,
                      icon: const Icon(Icons.upload),
                      label: const Text('Export Scores'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _importScores,
                      icon: const Icon(Icons.download),
                      label: const Text('Import Scores'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogsTab() {
    return _buildLogList(
      future: _logsFuture,
      onRefresh: _refreshLogs,
      tableName: 'logs',
      emptyMessage: 'No login activity yet.',
      itemBuilder: (log) => ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFF1E6EB),
          child: Icon(Icons.login, color: Color(0xFF8E2157)),
        ),
        title: Text(
            '${log['student_name'] ?? "Unknown"} (${log['year_group'] ?? "N/A"})'),
        subtitle:
            Text('${log['log_type'] ?? "Activity"}\n${log['timestamp'] ?? ""}'),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildBugsTab() {
    return _buildLogList(
      future: _bugsFuture,
      onRefresh: _refreshBugs,
      tableName: 'bug_reports',
      emptyMessage: 'No bug reports yet. Good news!',
      itemBuilder: (bug) => ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFF1E6EB),
          child: Icon(Icons.bug_report, color: Colors.red),
        ),
        title: Text(bug['student_name'] ?? "Unknown"),
        subtitle: Text(
            'Screen: ${bug['screen_name'] ?? "Unknown"}\nMessage: ${bug['message'] ?? ""}\nTime: ${bug['timestamp'] ?? ""}'),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildRequestsTab() {
    return _buildLogList(
      future: _requestsFuture,
      onRefresh: _refreshRequests,
      tableName: 'access_requests',
      emptyMessage: 'No pending access requests.',
      itemBuilder: (req) {
        final bool isApproved = req['status'] == 'approved';
        return ListTile(
          leading: CircleAvatar(
            backgroundColor:
                isApproved ? Colors.green.shade50 : const Color(0xFFF1E6EB),
            child: Icon(
              isApproved ? Icons.check_circle : Icons.person_add,
              color: isApproved ? Colors.green : Colors.blue,
            ),
          ),
          title: Text(req['student_name'] ?? "Unknown",
              style: TextStyle(
                  fontWeight:
                      isApproved ? FontWeight.normal : FontWeight.bold)),
          subtitle: Text('Request at: ${req['timestamp'] ?? ""}'),
          trailing: isApproved
              ? const Text('Approved',
                  style: TextStyle(
                      color: Colors.green, fontWeight: FontWeight.bold))
              : ElevatedButton(
                  onPressed: () => _approveStudent(req['student_name']),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white),
                  child: const Text('Approve'),
                ),
        );
      },
    );
  }

  Widget _buildLogList({
    required Future<List<Map<String, dynamic>>> future,
    required VoidCallback onRefresh,
    required String tableName,
    required String emptyMessage,
    required Widget Function(Map<String, dynamic>) itemBuilder,
  }) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final logs = snapshot.data ?? [];

        if (logs.isEmpty) {
          return Center(
            child:
                Text(emptyMessage, style: const TextStyle(color: Colors.grey)),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton.icon(
                onPressed: () async {
                  await DatabaseHelper.instance.clearTable(tableName);
                  onRefresh();
                },
                icon: const Icon(Icons.delete_sweep),
                label: Text('Clear $tableName'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                    foregroundColor: Colors.black87),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => onRefresh(),
                child: ListView.builder(
                  itemCount: logs.length,
                  itemBuilder: (context, index) => itemBuilder(logs[index]),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
