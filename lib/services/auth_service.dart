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
  Future<(LCUser?, String?)> loginWithEmailPassword(String email, String password) async {
    try {
      print('尝试登录: $email');
      
      // 执行登录
      LCUser? user = await LCUser.login(email, password);
      print('登录成功: ${user?.objectId}');
      return (user, null);
    } catch (e) {
      String errorMessage;
      if (e is LCException) {
        print('LeanCloud登录异常: 错误码=${e.code}, 消息=${e.message}');
        switch (e.code) {
          case 210:
            errorMessage = '用户名和密码不匹配';
            break;
          case 211:
            errorMessage = '该用户不存在';
            break;
          case 216:
            errorMessage = '未设置邮箱，请使用用户名登录';
            break;
          case 219:
            errorMessage = '登录失败次数超过限制，请稍后再试';
            break;
          case -1:
            errorMessage = '网络连接失败，请检查网络设置';
            break;
          default:
            errorMessage = '登录失败：${e.message}';
        }
      } else {
        print('登录失败(非LeanCloud异常): $e');
        errorMessage = '登录失败：网络错误或服务器异常';
      }
      return (null, errorMessage);
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
      print('尝试退出登录');
      await LCUser.logout();
      print('退出登录成功');
    } catch (e) {
      print('退出登录失败: $e');
      rethrow; // 重新抛出异常，让调用者处理
    }
  }
} 