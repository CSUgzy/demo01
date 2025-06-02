import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:leancloud_storage/leancloud.dart';
import '../../../services/auth_service.dart';

class EmailLoginPage extends StatefulWidget {
  const EmailLoginPage({super.key});

  @override
  State<EmailLoginPage> createState() => _EmailLoginPageState();
}

class _EmailLoginPageState extends State<EmailLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showEmailVerificationDialog(LCUser user) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('邮箱未验证'),
          content: const Text('您的邮箱尚未验证，请先前往邮箱完成验证。需要重新发送验证邮件吗？'),
          actions: <Widget>[
            TextButton(
              child: const Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('重新发送'),
              onPressed: () async {
                Navigator.of(context).pop();
                final success = await _authService.resendVerificationEmail(user);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? '验证邮件已发送，请查收' : '发送验证邮件失败，请稍后重试'),
                      backgroundColor: success 
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  String _getErrorMessage(dynamic error) {
    if (error is LCException) {
      switch (error.code) {
        case 210:
          return '用户名和密码不匹配';
        case 211:
          return '该用户不存在';
        case 216:
          return '未设置邮箱，请使用用户名登录';
        case 219:
          return '登录失败次数超过限制，请稍后再试';
        default:
          return '登录失败：${error.message}';
      }
    }
    return '登录失败：网络错误或服务器异常';
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        final email = _emailController.text.trim();
        final password = _passwordController.text;
        
        final user = await _authService.loginWithEmailPassword(email, password);
        
        if (user != null && mounted) {
          // 检查邮箱验证状态
          final isEmailVerified = await _authService.isCurrentUserEmailVerified();
          
          if (!isEmailVerified) {
            _showEmailVerificationDialog(user);
            return;
          }
          
          // 检查用户资料完善阶段
          final profileStage = user['profileCompletionStage'] as int? ?? 0;
          
          if (profileStage < 3) { // 假设总共有3个步骤
            Navigator.pushReplacementNamed(
              context, 
              '/profile-setup-step${profileStage + 1}'
            );
          } else {
            Navigator.pushReplacementNamed(context, '/home');
          }
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('登录失败：用户名或密码错误'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_getErrorMessage(e)),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final formWidth = screenWidth > 600 ? 400.0 : screenWidth;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(height: screenHeight * 0.08),

                // 上半部分（Logo、标题、slogan）
                Column(
                  children: [
                    // Logo占位符
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.school,
                        size: 50,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 标题和副标题
                    Text(
                      '良师益友',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '让天下没有难创的业',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: screenHeight * 0.1),

                // 登录表单
                Container(
                  width: formWidth,
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Form(
                    key: _formKey,
                    child: AutofillGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 邮箱输入框
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            decoration: const InputDecoration(
                              labelText: '电子邮箱',
                              hintText: '请输入您的电子邮箱',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '请输入电子邮箱';
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                return '请输入有效的电子邮箱地址';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // 密码输入框
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            autofillHints: const [AutofillHints.password],
                            decoration: InputDecoration(
                              labelText: '密码',
                              hintText: '请输入密码',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '请输入密码';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // 登录按钮
                          FilledButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text('登录'),
                          ),
                          const SizedBox(height: 16),

                          // 底部按钮行
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
                                child: const Text('忘记密码？'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pushReplacementNamed(context, '/register'),
                                child: const Text('没有账号？去注册'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 