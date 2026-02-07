import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pidayapp/models/question.dart';
import 'package:pidayapp/models/score.dart';
import 'package:pidayapp/screens/leaderboard_screen.dart'; // Added import
import 'package:pidayapp/services/database_helper.dart';
import 'package:pidayapp/services/pi_background.dart';
import 'package:pidayapp/services/bug_report_dialog.dart';

class QuizScreen extends StatefulWidget {
  final List<Question> questions;
  final String studentName;
  final String yearGroup;
  final String difficulty;

  const QuizScreen({
    super.key,
    required this.questions,
    required this.studentName,
    required this.yearGroup,
    required this.difficulty,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentIndex = 0;
  bool _isAnswered = false;
  int? _selectedOptionIndex;
  bool _showExplanation = false;
  int _score = 0;
  int _totalPoints = 0;
  Uint8List? _questionImageBytes;
  Uint8List? _solutionImageBytes;

  @override
  void initState() {
    super.initState();
    _decodeImages();
  }

  void _decodeImages() {
    final question = widget.questions[_currentIndex];
    if (question.imagePath != null && question.imagePath!.isNotEmpty) {
      _questionImageBytes = base64Decode(question.imagePath!);
    } else {
      _questionImageBytes = null;
    }

    if (question.solutionImagePath != null &&
        question.solutionImagePath!.isNotEmpty) {
      _solutionImageBytes = base64Decode(question.solutionImagePath!);
    } else {
      _solutionImageBytes = null;
    }
  }

  void _onOptionTap(int optionIndex) {
    if (_isAnswered) return;
    setState(() {
      _selectedOptionIndex = optionIndex;
    });
  }

  void _submitAnswer() {
    if (_isAnswered || _selectedOptionIndex == null) return;

    setState(() {
      _isAnswered = true;
      if (_selectedOptionIndex ==
          widget.questions[_currentIndex].correctAnswerIndex) {
        _score++;

        // Weighted scoring: Easy=1, Medium=2, Hard=3
        final difficulty =
            widget.questions[_currentIndex].difficulty.toLowerCase();
        if (difficulty == 'easy') {
          _totalPoints += 1;
        } else if (difficulty == 'medium') {
          _totalPoints += 2;
        } else if (difficulty == 'hard') {
          _totalPoints += 3;
        } else {
          _totalPoints += 1; // Default
        }
      }
    });
  }

  void _showImageZoom(String base64Image) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                color: Colors.black.withOpacity(0.8),
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4,
              child: Image.memory(
                base64Decode(base64Image),
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: 20,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _nextQuestion() {
    setState(() {
      if (_currentIndex < widget.questions.length - 1) {
        _currentIndex++;
        _isAnswered = false;
        _selectedOptionIndex = null;
        _showExplanation = false;
        _decodeImages(); // Decode for new question
      } else {
        // Save score before showing dialog
        final newScore = Score(
          name: widget.studentName,
          points: _totalPoints,
          date: DateTime.now().toString(),
        );
        DatabaseHelper.instance.createScore(newScore);

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text('Quiz Completed!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Correct Answers: $_score / ${widget.questions.length}'),
                Text('Total Points: $_totalPoints',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.deepPurple)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const LeaderboardScreen()),
                  );
                },
                child: const Text('View Leaderboard',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('Close'),
              )
            ],
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.questions[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('Question ${_currentIndex + 1}/${widget.questions.length}'),
        actions: [
          IconButton(
            onPressed: () => BugReportDialog.show(
              context,
              screenName: 'Quiz Screen - Question ${_currentIndex + 1}',
              studentName: widget.studentName,
            ),
            icon: const Icon(Icons.bug_report),
            tooltip: 'Report a Bug',
          ),
        ],
      ),
      body: PiBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Question Number
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'Question ${_currentIndex + 1}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8E2157),
                  ),
                ),
              ),

              // Difficulty & Student Display
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8E2157).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFF8E2157).withOpacity(0.3)),
                      ),
                      child: RichText(
                        text: TextSpan(
                          text: 'Difficulty: ',
                          style: const TextStyle(
                              color: Color(0xFF8E2157),
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                          children: [
                            TextSpan(
                              text:
                                  '${question.difficulty[0].toUpperCase()}${question.difficulty.substring(1).toLowerCase()}',
                              style: TextStyle(
                                color:
                                    question.difficulty.toLowerCase() == 'easy'
                                        ? Colors.red
                                        : (question.difficulty.toLowerCase() ==
                                                'medium'
                                            ? Colors.orange
                                            : Colors.green),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Text(
                      '${widget.studentName} (${widget.yearGroup})',
                      style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),

              // Question Text (moved above image)
              Text(
                question.text,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Question Image
              if (_questionImageBytes != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: GestureDetector(
                    onTap: () => _showImageZoom(
                        widget.questions[_currentIndex].imagePath ?? ""),
                    child: Container(
                      height: 180, // Fixed height to prevent jumping
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Center(
                              child: Image.memory(
                                _questionImageBytes!,
                                fit: BoxFit.contain,
                                width: double.infinity,
                                gaplessPlayback: true, // Prevent flicker
                              ),
                            ),
                          ),
                          const Positioned(
                            bottom: 4,
                            right: 4,
                            child: CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.black54,
                              child: Icon(Icons.zoom_in,
                                  color: Colors.white, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // Options Grid (Horizontal Line style)
              _buildHorizontalOptions(question),

              const SizedBox(height: 12),

              if (!_isAnswered)
                Container(
                  height: 55, // Fixed height to prevent jumping
                  child: ElevatedButton(
                    onPressed:
                        _selectedOptionIndex != null ? _submitAnswer : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF8E2157),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      disabledBackgroundColor: Colors.grey.shade300,
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        inherit: true, // Force consistency
                      ),
                    ),
                    child: const Text('Submit Answer'),
                  ),
                ),

              // Solution Section
              if (_isAnswered) ...[
                if (!_showExplanation)
                  Container(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => setState(() => _showExplanation = true),
                      icon: const Icon(Icons.lightbulb),
                      label: const Text('View Solution Image'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade600,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(
                            fontWeight: FontWeight.bold, inherit: true),
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: Colors.amber.shade300, width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.auto_awesome,
                                color: Colors.amber, size: 20),
                            SizedBox(width: 8),
                            Text('Solution',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_solutionImageBytes != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: GestureDetector(
                              onTap: () => _showImageZoom(
                                  question.solutionImagePath ?? ""),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.memory(
                                      _solutionImageBytes!,
                                      fit: BoxFit.contain,
                                      width: double.infinity,
                                      gaplessPlayback: true,
                                    ),
                                  ),
                                  const Positioned(
                                    bottom: 8,
                                    right: 8,
                                    child: CircleAvatar(
                                      radius: 16,
                                      backgroundColor: Colors.black54,
                                      child: Icon(Icons.zoom_in,
                                          color: Colors.white, size: 20),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (question.explanation.isNotEmpty)
                          Text(question.explanation,
                              style: const TextStyle(fontSize: 16)),
                        if ((question.solutionImagePath == null ||
                                question.solutionImagePath!.isEmpty) &&
                            question.explanation.isEmpty)
                          const Text(
                              'No detailed explanation provided for this question.',
                              style: TextStyle(fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                Container(
                  height: 55, // Fixed height to prevent jumping
                  child: ElevatedButton(
                    onPressed: _nextQuestion,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF5C0632),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        inherit: true,
                      ),
                    ),
                    child: Text(_currentIndex == widget.questions.length - 1
                        ? 'Finish Quiz'
                        : 'Next Question'),
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalOptions(Question question) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          question.options.length,
          (i) => Container(
            width: question.options.length <= 4
                ? (MediaQuery.of(context).size.width - 48) /
                    question.options.length
                : 70,
            child: _buildOptionTile(question, i),
          ),
        ).toList(),
      ),
    );
  }

  Widget _buildOptionTile(Question question, int index) {
    Color cardColor = Colors.white;
    Color textColor = Colors.black;
    bool isSelected = _selectedOptionIndex == index;

    if (_isAnswered) {
      if (index == question.correctAnswerIndex) {
        cardColor = Colors.green.shade50;
        textColor = Colors.green.shade900;
      } else if (isSelected) {
        cardColor = Colors.red.shade50;
        textColor = Colors.red.shade900;
      }
    } else if (isSelected) {
      cardColor = const Color(0xFF8E2157).withOpacity(0.05);
      textColor = const Color(0xFF8E2157);
    }

    final letter = String.fromCharCode(65 + index);
    final optionText = question.options[index];
    final bool shouldHideText = optionText.trim().toUpperCase() == letter;

    return AspectRatio(
      aspectRatio: 1.0, // Make it square
      child: Card(
        color: cardColor,
        elevation: isSelected || _isAnswered ? 0 : 2,
        margin: const EdgeInsets.all(4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: _isAnswered
                ? (index == question.correctAnswerIndex
                    ? Colors.green
                    : (isSelected ? Colors.red : Colors.transparent))
                : (isSelected ? const Color(0xFF8E2157) : Colors.grey.shade300),
            width: 2,
          ),
        ),
        child: InkWell(
          onTap: () => _onOptionTap(index),
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: _isAnswered
                    ? (index == question.correctAnswerIndex
                        ? Colors.green
                        : (isSelected ? Colors.red : Colors.grey.shade300))
                    : (isSelected
                        ? const Color(0xFF8E2157)
                        : Colors.grey.shade200),
                child: Text(
                  letter,
                  style: TextStyle(
                    fontSize: 14,
                    color: (isSelected ||
                            (_isAnswered &&
                                index == question.correctAnswerIndex))
                        ? Colors.white
                        : Colors.black,
                    fontWeight: FontWeight.bold,
                    inherit: true,
                  ),
                ),
              ),
              if (!shouldHideText) ...[
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(optionText,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 12,
                        fontWeight:
                            index == question.correctAnswerIndex && _isAnswered
                                ? FontWeight.bold
                                : FontWeight.normal,
                        inherit: true,
                      )),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
