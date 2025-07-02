import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:leancloud_storage/leancloud.dart';
import 'package:timeago/timeago.dart' as timeago;
// 导入main.dart中的initializeLeanCloud函数
import '../.././../main.dart';
// 这里需要添加你的登录页和主页的导入路径
// import 'package:demo01/pages/auth/email_login_page.dart';
// import 'package:demo01/pages/main/main_navigation_wrapper.dart';

// 错误日志文件路径
String? _splashErrorLogPath;

// 写入错误日志到文件
Future<void> _writeErrorToFile(String error) async {
  try {
    if (_splashErrorLogPath == null) {
      final directory = await getApplicationDocumentsDirectory();
      _splashErrorLogPath = '${directory.path}/splash_error_log.txt';
    }
    
    final file = File(_splashErrorLogPath!);
    final timestamp = DateTime.now().toString();
    await file.writeAsString('[$timestamp] $error\n', mode: FileMode.append);
    print('启动页错误已记录到: $_splashErrorLogPath');
  } catch (e) {
    print('写入启动页错误日志失败: $e');
  }
}

class SplashScreenPage extends StatefulWidget {
  const SplashScreenPage({Key? key}) : super(key: key);

  @override
  State<SplashScreenPage> createState() => _SplashScreenPageState();
}

class _SplashScreenPageState extends State<SplashScreenPage> with SingleTickerProviderStateMixin {
  // 添加动画控制器
  late AnimationController _controller;
  late Animation<double> _fadeInAnimation;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    
    // 记录启动日志
    _writeErrorToFile('启动页初始化');
    
    // 配置动画
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn)
    );
    
    // 启动动画
    _controller.forward();
    
    // 初始化服务
    _initializeServices();
  }
  
  Future<void> _initializeServices() async {
    try {
      _writeErrorToFile('开始初始化服务');
      
      // 初始化LeanCloud
      await initializeLeanCloud();
      
      // 初始化timeago中文支持
      timeago.setLocaleMessages('zh_CN', timeago.ZhCnMessages());
      
      _writeErrorToFile('服务初始化完成');
      
      // 延迟1秒后检查登录状态并导航
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        _checkLoginStatusAndNavigate();
      }
    } catch (e, stack) {
      final errorMsg = '服务初始化错误: $e\n$stack';
      print(errorMsg);
      _writeErrorToFile(errorMsg);
      
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = '应用初始化失败，请重试';
          _isInitializing = false;
        });
      }
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkLoginStatusAndNavigate() async {
    if (_isInitializing) {
      setState(() {
        _isInitializing = false;
      });
    }
    
    try {
      _writeErrorToFile('开始检查登录状态');
      
      // 检查当前用户登录状态
      LCUser? currentUser = await LCUser.getCurrent();
      _writeErrorToFile('登录状态检查结果: ${currentUser != null ? '已登录' : '未登录'}');

      if (!mounted) return; // 检查页面是否还存在，防止异步错误

      if (currentUser != null) {
        // 如果用户已登录，跳转到主页
        _writeErrorToFile('导航到主页');
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        // 如果用户未登录，跳转到登录页
        _writeErrorToFile('导航到登录页');
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e, stack) {
      final errorMsg = '启动页导航错误: $e\n$stack';
      print(errorMsg);
      _writeErrorToFile(errorMsg);
      
      if (mounted) {
        // 添加更详细的错误日志
        if (e is LCException) {
          _writeErrorToFile('LeanCloud错误代码: ${e.code}, 消息: ${e.message}');
        }
        
        setState(() {
          _hasError = true;
          _errorMessage = '应用加载失败，请重试';
        });
        
        // 减少等待时间，2秒后自动尝试跳转到登录页
        Timer(const Duration(seconds: 2), () {
          if (mounted) {
            _writeErrorToFile('错误后自动导航到登录页');
            Navigator.of(context).pushReplacementNamed('/login');
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 获取屏幕尺寸
    final Size size = MediaQuery.of(context).size;
    
    return Scaffold(
      body: Container(
        color: Colors.white,
        width: size.width,
        height: size.height,
        child: FadeTransition(
          opacity: _fadeInAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo带弹性缩放
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0.8, end: 1.0),
                curve: Curves.elasticOut,
                duration: const Duration(milliseconds: 1800),
                builder: (context, double value, child) {
                  return Transform.scale(
                    scale: value,
                    child: child,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Image.asset(
                    'assets/icons/logo-k.png',
                    width: 120,
                    height: 120,
                    errorBuilder: (context, error, stackTrace) {
                      final errorMsg = 'Logo加载错误: $error\n$stackTrace';
                      print(errorMsg);
                      _writeErrorToFile(errorMsg);
                      return Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.school,
                          size: 60,
                          color: Colors.blue,
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              // App名称
              const SizedBox(height: 24),
              const Text(
                "良师益友",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              
              // App Slogan (口号)
              const SizedBox(height: 12),
              const Text(
                "连接项目与人才，让天下没有难创的业",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              
              // 加载指示器或错误信息
              const SizedBox(height: 40),
              _hasError 
                ? Column(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 40,
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Text(
                          _errorMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.red,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _hasError = false;
                            _isInitializing = true;
                          });
                          _initializeServices();
                        },
                        child: const Text('重试'),
                      ),
                    ],
                  )
                : const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                  ),
            ],
          ),
        ),
      ),
    );
  }
} 