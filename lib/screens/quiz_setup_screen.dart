import 'package:flutter/material.dart';
import 'package:pidayapp/models/question.dart';
import 'package:pidayapp/services/database_helper.dart';
import 'package:pidayapp/screens/quiz_screen.dart';
import 'package:pidayapp/services/pi_background.dart';

class QuizSetupScreen extends StatefulWidget {
  const QuizSetupScreen({super.key});

  @override
  State<QuizSetupScreen> createState() => _QuizSetupScreenState();
}

class _QuizSetupScreenState extends State<QuizSetupScreen> {
  final TextEditingController _nameController = TextEditingController();
  String _selectedYearGroup = 'Year 9';
  String _selectedDifficulty = 'Medium';
  bool _isLocked = false;
  bool _isRandom = false;

  final List<String> _difficulties = ['Easy', 'Medium', 'Hard'];
  final List<String> _yearGroups = [
    'Year 9',
    'Year 10',
    'Year 11',
    'Year 12',
    'Year 13'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        setState(() {
          _nameController.text = args['name'] ?? '';
          _selectedYearGroup = args['yearGroup'] ?? 'Year 9';
          _isLocked = true;
        });
      } else if (args is String) {
        // Fallback for old navigation if any
        _nameController.text = args;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _startQuiz() async {
    List<Question> questions;
    if (_isRandom) {
      questions = await DatabaseHelper.instance.readAllQuestions();
      questions.shuffle();
    } else {
      questions = await DatabaseHelper.instance
          .readQuestionsByDifficulty(_selectedDifficulty);
    }

    if (!mounted) return;

    if (questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No questions found for this selection.')),
      );
      return;
    }

    DatabaseHelper.instance.logActivity(
      studentName: _nameController.text.trim().isEmpty
          ? 'Guest'
          : _nameController.text.trim(),
      yearGroup: _selectedYearGroup,
      logType: 'Quiz Start (${_isRandom ? "Random" : _selectedDifficulty})',
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizScreen(
          questions: questions,
          studentName: _nameController.text.trim().isEmpty
              ? 'Guest'
              : _nameController.text.trim(),
          yearGroup: _selectedYearGroup,
          difficulty: _isRandom ? 'Random' : _selectedDifficulty,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pi Day Setup')),
      body: PiBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Student Information',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8E2157)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                readOnly: _isLocked,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  labelStyle: const TextStyle(color: Color(0xFF8E2157)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFF8E2157), width: 2),
                  ),
                  prefixIcon:
                      const Icon(Icons.person, color: Color(0xFF8E2157)),
                  hintText: _isLocked ? 'Locked by Teacher' : 'Enter your name',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedYearGroup,
                onChanged: _isLocked
                    ? null
                    : (newValue) {
                        setState(() {
                          _selectedYearGroup = newValue!;
                        });
                      },
                decoration: InputDecoration(
                  labelText: 'Year Group',
                  labelStyle: const TextStyle(color: Color(0xFF8E2157)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFF8E2157), width: 2),
                  ),
                  prefixIcon: const Icon(Icons.group, color: Color(0xFF8E2157)),
                  helperText: _isLocked ? 'Verified by Teacher' : null,
                ),
                items: _yearGroups.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              const Text(
                'Choose Difficulty',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8E2157)),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildDifficultyButton('Easy', Colors.red)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _buildDifficultyButton('Medium', Colors.orange)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildDifficultyButton('Hard', Colors.green)),
                ],
              ),
              const SizedBox(height: 16),
              _RainbowButton(
                isSelected: _isRandom,
                onTap: () => setState(() => _isRandom = true),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: _startQuiz,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                  backgroundColor: const Color(0xFF8E2157),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                ),
                child: const Text('Start Quiz'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyButton(String difficulty, Color color) {
    final isSelected = !_isRandom && _selectedDifficulty == difficulty;
    return GestureDetector(
      onTap: () => setState(() {
        _isRandom = false;
        _selectedDifficulty = difficulty;
      }),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 2),
        ),
        alignment: Alignment.center,
        child: Text(
          difficulty,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class _RainbowButton extends StatefulWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const _RainbowButton({required this.isSelected, required this.onTap});

  @override
  State<_RainbowButton> createState() => _RainbowButtonState();
}

class _RainbowButtonState extends State<_RainbowButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 4))
          ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final gradient = SweepGradient(
            colors: widget.isSelected
                ? [
                    Colors.red.shade900,
                    Colors.orange.shade900,
                    Colors.yellow.shade900,
                    Colors.green.shade900,
                    Colors.blue.shade900,
                    Colors.indigo.shade900,
                    Colors.purple.shade900,
                    Colors.red.shade900
                  ]
                : [
                    Colors.red.shade50,
                    Colors.orange.shade50,
                    Colors.yellow.shade50,
                    Colors.green.shade50,
                    Colors.blue.shade50,
                    Colors.indigo.shade50,
                    Colors.purple.shade50,
                    Colors.red.shade50
                  ],
            stops: const [0.0, 0.14, 0.28, 0.42, 0.56, 0.7, 0.84, 1.0],
            transform:
                GradientRotation(_controller.value * 2 * 3.141592653589793),
          );

          return Container(
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: gradient,
              boxShadow: [
                BoxShadow(
                  color: widget.isSelected
                      ? Colors.deepPurple.withOpacity(0.5)
                      : Colors.orange.withOpacity(0.15),
                  blurRadius: widget.isSelected ? 20 : 8,
                  spreadRadius: widget.isSelected ? 3 : 1,
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CustomPaint(
                painter: _RainbowPainter(_controller.value, widget.isSelected),
                child: Center(
                  child: Text(
                    'Random Difficulty',
                    style: TextStyle(
                      color: widget.isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 0.8,
                      shadows: [
                        if (widget.isSelected)
                          const Shadow(
                              color: Colors.black,
                              blurRadius: 8,
                              offset: Offset(0, 1))
                        else
                          Shadow(
                              color: Colors.white.withOpacity(0.8),
                              blurRadius: 4),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RainbowPainter extends CustomPainter {
  final double animationValue;
  final bool isSelected;

  _RainbowPainter(this.animationValue, this.isSelected);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));

    final gradient = SweepGradient(
      colors: const [
        Colors.red,
        Colors.orange,
        Colors.yellow,
        Colors.green,
        Colors.blue,
        Colors.indigo,
        Colors.purple,
        Colors.red,
      ],
      stops: const [0.0, 0.14, 0.28, 0.42, 0.56, 0.7, 0.84, 1.0],
      transform: GradientRotation(animationValue * 2 * 3.141592653589793),
    );

    if (!isSelected) {
      // Vibrant internal rainbow for non-selected state
      final paint = Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawRRect(rrect.deflate(1.5), paint);

      // Sharp outer rainbow border
      final borderPaint = Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawRRect(rrect, borderPaint);
    } else {
      // Extremely vibrant glowing thick border for selected state
      final glowPaint = Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 12);

      canvas.drawRRect(rrect, glowPaint);

      final borderPaint = Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5;

      canvas.drawRRect(rrect, borderPaint);

      // Additional internal rim light
      final innerPaint = Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawRRect(rrect.deflate(2), innerPaint);
    }
  }

  @override
  bool shouldRepaint(_RainbowPainter oldDelegate) => true;
}
