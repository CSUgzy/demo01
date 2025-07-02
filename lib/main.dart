import 'package:flutter/material.dart';
import 'package:leancloud_storage/leancloud.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
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
import 'pages/screens/legal/user_agreement_page.dart';
import 'pages/screens/legal/privacy_policy_page.dart';

// 全局错误日志文件路径
String? _errorLogPath;

// 写入错误日志到文件
Future<void> _writeErrorToFile(String error) async {
  try {
    if (_errorLogPath == null) {
      final directory = await getApplicationDocumentsDirectory();
      _errorLogPath = '${directory.path}/error_log.txt';
    }
    
    final file = File(_errorLogPath!);
    final timestamp = DateTime.now().toString();
    await file.writeAsString('[$timestamp] $error\n', mode: FileMode.append);
    print('错误已记录到: $_errorLogPath');
  } catch (e) {
    print('写入错误日志失败: $e');
  }
}

void main() async {
  // 确保Flutter引擎初始化完成
  WidgetsFlutterBinding.ensureInitialized();
  
  // 设置应用方向
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // 设置状态栏样式
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  
  // 设置全局错误处理
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    final errorMsg = 'Flutter错误: ${details.exception}, ${details.stack}';
    print(errorMsg);
    _writeErrorToFile(errorMsg);
  };
  
  // 捕获未处理的异步错误
  WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
    final errorMsg = '未捕获的异步错误: $error\n$stack';
    print(errorMsg);
    _writeErrorToFile(errorMsg);
    return true;
  };
  
  // 简化启动过程，直接运行应用，在应用内部初始化服务
  runApp(const MyApp());
}

// 初始化LeanCloud - 移到SplashScreen中进行
Future<void> initializeLeanCloud() async {
  try {
    // 初始化 LeanCloud
    LeanCloud.initialize(
      'kH93P959BRFqDK4JZZuAd14f-gzGzoHsz',
      'tUlZjd7liUyz9YvyT9AuF6IK',
      server: 'https://kh93p959.lc-cn-n1-shared.com',
      queryCache: LCQueryCache(),
    );
    print('LeanCloud初始化成功');
    return Future.value();
  } catch (e) {
    print('LeanCloud初始化失败: $e');
    // 不再重新抛出异常，允许应用继续运行
    return Future.value();
  }
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
        '/user-agreement': (context) => const UserAgreementPage(),
        '/privacy-policy': (context) => const PrivacyPolicyPage(),
      },
    );
  }
}
