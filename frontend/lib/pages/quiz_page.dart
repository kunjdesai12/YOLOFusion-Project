import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'theme/app_theme.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  _QuizPageState createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  int _currentQuestionIndex = 0;
  int _score = 0;
  final List<int?> _selectedAnswers = List.filled(6, null);
  bool _isSubmitted = false;

  final List<Question> _questions = [
    Question(
      question: 'What does YOLO stand for?',
      options: ['You Only Learn Once', 'You Only Look Once', 'Yield Optimal Learning Output'],
      correctAnswer: 1,
      explanation:
      'YOLO stands for "You Only Look Once," a single-stage object detection algorithm designed for real-time performance.',
    ),
    Question(
      question: 'Which YOLO version introduced multi-scale predictions?',
      options: ['YOLOv1', 'YOLOv3', 'YOLOv5'],
      correctAnswer: 1,
      explanation:
      'YOLOv3 introduced multi-scale predictions, allowing it to detect objects at different scales effectively.',
    ),
    Question(
      question: 'What is a key benefit of YOLO models?',
      options: ['High latency', 'Real-time performance', 'Low accuracy'],
      correctAnswer: 1,
      explanation:
      'YOLO models are known for their real-time performance due to the single-pass detection approach.',
    ),
    Question(
      question: 'Which component of YOLO extracts features from the input image?',
      options: ['Neck', 'Backbone', 'Head'],
      correctAnswer: 1,
      explanation:
      'The backbone (e.g., CSPDarknet) extracts features from the input image for further processing.',
    ),
    Question(
      question: 'What technique is used to reduce model size in YOLO optimization?',
      options: ['Pruning', 'Data Augmentation', 'Transfer Learning'],
      correctAnswer: 0,
      explanation:
      'Pruning reduces the model size by removing unnecessary weights, improving efficiency on edge devices.',
    ),
    Question(
      question: 'Which platform is commonly used for cloud deployment of YOLO?',
      options: ['NVIDIA Jetson', 'AWS', 'Raspberry Pi'],
      correctAnswer: 1,
      explanation:
      'AWS (Amazon Web Services) is a popular cloud platform for deploying scalable YOLO inference.',
    ),
  ];

  void _submitAnswer(int? selected) {
    if (selected != null && !_isSubmitted) {
      setState(() {
        _selectedAnswers[_currentQuestionIndex] = selected;
        _isSubmitted = true;
        if (selected == _questions[_currentQuestionIndex].correctAnswer) {
          _score++;
        }
      });
    }
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _isSubmitted = false;
      });
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Quiz Completed!', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          content: Text('Your final score: $_score / ${_questions.length}', style: GoogleFonts.poppins()),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
                setState(() {
                  _currentQuestionIndex = 0;
                  _score = 0;
                  _isSubmitted = false;
                  _selectedAnswers.fillRange(0, _selectedAnswers.length, null);
                });
              },
              child: Text('Close', style: GoogleFonts.poppins(color: AppTheme.primaryBlue)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = _questions[_currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'YOLO Quiz',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primaryBlue,
        elevation: 2,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick YOLO Quiz',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
                    style: GoogleFonts.poppins(fontSize: 16, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Score: $_score',
                    style: GoogleFonts.poppins(fontSize: 16, color: Colors.green.shade700),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    question.question,
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(question.options.length, (index) {
                    return RadioListTile<int>(
                      value: index,
                      groupValue: _selectedAnswers[_currentQuestionIndex],
                      activeColor: AppTheme.primaryBlue,
                      onChanged: _isSubmitted
                          ? null
                          : (value) {
                        setState(() {
                          _selectedAnswers[_currentQuestionIndex] = value;
                        });
                      },
                      title: Text(
                        question.options[index],
                        style: GoogleFonts.poppins(fontSize: 16),
                      ),
                    );
                  }),
                  if (_isSubmitted) ...[
                    const SizedBox(height: 16),
                    Text(
                      _selectedAnswers[_currentQuestionIndex] == question.correctAnswer
                          ? '✅ Correct!'
                          : '❌ Incorrect!',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _selectedAnswers[_currentQuestionIndex] == question.correctAnswer
                            ? Colors.green
                            : AppTheme.errorColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_selectedAnswers[_currentQuestionIndex] != question.correctAnswer)
                      Text(
                        'Correct Answer: ${question.options[question.correctAnswer]}',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.errorColor,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      question.explanation,
                      style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textMuted),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
              color: Colors.white,
            ),
            child: ElevatedButton(
              onPressed: _isSubmitted
                  ? _nextQuestion
                  : (_selectedAnswers[_currentQuestionIndex] != null
                  ? () => _submitAnswer(_selectedAnswers[_currentQuestionIndex])
                  : null),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                _isSubmitted
                    ? (_currentQuestionIndex == _questions.length - 1 ? 'Finish' : 'Next')
                    : 'Submit',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Question {
  final String question;
  final List<String> options;
  final int correctAnswer;
  final String explanation;

  Question({
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
  });
}
