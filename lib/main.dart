import 'package:flutter/material.dart';
import 'package:leancloud_storage/leancloud.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'pages/screens/auth/email_registration_page.dart';
import 'pages/screens/auth/email_login_page.dart';
import 'pages/screens/auth/email_forgot_password_page.dart';
import 'pages/screens/profile_setup/step1_basic_info_page.dart';
import 'pages/screens/profile_setup/step2_core_skills_page.dart';
import 'pages/screens/profile_setup/step3_cooperation_intent_page.dart';

void main() {
  // 初始化 LeanCloud
  LeanCloud.initialize(
    'kH93P959BRFqDK4JZZuAd14f-gzGzoHsz',
    'tUlZjd7liUyz9YvyT9AuF6IK',
    server: 'https://kh93p959.lc-cn-n1-shared.com',
    queryCache: LCQueryCache(),
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ShadApp.material(
      title: '良师益有',
      materialThemeBuilder: (context, theme) {
        return ThemeData(
          colorScheme: ColorScheme.light(
            primary: const Color(0xFF1677FF),
            onPrimary: Colors.white,
            secondary: theme.colorScheme.secondary,
            onSecondary: Colors.white,
            error: Colors.red,
            onError: Colors.white,
            background: Colors.white,
            onBackground: Colors.black87,
            surface: Colors.white,
            onSurface: Colors.black87,
          ),
          useMaterial3: true,
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF1677FF)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1677FF),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF1677FF),
            ),
          ),
        );
      },
      home: const EmailLoginPage(),
      routes: {
        '/login': (context) => const EmailLoginPage(),
        '/register': (context) => const EmailRegistrationPage(),
        '/home': (context) => const Scaffold(body: Center(child: Text('主页 - 待实现'))),
        '/profile-setup-step1': (context) => const ProfileSetupStep1Page(),
        '/profile-setup-step2': (context) => const ProfileSetupStep2Page(),
        '/profile-setup-step3': (context) => const ProfileSetupStep3Page(),
        '/forgot-password': (context) => const EmailForgotPasswordPage(),
      },
    );
  }
}
