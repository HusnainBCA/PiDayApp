import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pidayapp/services/database_helper.dart';
import 'package:pidayapp/services/pi_background.dart';
import 'package:pidayapp/data/custom_assets.dart';

class AuthorizationScreen extends StatefulWidget {
  const AuthorizationScreen({super.key});

  @override
  State<AuthorizationScreen> createState() => _AuthorizationScreenState();
}

class _AuthorizationScreenState extends State<AuthorizationScreen> {
  final TextEditingController _nameController = TextEditingController();
  String? _selectedYearGroup; // Made nullable to force selection
  final List<String> _yearGroups = [
    'Year 9',
    'Year 10',
    'Year 11',
    'Year 12',
    'Year 13'
  ];
  bool _isChecking = false;
  bool _isStudentMode = true;
  String? _statusMessage;

  final PageController _pageController = PageController();
  Timer? _carouselTimer;

  @override
  void initState() {
    super.initState();
    _startCarouselTimer();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _carouselTimer?.cancel();
    _nameController.dispose();
    super.dispose();
  }

  void _startCarouselTimer() {
    _carouselTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients) {
        int nextPage = (_pageController.page?.toInt() ?? 0) + 1;
        if (nextPage >= 2) nextPage = 0; // Assuming 2 images

        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutQuart,
        );
      }
    });
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacementNamed('/quiz-setup', arguments: {
      'name': _nameController.text.trim(),
      'yearGroup': _selectedYearGroup!,
    });
  }

  Future<void> _checkStatus() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _statusMessage = "Please enter your name.";
      });
      return;
    }

    if (_selectedYearGroup == null) {
      setState(() {
        _statusMessage = "Please select your year group.";
      });
      return;
    }

    setState(() {
      _isChecking = true;
      _statusMessage = null;
    });

    try {
      final isApproved = await DatabaseHelper.instance.isStudentApproved(name);
      if (isApproved) {
        if (mounted) _navigateToHome();
      } else {
        final requests = await DatabaseHelper.instance.getAccessRequests();
        final hasRequest = requests.any((r) => r['student_name'] == name);

        setState(() {
          _statusMessage = hasRequest
              ? "Your request is still PENDING.\nPlease ask Mr Afsar to approve you."
              : "No request found for this name.\nPlease click 'Request Access' below.";
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking status: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _requestAccess() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _statusMessage = "Please enter your name.";
      });
      return;
    }

    if (_selectedYearGroup == null) {
      setState(() {
        _statusMessage = "Please select your year group.";
      });
      return;
    }

    try {
      await DatabaseHelper.instance.saveAccessRequest(
        studentName: name,
        yearGroup: _selectedYearGroup!,
      );

      setState(() {
        _statusMessage =
            "Request SENT!\nNow ask Mr Afsar to 'Approve' you in the Teacher Panel.";
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Request Sent!'),
            content: const Text(
              'Your request has been sent to the teacher panel. Once Mr Afsar approves you, you will be able to access the quiz.',
              textAlign: TextAlign.center,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save request. Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PiBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildWelcomeCarousel(),
                const SizedBox(height: 32),

                // Mode Toggle Boxes
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isStudentMode = true),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: _isStudentMode
                                ? const Color(0xFF8E2157)
                                : Colors.white.withOpacity(0.5),
                            borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(15),
                                bottomLeft: Radius.circular(15)),
                            border: Border.all(color: const Color(0xFF8E2157)),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.school,
                                  color: _isStudentMode
                                      ? Colors.white
                                      : const Color(0xFF8E2157)),
                              const SizedBox(height: 4),
                              Text(
                                'STUDENT',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _isStudentMode
                                      ? Colors.white
                                      : const Color(0xFF8E2157),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isStudentMode = false),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: !_isStudentMode
                                ? const Color(0xFF8E2157)
                                : Colors.white.withOpacity(0.5),
                            borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(15),
                                bottomRight: Radius.circular(15)),
                            border: Border.all(color: const Color(0xFF8E2157)),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.admin_panel_settings,
                                  color: !_isStudentMode
                                      ? Colors.white
                                      : const Color(0xFF8E2157)),
                              const SizedBox(height: 4),
                              Text(
                                'TEACHER',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: !_isStudentMode
                                      ? Colors.white
                                      : const Color(0xFF8E2157),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Dynamic Content Box
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child:
                      _isStudentMode ? _buildStudentBox() : _buildTeacherBox(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCarousel() {
    final List<String> images = [
      CustomAssets.piDigitsBase64,
      CustomAssets.piPoemBase64,
    ];

    return Column(
      children: [
        const Text(
          'Welcome to the Pi Day App!',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF8E2157),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _pageController,
            itemCount: images.length,
            itemBuilder: (context, index) {
              final imgStr = images[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 5)),
                  ],
                  border: Border.all(
                      color: const Color(0xFF8E2157).withOpacity(0.2)),
                ),
                clipBehavior: Clip.antiAlias,
                child: imgStr.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                                index == 0 ? Icons.numbers : Icons.auto_stories,
                                size: 50,
                                color:
                                    const Color(0xFF8E2157).withOpacity(0.5)),
                            const SizedBox(height: 10),
                            Text(
                                index == 0
                                    ? 'Pi Digits'
                                    : 'Martin Gardner Quote',
                                style: TextStyle(
                                    color: const Color(0xFF8E2157)
                                        .withOpacity(0.5))),
                          ],
                        ),
                      )
                    : Image.memory(base64Decode(imgStr), fit: BoxFit.contain),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(images.length, (index) {
            return Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF8E2157).withOpacity(0.3),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildStudentBox() {
    return Container(
      key: const ValueKey('student_box'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Select your Year and enter your name.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'e.g. John Doe',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                  onChanged: (_) => setState(() => _statusMessage = null),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  value: _selectedYearGroup,
                  hint: const Text('Select'),
                  decoration: InputDecoration(
                    labelText: 'Year',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15)),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
                    isDense: true,
                  ),
                  items: _yearGroups.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedYearGroup = newValue!;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_statusMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text(
                _statusMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Color(0xFF8E2157),
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isChecking ? null : _checkStatus,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8E2157),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                    ),
                    child: _isChecking
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Check Status',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _requestAccess,
                    icon: const Icon(Icons.send, size: 18),
                    label: const Text('Request Access',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF8E2157),
                      side:
                          const BorderSide(color: Color(0xFF8E2157), width: 2),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherBox() {
    return Container(
      key: const ValueKey('teacher_box'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.verified_user, size: 40, color: Color(0xFF8E2157)),
          const SizedBox(height: 12),
          const Text(
            'Teacher Access',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Login to manage questions, view student requests, and control security.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pushNamed('/'),
              icon: const Icon(Icons.login),
              label: const Text('Open Grand Dashboard'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8E2157),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                textStyle:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
