import 'package:flutter/material.dart';
import 'package:leancloud_storage/leancloud.dart';
import '../../../services/auth_service.dart';
import '../auth/email_login_page.dart';

class AccountSecurityPage extends StatefulWidget {
  const AccountSecurityPage({super.key});

  @override
  State<AccountSecurityPage> createState() => _AccountSecurityPageState();
}

class _AccountSecurityPageState extends State<AccountSecurityPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("账号与安全"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        children: [
          // 修改密码选项
          ListTile(
            leading: const Icon(Icons.lock_outline, color: Colors.blue),
            title: const Text("修改密码"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChangePasswordPage(),
                ),
              );
            },
          ),
          // const Divider(height: 1),
          
          // 可以添加其他账号安全相关选项，如绑定手机号、邮箱验证等
        ],
      ),
    );
  }
}

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final formKey = GlobalKey<FormState>();
  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool isLoading = false;
  String? errorMessage;

  @override
  void dispose() {
    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("修改密码"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 当前密码
              Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.96, // 宽度为屏幕宽度的96%
                  child: TextFormField(
                    controller: oldPasswordController,
                    decoration: const InputDecoration(
                      labelText: '当前密码',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入当前密码';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // 新密码
              Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.96, // 宽度为屏幕宽度的96%
                  child: TextFormField(
                    controller: newPasswordController,
                    decoration: const InputDecoration(
                      labelText: '新密码',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入新密码';
                      }
                      if (value.length < 6) {
                        return '密码长度不能少于6位';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // 确认新密码
              Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.96, // 宽度为屏幕宽度的96%
                  child: TextFormField(
                    controller: confirmPasswordController,
                    decoration: const InputDecoration(
                      labelText: '确认新密码',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请确认新密码';
                      }
                      if (value != newPasswordController.text) {
                        return '两次输入的密码不一致';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              
              // 错误信息
              if (errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
              
              const SizedBox(height: 24),
              
              // 确认修改按钮
              Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.96, // 宽度为屏幕宽度的96%
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _handleChangePassword,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: isLoading 
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('确认修改'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _handleChangePassword() async {
    // 校验表单
    if (!formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    
    try {
      // 获取当前用户
      final currentUser = await LCUser.getCurrent();
      if (currentUser == null) {
        throw Exception('用户未登录');
      }
      
      // 保存密码值
      final oldPassword = oldPasswordController.text;
      final newPassword = newPasswordController.text;
      
      // 修改密码
      await currentUser.updatePassword(
        oldPassword,
        newPassword,
      );
      
      if (mounted) {
        // 显示成功提示
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('密码修改成功，请重新登录')),
        );
        
        // 执行退出登录逻辑
        await _handleLogout();
      }
    } catch (e) {
      // 处理错误
      String message = '密码修改失败';
      if (e is LCException) {
        if (e.code == 210) {
          message = '当前密码不正确';
        } else {
          message = '修改失败: ${e.message}';
        }
      }
      
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = message;
        });
      }
    }
  }
  
  // 处理退出登录
  Future<void> _handleLogout() async {
    try {
      // 使用AuthService的logout方法
      await AuthService().logout();
      
      if (mounted) {
        // 导航到登录页面，并清除所有之前的页面栈
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const EmailLoginPage()),
          (Route<dynamic> route) => false, // 移除所有现有路由
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('退出登录失败: $e')),
        );
      }
    }
  }
} 