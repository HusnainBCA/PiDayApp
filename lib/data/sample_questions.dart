import '../models/question.dart';

final List<Question> sampleQuestions2016 = [
  Question(
    text:
        "In general, the wholesale price of an item depends on the order size. The following graph shows this relation for a particular item. If c - a = 24, then what is c - b?",
    options: ["6", "8", "12", "14", "16"],
    correctAnswerIndex: 1, // "8" is at index 1
    difficulty: "Medium",
    explanation:
        "The graph shows a linear relationship. The slope is constant. Slope = (change in price) / (change in quantity). Between points (5, c) and (50, a): Slope = (a - c) / (50 - 5) = -24 / 45 = -8/15. Between (5, c) and (20, b): Slope = (b - c) / (20 - 5) = (b - c) / 15. Equating slopes: -8/15 = (b - c) / 15 => b - c = -8 => c - b = 8.",
  ),
  Question(
    text: "If x² < x, then what is the largest integer value of 2x + 7?",
    options: ["6", "7", "8", "9", "10"],
    correctAnswerIndex: 2, // "8" is at index 2
    difficulty: "Medium",
    explanation:
        "x² < x implies 0 < x < 1. Multiplying by 2 gives 0 < 2x < 2. Adding 7 gives 7 < 2x + 7 < 9. The integers in this range are strictly less than 9, so the largest integer is 8.",
  ),
  Question(
    text: "If (0.004x + 0.3) / (0.007x + 0.05) = 3/4, then x equals",
    options: ["100", "120", "210", "121.8", "141.7"],
    correctAnswerIndex: 2, // "210" is at index 2
    difficulty: "Medium",
    explanation:
        "Cross-multiply: 4 * (0.004x + 0.3) = 3 * (0.007x + 0.05). \n0.016x + 1.2 = 0.021x + 0.15. \n1.2 - 0.15 = 0.021x - 0.016x. \n1.05 = 0.005x. \nx = 1.05 / 0.005 = 210.",
  ),
];
