// services/help_and_feedback_service.dart
import 'package:leancloud_storage/leancloud.dart';
import 'package:package_info_plus/package_info_plus.dart'; // 用于获取App版本
import 'package:device_info_plus/device_info_plus.dart'; // 用于获取设备信息
import 'dart:io' show Platform;

class HelpAndFeedbackService {
  Future<bool> submitFeedback({
    required String content,
    String? contactInfo,
  }) async {
    LCUser? currentUser = await LCUser.getCurrent();
    if (currentUser == null) {
      // 用户未登录，理论上不应能进入此页面，但作为防御性编程
      throw "请先登录后再提交反馈。";
    }
    if (content.trim().isEmpty) {
      throw "反馈内容不能为空。";
    }

    try {
      LCObject feedback = LCObject('Feedback');
      feedback['submitter'] = currentUser;
      feedback['content'] = content.trim();

      if (contactInfo != null && contactInfo.isNotEmpty) {
        feedback['contactInfo'] = contactInfo;
      }

      // 获取App版本信息
      final packageInfo = await PackageInfo.fromPlatform();
      feedback['appVersion'] = '${packageInfo.version}+${packageInfo.buildNumber}';
      
      // 获取设备信息
      final deviceInfo = DeviceInfoPlugin();
      String deviceInfoStr = '';
      
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceInfoStr = 'Android ${androidInfo.version.release}, ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceInfoStr = 'iOS ${iosInfo.systemVersion}, ${iosInfo.model}';
      } else {
        deviceInfoStr = Platform.operatingSystem;
      }
      
      feedback['deviceInfo'] = deviceInfoStr;
      
      // ACL: 只有创建者和后台管理员能读，但创建者不能修改或删除，以防撤回
      LCACL acl = LCACL();
      acl.setUserIdReadAccess(currentUser.objectId!, true);

      acl.setPublicWriteAccess(false); // 公开不可写
      // 默认情况下，管理员可以在后台看到所有数据
      feedback.acl = acl;

      await feedback.save();
      return true;
    } on LCException catch (e) {
      // 可以根据e.code进行更详细的错误处理
      throw "提交失败，请稍后重试。";
    } catch (e) {
      throw "发生未知错误，请检查您的网络连接。";
    }
  }
} 