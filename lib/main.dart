import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'services/phone_auth_service.dart';
import 'services/user_profile_service.dart';
import 'screens/rastros_screens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const RastrosApp());
}

class RastrosApp extends StatelessWidget {
  const RastrosApp({super.key, this.authService, this.profileService});

  final PhoneAuthService? authService;
  final UserProfileService? profileService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rastros',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: RastrosColors.cream,
        colorScheme: ColorScheme.fromSeed(
          seedColor: RastrosColors.blue,
          surface: RastrosColors.cream,
        ),
        fontFamily: 'Roboto',
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: RastrosColors.navy),
          bodyMedium: TextStyle(color: RastrosColors.navy),
        ),
      ),
      home: LoginScreen(
        authService: authService,
        profileService: profileService,
      ),
    );
  }
}
