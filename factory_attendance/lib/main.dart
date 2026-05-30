import 'package:flutter/material.dart';
import 'core/themes/app_colors.dart';

void main() {
  runApp(const FactoryAttendanceApp());
}

class FactoryAttendanceApp extends StatelessWidget {
  const FactoryAttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Factory Attendance',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.deepNavy),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('Factory Attendance HRIS'),
        ),
      ),
    );
  }
}
