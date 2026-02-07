import 'dart:convert';

class Question {
  final int? id;
  final String text;
  final List<String> options;
  final int correctAnswerIndex;
  final String difficulty;
  final String explanation;
  final String? imagePath; // Stores Base64 string for Web or Path for Mobile
  final String?
      solutionImagePath; // Stores Base64 string for solution/explanation image

  Question({
    this.id,
    required this.text,
    required this.options,
    required this.correctAnswerIndex,
    required this.difficulty,
    required this.explanation,
    this.imagePath,
    this.solutionImagePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'options': jsonEncode(options),
      'correctAnswerIndex': correctAnswerIndex,
      'difficulty': difficulty,
      'explanation': explanation,
      'imagePath': imagePath,
      'solutionImagePath': solutionImagePath,
    };
  }

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      id: map['id'],
      text: map['text'],
      options: List<String>.from(jsonDecode(map['options'])),
      correctAnswerIndex: map['correctAnswerIndex'],
      difficulty: map['difficulty'],
      explanation: map['explanation'],
      imagePath: map['imagePath'],
      solutionImagePath: map['solutionImagePath'],
    );
  }
}
