import 'package:flutter/material.dart';

import '../features/home/home_screen.dart';
import 'theme.dart';

class DayOneApp extends StatelessWidget {
  const DayOneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DayOne',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const HomeScreen(),
    );
  }
}
