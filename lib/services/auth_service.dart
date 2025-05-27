import 'package:leancloud_storage/leancloud.dart';

class AuthService {
  // 注册方法 (邮箱+密码)
  Future<(LCUser?, String?)> registerWithEmailPassword(String email, String password) async {
    try {
      // 创建用户
      LCUser user = LCUser();
      // 设置邮箱和密码
      user.username = email; // 使用邮箱作为用户名
      user.email = email;
      user.password = password;
      
      // 执行注册
      await user.signUp();
      return (user, null);
    } catch (e) {
      String errorMessage;
      if (e is LCException) {
        switch (e.code) {
          case 202:
            errorMessage = '该用户名已被注册';
            break;
          case 203:
            errorMessage = '该邮箱已被注册';
            break;
          case 125:
            errorMessage = '邮箱地址无效';
            break;
          default:
            errorMessage = '注册失败：${e.message}';
        }
      } else {
        errorMessage = '注册失败：网络错误或服务器异常';
      }
      print('注册失败: $e');
      return (null, errorMessage);
    }
  }

  // 登录方法 (邮箱+密码)
  Future<LCUser?> loginWithEmailPassword(String email, String password) async {
    try {
      // 执行登录
      LCUser? user = await LCUser.login(email, password);
      return user;
    } catch (e) {
      print('登录失败: $e');
      return null;
    }
  }

  // 请求密码重置邮件
  Future<bool> requestPasswordResetEmail(String email) async {
    try {
      await LCUser.requestPasswordReset(email);
      return true;
    } catch (e) {
      print(e); // 处理邮箱不存在等错误
      return false;
    }
  }

  // 检查当前用户邮箱是否已验证
  Future<bool> isCurrentUserEmailVerified() async {
    try {
      LCUser? currentUser = await LCUser.getCurrent();
      if (currentUser != null) {
        // 获取最新的用户信息
        await currentUser.fetch();
        return currentUser['emailVerified'] ?? false;
      }
      return false;
    } catch (e) {
      print('检查邮箱验证状态失败: $e');
      return false;
    }
  }

  // 重新发送验证邮件
  Future<bool> resendVerificationEmail(LCUser user) async {
    try {
      await LCUser.requestEmailVerify(user.email!);
      return true;
    } catch (e) {
      print('重新发送验证邮件失败: $e');
      return false;
    }
  }

  // 获取当前用户
  Future<LCUser?> getCurrentUser() async {
    try {
      return await LCUser.getCurrent();
    } catch (e) {
      print('获取当前用户失败: $e');
      return null;
    }
  }

  // 退出登录
  Future<void> logout() async {
    try {
      await LCUser.logout();
    } catch (e) {
      print('退出登录失败: $e');
    }
  }
} 