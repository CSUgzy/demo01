import 'package:flutter/material.dart';
import 'package:leancloud_storage/leancloud.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'pages/screens/auth/email_registration_page.dart';
import 'pages/screens/auth/email_login_page.dart';
import 'pages/screens/auth/email_forgot_password_page.dart';
import 'pages/screens/profile_setup/step1_basic_info_page.dart';
import 'pages/screens/profile_setup/step2_core_skills_page.dart';
import 'pages/screens/profile_setup/step3_cooperation_intent_page.dart';
import 'widgets/main_navigation_wrapper.dart';
import 'pages/screens/postings/select_post_type_page.dart';
import 'services/notification_service.dart';
import 'pages/screens/splash/splash_screen_page.dart';

void main() {
  // 优先启动UI，然后在后台初始化其他服务
  runApp(const MyApp());
  
  // 在UI显示后进行初始化工作
  _initializeServices();
}

// 将初始化工作放到后台执行
Future<void> _initializeServices() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化 LeanCloud
  LeanCloud.initialize(
    'kH93P959BRFqDK4JZZuAd14f-gzGzoHsz',
    'tUlZjd7liUyz9YvyT9AuF6IK',
    server: 'https://kh93p959.lc-cn-n1-shared.com',
    queryCache: LCQueryCache(),
  );
  
  // 检查并初始化通知系统
  await _initializeNotificationSystem();
  
  // 初始化timeago中文支持
  timeago.setLocaleMessages('zh_CN', timeago.ZhCnMessages());
}

// 初始化通知系统
Future<void> _initializeNotificationSystem() async {
  try {
    // 检查用户是否已登录
    final currentUser = await LCUser.getCurrent();
    if (currentUser != null) {
      // 尝试初始化通知系统
      final notificationService = NotificationService();
      print("正在初始化通知系统...");
      await notificationService.getUnreadNotificationCount();
      print("通知系统初始化成功");
    }
  } catch (e) {
    print("通知系统初始化失败: $e");
    if (e is LCException) {
      print('LeanCloud error code: ${e.code}, message: ${e.message}');
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ShadApp.material(
      title: '良师益友',
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
      // 使用SplashScreenPage作为应用的初始界面
      home: const SplashScreenPage(),
      routes: {
        '/login': (context) => const EmailLoginPage(),
        '/register': (context) => const EmailRegistrationPage(),
        '/main': (context) => const MainNavigationWrapper(),
        '/home': (context) => const MainNavigationWrapper(),
        '/profile-setup-step1': (context) => const ProfileSetupStep1Page(),
        '/profile-setup-step2': (context) => const ProfileSetupStep2Page(),
        '/profile-setup-step3': (context) => const ProfileSetupStep3Page(),
        '/forgot-password': (context) => const EmailForgotPasswordPage(),
        '/select-post-type': (context) => const SelectPostTypePage(),
      },
    );
  }
  
  // 根据登录状态决定显示登录页面还是主导航页面，现在由SplashScreenPage负责
  Widget _buildHomeScreen() {
    // 检查用户是否已登录
    return FutureBuilder<LCUser?>(
      future: LCUser.getCurrent(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // 如果用户已登录，显示主导航页面；否则显示登录页面
        if (snapshot.hasData && snapshot.data != null) {
          return const MainNavigationWrapper();
        } else {
          return const EmailLoginPage();
        }
      },
    );
  }
}
