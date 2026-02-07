import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pidayapp/models/question.dart';
import 'package:pidayapp/services/database_helper.dart';
import 'package:pidayapp/services/pi_background.dart';

class AddQuestionScreen extends StatefulWidget {
  const AddQuestionScreen({super.key});

  @override
  State<AddQuestionScreen> createState() => _AddQuestionScreenState();
}

class _AddQuestionScreenState extends State<AddQuestionScreen> {
  final _formKey = GlobalKey<FormState>();

  final _textController = TextEditingController();

  // Pre-filled controllers for options A through E
  final List<TextEditingController> _optionControllers = [
    TextEditingController(text: 'A'),
    TextEditingController(text: 'B'),
    TextEditingController(text: 'C'),
    TextEditingController(text: 'D'),
    TextEditingController(text: 'E'),
  ];

  final _explanationController = TextEditingController();

  int _correctAnswerIndex = 0;
  String _difficulty = 'Medium';
  String? _base64Image; // Question image
  String? _base64SolutionImage; // Solution image

  @override
  void dispose() {
    _textController.dispose();
    for (var c in _optionControllers) c.dispose();
    _explanationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage({required bool isSolution}) async {
    final ImagePicker picker = ImagePicker();
    // Balanced compression: High detail for students, but fast for FlutLab
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1000, // Higher resolution for crisp text
      maxHeight: 1000,
      imageQuality: 85, // Higher quality (standard for professional web photos)
    );

    if (image != null) {
      final Uint8List imageBytes = await image.readAsBytes();
      final String base64String = base64Encode(imageBytes);

      setState(() {
        if (isSolution) {
          _base64SolutionImage = base64String;
        } else {
          _base64Image = base64String;
        }
      });
    }
  }

  void _removeImage({required bool isSolution}) {
    setState(() {
      if (isSolution) {
        _base64SolutionImage = null;
      } else {
        _base64Image = null;
      }
    });
  }

  Future<void> _saveQuestion() async {
    if (_formKey.currentState!.validate()) {
      final options = _optionControllers.map((c) => c.text.trim()).toList();

      final question = Question(
        text: _textController.text.trim(),
        options: options,
        correctAnswerIndex: _correctAnswerIndex,
        difficulty: _difficulty,
        explanation: _explanationController.text.trim(),
        imagePath: _base64Image,
        solutionImagePath: _base64SolutionImage,
      );

      await DatabaseHelper.instance.create(question);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Question saved successfully!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Question')),
      body: PiBackground(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 40),
              children: [
                TextFormField(
                  controller: _textController,
                  decoration: const InputDecoration(
                    labelText: 'Question Text',
                    hintText: 'e.g. Solve the problem shown below:',
                  ),
                  maxLines: 2,
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Enter question text'
                      : null,
                ),
                const SizedBox(height: 20),

                // --- QUESTION IMAGE ---
                const Text('Question Image',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _pickImage(isSolution: false),
                      icon: const Icon(Icons.add_photo_alternate),
                      label: const Text('Pick Image'),
                    ),
                    const SizedBox(width: 16),
                    if (_base64Image != null)
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green),
                            const SizedBox(width: 8),
                            const Text('Attached'),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red),
                              onPressed: () => _removeImage(isSolution: false),
                              tooltip: 'Remove',
                            )
                          ],
                        ),
                      ),
                  ],
                ),
                if (_base64Image != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(base64Decode(_base64Image!),
                            fit: BoxFit.contain),
                      ),
                    ),
                  ),

                const SizedBox(height: 24),
                const Text('Set Correct Answer & Options',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...List.generate(5, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        Radio<int>(
                          value: index,
                          groupValue: _correctAnswerIndex,
                          onChanged: (val) {
                            setState(() {
                              _correctAnswerIndex = val!;
                            });
                          },
                        ),
                        Expanded(
                          child: TextFormField(
                            controller: _optionControllers[index],
                            decoration: InputDecoration(
                              labelText:
                                  'Option ${String.fromCharCode(65 + index)}',
                              border: const OutlineInputBorder(),
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                            ),
                            validator: (value) =>
                                (value == null || value.isEmpty)
                                    ? 'Required'
                                    : null,
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 24),
                const Text('Difficulty Level',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                      value: 'Easy',
                      label: const Text('Easy',
                          style: TextStyle(
                              color: Colors.red, fontWeight: FontWeight.bold)),
                    ),
                    ButtonSegment(
                      value: 'Medium',
                      label: const Text('Medium',
                          style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold)),
                    ),
                    ButtonSegment(
                      value: 'Hard',
                      label: const Text('Hard',
                          style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                  selected: {_difficulty},
                  showSelectedIcon: false,
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      _difficulty = newSelection.first;
                    });
                  },
                  style: ButtonStyle(
                    side: WidgetStateProperty.resolveWith<BorderSide>((states) {
                      if (states.contains(WidgetState.selected)) {
                        Color color = _difficulty == 'Easy'
                            ? Colors.red
                            : (_difficulty == 'Medium'
                                ? Colors.orange
                                : Colors.green);
                        return BorderSide(color: color, width: 2);
                      }
                      return const BorderSide(color: Colors.grey);
                    }),
                    backgroundColor:
                        WidgetStateProperty.resolveWith<Color>((states) {
                      if (states.contains(WidgetState.selected)) {
                        Color color = _difficulty == 'Easy'
                            ? (Colors.red[50] ?? Colors.red)
                            : (_difficulty == 'Medium'
                                ? (Colors.orange[50] ?? Colors.orange)
                                : (Colors.green[50] ?? Colors.green));
                        return color;
                      }
                      return Colors.transparent;
                    }),
                  ),
                ),

                const SizedBox(height: 24),
                // --- SOLUTION IMAGE ---
                const Text('Solution Image',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _pickImage(isSolution: true),
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('Pick Solution Image'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade100,
                          foregroundColor: Colors.amber.shade900),
                    ),
                    const SizedBox(width: 16),
                    if (_base64SolutionImage != null)
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.amber),
                            const SizedBox(width: 8),
                            const Text('Ready'),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red),
                              onPressed: () => _removeImage(isSolution: true),
                              tooltip: 'Remove',
                            )
                          ],
                        ),
                      ),
                  ],
                ),
                if (_base64SolutionImage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.amber.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(base64Decode(_base64SolutionImage!),
                            fit: BoxFit.contain),
                      ),
                    ),
                  ),

                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _saveQuestion,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF8E2157),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save Content',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
