import 'dart:io';
import 'package:leancloud_storage/leancloud.dart';

class UserService {
  // 更新用户基础资料
  Future<bool> updateUserProfile(LCUser user, Map<String, dynamic> data, {LCFile? iconFile}) async {
    try {
      // 验证必填字段
      if (data.containsKey('nickname') && (data['nickname'] == null || data['nickname'].toString().trim().isEmpty)) {
        print('昵称不能为空');
        return false;
      }

      if (data.containsKey('email') && !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(data['email'])) {
        print('邮箱格式不正确');
        return false;
      }

      // 获取当前用户
      LCUser? currentUser = await LCUser.getCurrent();
      if (currentUser == null) {
        print('当前用户未登录');
        return false;
      }

      // 如果有新的头像文件，先更新头像
      if (iconFile != null) {
        // 检查文件是否已经保存
        if (iconFile.objectId == null) {
          await iconFile.save();
        }
        // 将 LCFile 对象设置到 icon 字段
        currentUser['icon'] = iconFile;
        print('更新用户头像: ${iconFile.url}');
      }

      // 更新其他资料
      for (var entry in data.entries) {
        if (entry.key != 'icon' && entry.value != null) {
          currentUser[entry.key] = entry.value;
        }
      }

      // 保存更新
      await currentUser.save();
      print('用户资料更新成功');
      return true;
    } catch (e) {
      if (e is LCException) {
        print('更新用户资料失败: 错误码=${e.code}, 错误信息=${e.message}');
        // 处理特定错误码
        if (e.code == 202) {
          print('用户名已被占用');
        } else if (e.code == 203) {
          print('邮箱已被占用'); 
        }
      } else {
        print('更新用户资料失败: $e');
      }
      return false;
    }
  }

  // 上传头像文件
  Future<LCFile?> uploadAvatar(String filePath, String userId) async {
    try {
      // 创建文件对象
      File file = File(filePath);
      if (!await file.exists()) {
        print('文件不存在: $filePath');
        return null;
      }

      // 获取文件大小和类型
      int fileSize = await file.length();
      String extension = filePath.split('.').last.toLowerCase();
      print('准备上传文件: 大小=${fileSize}字节, 类型=$extension');

      // 检查文件大小限制 (5MB)
      if (fileSize > 5 * 1024 * 1024) {
        print('文件大小超过限制(5MB)');
        return null;
      }

      // 检查文件类型
      if (!['jpg', 'jpeg', 'png'].contains(extension)) {
        print('不支持的文件类型: $extension');
        return null;
      }

      // 构建文件名
      String fileName = 'avatar_${userId}_${DateTime.now().millisecondsSinceEpoch}.$extension';
      
      // 创建 LCFile 并上传
      print('开始上传文件: $fileName');
      LCFile avatar = await LCFile.fromPath(fileName, filePath);
      
      // 设置元数据
      avatar.addMetaData('owner', userId);
      avatar.addMetaData('fileType', 'avatar');
      
      // 设置访问控制 - 允许所有人读写，因为文件需要在用户资料更新时被修改
      var acl = LCACL();
      acl.setPublicReadAccess(true);   // 所有人可读
      acl.setPublicWriteAccess(true);  // 所有人可写
      avatar.acl = acl;
      
      // 等待上传完成
      await avatar.save();
      print('文件上传成功: ${avatar.url}');
      
      return avatar;
    } catch (e) {
      if (e is LCException) {
        print('上传头像失败: 错误码=${e.code}, 错误信息=${e.message}');
      } else {
        print('上传头像失败: $e');
      }
      return null;
    }
  }

  // 获取用户完整资料
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      // 创建用户查询
      LCQuery<LCObject> query = LCQuery('_User');
      
      // 设置查询条件
      query.whereEqualTo('objectId', userId);
      
      // 设置重试次数
      int maxRetries = 3;
      int currentRetry = 0;
      
      while (currentRetry < maxRetries) {
        try {
          LCObject? userObject = await query.get(userId);
          
          if (userObject != null) {
            return {
              'email': userObject['email'],
              'emailVerified': userObject['emailVerified'],
              'icon': userObject['icon'],
              'nickname': userObject['nickname'],
              'gender': userObject['gender'] ?? '未知',
              'mobilePhoneNumber': userObject['mobilePhoneNumber'],
              'wechatId': userObject['wechatId'],
              'city': userObject['city'],
              'skills': userObject['skills'] ?? [],
              'interestedDomains': userObject['interestedDomains'] ?? [],
              'mainGoal': userObject['mainGoal'],
              'cooperationMethods': userObject['cooperationMethods'] ?? [],
              'bio': userObject['bio'],
              'lastActiveAt': userObject['lastActiveAt'],
              'createdAt': userObject.createdAt,
              'updatedAt': userObject.updatedAt,
            };
          }
          return null;
        } catch (e) {
          currentRetry++;
          if (currentRetry >= maxRetries) {
            rethrow;
          }
          // 指数退避重试
          await Future.delayed(Duration(milliseconds: 1000 * currentRetry));
        }
      }
      return null;
    } catch (e) {
      print('获取用户资料失败: $e');
      return null;
    }
  }

  // 更新用户技能标签
  Future<bool> updateUserSkills(LCUser user, List<String> skills) async {
    try {
      user['skills'] = skills;
      await user.save();
      return true;
    } catch (e) {
      print('更新用户技能失败: $e');
      return false;
    }
  }

  // 更新用户感兴趣的领域
  Future<bool> updateUserInterestedDomains(LCUser user, List<String> domains) async {
    try {
      user['interestedDomains'] = domains;
      await user.save();
      return true;
    } catch (e) {
      print('更新用户感兴趣领域失败: $e');
      return false;
    }
  }
} 