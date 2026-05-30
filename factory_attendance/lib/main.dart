import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'firebase_options.dart';
import 'core/themes/app_colors.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/attendance_provider.dart';
import 'data/repositories/attendance_repository_impl.dart';
import 'presentation/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider(AttendanceRepositoryImpl())),
      ],
      child: const FactoryAttendanceApp(),
    ),
  );
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
      home: const SplashScreen(),
    );
  }
}
