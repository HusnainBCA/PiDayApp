import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pidayapp/models/question.dart';
import 'package:pidayapp/models/score.dart';
import 'package:pidayapp/data/bundled_questions.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  // In-memory store for Web
  final List<Question> _webQuestions = [];
  final List<Score> _webScores = [];
  final Map<String, String> _webSettings = {};
  final List<Map<String, dynamic>> _webLogs = [];
  final List<Map<String, dynamic>> _webBugReports = [];
  final List<Map<String, dynamic>> _webAccessRequests = [];

  DatabaseHelper._init();

  Future<Database> get database async {
    if (kIsWeb) {
      throw Exception("SQLite not supported on Web. Use in-memory list.");
    }
    if (_database != null) return _database!;
    _database = await _initDB('quiz.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // Upgrade to version 7 for status-based approval
    return await openDatabase(path,
        version: 7, onCreate: _createDB, onUpgrade: _onUpgrade);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const textTypeNullable = 'TEXT';

    await db.execute('''
CREATE TABLE questions ( 
  id $idType, 
  text $textType,
  options $textType,
  correctAnswerIndex $intType,
  difficulty $textType,
  explanation $textType,
  imagePath $textTypeNullable,
  solutionImagePath $textTypeNullable
);

CREATE TABLE leaderboard (
  id $idType,
  name $textType,
  points $intType,
  date $textType
);

CREATE TABLE settings (
  key TEXT PRIMARY KEY,
  value TEXT
);

CREATE TABLE logs (
  id $idType,
  student_name TEXT,
  year_group TEXT,
  log_type TEXT,
  timestamp TEXT
);

CREATE TABLE bug_reports (
  id $idType,
  student_name TEXT,
  screen_name TEXT,
  message TEXT,
  timestamp TEXT
);

CREATE TABLE access_requests (
  id $idType,
  student_name TEXT,
  year_group TEXT,
  status TEXT DEFAULT 'pending',
  timestamp TEXT
);
''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE questions ADD COLUMN imagePath TEXT');
    }
    if (oldVersion < 3) {
      await db
          .execute('ALTER TABLE questions ADD COLUMN solutionImagePath TEXT');
    }
    if (oldVersion < 4) {
      await db.execute('''
CREATE TABLE leaderboard (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  points INTEGER NOT NULL,
  date TEXT NOT NULL
)
''');
    }
    if (oldVersion < 5) {
      await db
          .execute('CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT)');
      await db.execute('''
CREATE TABLE logs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  student_name TEXT,
  year_group TEXT,
  log_type TEXT,
  timestamp TEXT
)
''');
    }
    if (oldVersion < 6) {
      await db.execute('''
CREATE TABLE bug_reports (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  student_name TEXT,
  screen_name TEXT,
  message TEXT,
  timestamp TEXT
)
''');
      await db.execute('''
CREATE TABLE access_requests (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  student_name TEXT,
  year_group TEXT,
  status TEXT DEFAULT 'pending',
  timestamp TEXT
)
''');
    }
    if (oldVersion < 7) {
      // Check if status column already exists (safeguard)
      try {
        await db.execute(
            'ALTER TABLE access_requests ADD COLUMN status TEXT DEFAULT "pending"');
      } catch (e) {
        // Column might already exist if something went wrong in a previous dev run
      }
    }
  }

  // --- SEEDING LOGIC ---
  Future<void> seedDatabaseIfNeeded() async {
    if (bundledQuestions.isEmpty) {
      return;
    }

    try {
      final List<Map<String, dynamic>> jsonList = bundledQuestions;

      if (kIsWeb) {
        if (_webQuestions.isEmpty) {
          print("Seeding Web Database...");
          for (var json in jsonList) {
            final q = Question.fromMap(json);
            final newQ = Question(
              text: q.text,
              options: q.options,
              correctAnswerIndex: q.correctAnswerIndex,
              difficulty: q.difficulty,
              explanation: q.explanation,
              imagePath: q.imagePath,
              solutionImagePath: q.solutionImagePath,
            );
            create(newQ);
          }
        }
      } else {
        final db = await instance.database;
        final count = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM questions'));

        if (count == 0) {
          print("Seeding Mobile Database...");
          final batch = db.batch();
          for (var json in jsonList) {
            final Map<String, dynamic> map = Map.from(json);
            map.remove('id');
            batch.insert('questions', map);
          }
          await batch.commit(noResult: true);
        }
      }
    } catch (e) {
      print("Error seeding database: $e");
    }
  }

  // --- CRUD OPERATIONS ---

  Future<int> create(Question question) async {
    if (kIsWeb) {
      int newId =
          (_webQuestions.isEmpty) ? 1 : (_webQuestions.last.id ?? 0) + 1;

      final newQuestion = Question(
        id: newId,
        text: question.text,
        options: question.options,
        correctAnswerIndex: question.correctAnswerIndex,
        difficulty: question.difficulty,
        explanation: question.explanation,
        imagePath: question.imagePath,
        solutionImagePath: question.solutionImagePath,
      );

      _webQuestions.add(newQuestion);
      return newId;
    }

    final db = await instance.database;
    return await db.insert('questions', question.toMap());
  }

  Future<Question> readQuestion(int id) async {
    if (kIsWeb) {
      return _webQuestions.firstWhere((q) => q.id == id,
          orElse: () => throw Exception('ID $id not found'));
    }

    final db = await instance.database;
    final maps = await db.query(
      'questions',
      columns: [
        'id',
        'text',
        'options',
        'correctAnswerIndex',
        'difficulty',
        'explanation',
        'imagePath',
        'solutionImagePath'
      ],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Question.fromMap(maps.first);
    } else {
      throw Exception('ID $id not found');
    }
  }

  Future<List<Question>> readAllQuestions() async {
    if (kIsWeb) {
      return List.from(_webQuestions);
    }

    final db = await instance.database;
    final result = await db.query('questions');
    return result.map((json) => Question.fromMap(json)).toList();
  }

  Future<List<Question>> readQuestionsByDifficulty(String difficulty) async {
    if (kIsWeb) {
      return _webQuestions.where((q) => q.difficulty == difficulty).toList();
    }

    final db = await instance.database;
    final result = await db.query(
      'questions',
      where: 'difficulty = ?',
      whereArgs: [difficulty],
    );
    return result.map((json) => Question.fromMap(json)).toList();
  }

  Future<int> update(Question question) async {
    if (kIsWeb) {
      final index = _webQuestions.indexWhere((q) => q.id == question.id);
      if (index != -1) {
        _webQuestions[index] = question;
        return 1;
      }
      return 0;
    }

    final db = await instance.database;
    return db.update(
      'questions',
      question.toMap(),
      where: 'id = ?',
      whereArgs: [question.id],
    );
  }

  Future<int> delete(int id) async {
    if (kIsWeb) {
      _webQuestions.removeWhere((q) => q.id == id);
      return 1;
    }

    final db = await instance.database;
    return await db.delete(
      'questions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    if (kIsWeb) return;
    final db = await instance.database;
    db.close();
  }

  // --- LEADERBOARD CRUD ---

  Future<int> createScore(Score score) async {
    if (kIsWeb) {
      int newId = (_webScores.isEmpty) ? 1 : (_webScores.last.id ?? 0) + 1;
      final newScore = Score(
        id: newId,
        name: score.name,
        points: score.points,
        date: score.date,
      );
      _webScores.add(newScore);
      return newId;
    }

    final db = await instance.database;
    return await db.insert('leaderboard', score.toMap());
  }

  Future<List<Score>> getLeaderboard() async {
    if (kIsWeb) {
      final sorted = List<Score>.from(_webScores);
      sorted.sort((a, b) => b.points.compareTo(a.points));
      return sorted.take(10).toList();
    }

    final db = await instance.database;
    final result =
        await db.query('leaderboard', orderBy: 'points DESC', limit: 10);
    return result.map((json) => Score.fromMap(json)).toList();
  }

  Future<List<Score>> getAllScores() async {
    if (kIsWeb) return List.from(_webScores);
    final db = await instance.database;
    final result = await db.query('leaderboard');
    return result.map((json) => Score.fromMap(json)).toList();
  }

  Future<void> mergeScores(List<Score> newScores) async {
    final existingScores = await getAllScores();

    for (var score in newScores) {
      // Avoid exact duplicates (same name, points, and date)
      bool exists = existingScores.any((s) =>
          s.name == score.name &&
          s.points == score.points &&
          s.date == score.date);

      if (!exists) {
        await createScore(score);
        existingScores.add(score); // Update local check list
      }
    }
  }

  // --- SETTINGS ---
  Future<void> saveSetting(String key, String value) async {
    if (kIsWeb) {
      _webSettings[key] = value;
      return;
    }
    final db = await instance.database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSetting(String key) async {
    if (kIsWeb) {
      return _webSettings[key];
    }
    final db = await instance.database;
    final maps = await db.query(
      'settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
    );
    if (maps.isNotEmpty) {
      return maps.first['value'] as String?;
    }
    return null;
  }

  // --- LOGS ---
  Future<void> logActivity({
    required String studentName,
    required String yearGroup,
    required String logType,
  }) async {
    final timestamp = DateTime.now().toString();
    if (kIsWeb) {
      _webLogs.add({
        'id': _webLogs.length + 1,
        'student_name': studentName,
        'year_group': yearGroup,
        'log_type': logType,
        'timestamp': timestamp,
      });
      return;
    }
    final db = await instance.database;
    await db.insert('logs', {
      'student_name': studentName,
      'year_group': yearGroup,
      'log_type': logType,
      'timestamp': timestamp,
    });
  }

  Future<List<Map<String, dynamic>>> getLogs() async {
    if (kIsWeb) {
      return List.from(_webLogs.reversed);
    }
    final db = await instance.database;
    return await db.query('logs', orderBy: 'timestamp DESC');
  }

  // --- BUG REPORTS ---
  Future<void> saveBugReport({
    required String studentName,
    required String screenName,
    required String message,
  }) async {
    final timestamp = DateTime.now().toString();
    if (kIsWeb) {
      _webBugReports.add({
        'id': _webBugReports.length + 1,
        'student_name': studentName,
        'screen_name': screenName,
        'message': message,
        'timestamp': timestamp,
      });
      return;
    }
    final db = await instance.database;
    await db.insert('bug_reports', {
      'student_name': studentName,
      'screen_name': screenName,
      'message': message,
      'timestamp': timestamp,
    });
  }

  Future<List<Map<String, dynamic>>> getBugReports() async {
    if (kIsWeb) return List.from(_webBugReports.reversed);
    final db = await instance.database;
    return await db.query('bug_reports', orderBy: 'timestamp DESC');
  }

  // --- ACCESS REQUESTS ---
  Future<void> saveAccessRequest({
    required String studentName,
    required String yearGroup,
  }) async {
    final timestamp = DateTime.now().toString();
    if (kIsWeb) {
      // Check if already exists to avoid duplicates
      final exists =
          _webAccessRequests.any((r) => r['student_name'] == studentName);
      if (exists) return;

      _webAccessRequests.add({
        'id': _webAccessRequests.length + 1,
        'student_name': studentName,
        'year_group': yearGroup,
        'status': 'pending',
        'timestamp': timestamp,
      });
      return;
    }
    final db = await instance.database;
    // Check if exists
    final List<Map<String, dynamic>> existing = await db.query(
      'access_requests',
      where: 'student_name = ?',
      whereArgs: [studentName],
    );
    if (existing.isNotEmpty) return;

    await db.insert('access_requests', {
      'student_name': studentName,
      'year_group': yearGroup,
      'status': 'pending',
      'timestamp': timestamp,
    });
  }

  Future<void> approveStudent(String studentName) async {
    if (kIsWeb) {
      final index = _webAccessRequests
          .indexWhere((r) => r['student_name'] == studentName);
      if (index != -1) {
        final existing = _webAccessRequests[index];
        _webAccessRequests[index] = {
          ...existing,
          'status': 'approved',
        };
      }
      return;
    }
    final db = await instance.database;
    await db.update(
      'access_requests',
      {'status': 'approved'},
      where: 'student_name = ?',
      whereArgs: [studentName],
    );
  }

  Future<bool> isStudentApproved(String studentName) async {
    if (kIsWeb) {
      return _webAccessRequests.any(
          (r) => r['student_name'] == studentName && r['status'] == 'approved');
    }
    final db = await instance.database;
    final res = await db.query(
      'access_requests',
      where: 'student_name = ? AND status = ?',
      whereArgs: [studentName, 'approved'],
    );
    return res.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> getAccessRequests() async {
    if (kIsWeb) return List.from(_webAccessRequests.reversed);
    final db = await instance.database;
    return await db.query('access_requests', orderBy: 'timestamp DESC');
  }

  Future<void> clearTable(String table) async {
    if (kIsWeb) {
      if (table == 'logs') _webLogs.clear();
      if (table == 'bug_reports') _webBugReports.clear();
      if (table == 'access_requests') _webAccessRequests.clear();
      return;
    }
    final db = await instance.database;
    await db.delete(table);
  }
}
