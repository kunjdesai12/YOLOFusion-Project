import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:yolofusion/theme/app_theme.dart';
// import 'app_theme.dart';
import 'splash_screen.dart';

void main() {
  runApp(const YOLOFusionApp());
}

class YOLOFusionApp extends StatelessWidget {
  const YOLOFusionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YOLOFusion',
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
