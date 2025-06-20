import 'package:flutter/material.dart';
import 'dart:async';
import 'package:leancloud_storage/leancloud.dart';
// 这里需要添加你的登录页和主页的导入路径
// import 'package:demo01/pages/auth/email_login_page.dart';
// import 'package:demo01/pages/main/main_navigation_wrapper.dart';

class SplashScreenPage extends StatefulWidget {
  const SplashScreenPage({Key? key}) : super(key: key);

  @override
  State<SplashScreenPage> createState() => _SplashScreenPageState();
}

class _SplashScreenPageState extends State<SplashScreenPage> with SingleTickerProviderStateMixin {
  // 添加动画控制器
  late AnimationController _controller;
  late Animation<double> _fadeInAnimation;

  @override
  void initState() {
    super.initState();
    
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
    
    // 延迟2秒后检查登录状态并导航
    Timer(const Duration(seconds: 2), () {
      _checkLoginStatusAndNavigate();
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkLoginStatusAndNavigate() async {
    // 检查当前用户登录状态
    LCUser? currentUser = await LCUser.getCurrent();

    if (!mounted) return; // 检查页面是否还存在，防止异步错误

    if (currentUser != null) {
      // 如果用户已登录，跳转到主页
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      // 如果用户未登录，跳转到登录页
      Navigator.of(context).pushReplacementNamed('/login');
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
                child: Image.asset(
                  'assets/icons/logo.png',
                  width: 120,
                  height: 120,
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
              
              // 加载指示器
              const SizedBox(height: 40),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 