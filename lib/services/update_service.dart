import 'dart:io';
import 'package:flutter/material.dart';
import 'package:leancloud_storage/leancloud.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:url_launcher/url_launcher.dart';

// 定义一个数据模型来承载版本信息
class UpdateInfo {
  final String latestVersionName;
  final int latestVersionCode;
  final String updateLog;
  final bool isForceUpdate;
  final String storeUrl;

  UpdateInfo({
    required this.latestVersionName,
    required this.latestVersionCode,
    required this.updateLog,
    required this.isForceUpdate,
    required this.storeUrl,
  });
}

class UpdateService {
  // 默认应用商店链接
  static const String defaultAndroidStoreUrl = "https://play.google.com/store/apps/details?id=com.example.demo01";
  static const String defaultIosStoreUrl = "https://apps.apple.com/app/idYOUR_APP_ID";
  
  /// 检查是否有新版本
  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      // 1. 获取当前App的版本信息
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      print('packageInfo: $packageInfo');
      int currentVersionCode = int.parse(packageInfo.buildNumber);
      String platform = Platform.isIOS ? 'iOS' : 'Android';
      print('当前平台: $platform, 版本号: $currentVersionCode');

      // 2. 从LeanCloud查询最新版本信息
      try {
        print('开始查询AppVersion表...');
        LCQuery<LCObject> query = LCQuery('AppVersion');
        query.whereEqualTo('platform', platform);
        query.orderByDescending('versionCode');
        query.limit(1);
        
        print('执行查询...');
        List<LCObject>? results = await query.find();
        print('查询结果: ${results?.length ?? 0} 条记录');

        if (results == null || results.isEmpty) {
          print('未找到版本信息记录');
          return null; // 服务器上没有版本信息
        }
        
        LCObject latestVersion = results.first;
        print('找到最新版本: ${latestVersion.objectId}');
        
        // 打印可能的字段，检查是否存在
        print('版本信息字段:');
        // 尝试获取常见字段
        final fields = ['versionName', 'versionCode', 'updateLog', 'isForceUpdate', 'storeUrl', 'platform'];
        for (final field in fields) {
          print('$field: ${latestVersion[field]}');
        }
        
        // 安全获取版本号
        int latestVersionCode = 0;
        if (latestVersion['versionCode'] != null) {
          latestVersionCode = latestVersion['versionCode'] as int;
        } else {
          print('警告: versionCode字段不存在');
          return null;
        }
        
        print('最新版本号: $latestVersionCode, 当前版本号: $currentVersionCode');

        // 3. 比较版本号 - 确保服务器版本确实高于当前版本
        if (latestVersionCode > currentVersionCode) {
          print('发现新版本');
          
          // 安全获取其他字段
          String versionName = latestVersion['versionName'] as String? ?? '未知版本';
          String updateLog = latestVersion['updateLog'] as String? ?? '暂无更新说明';
          bool isForceUpdate = latestVersion['isForceUpdate'] as bool? ?? false;
          
          // 获取商店链接，如果为空则使用默认链接
          String storeUrl = latestVersion['storeUrl'] as String? ?? '';
          if (storeUrl.isEmpty) {
            storeUrl = Platform.isAndroid ? defaultAndroidStoreUrl : defaultIosStoreUrl;
            print('使用默认应用商店链接: $storeUrl');
          }
          
          // 发现新版本，封装信息并返回
          return UpdateInfo(
            latestVersionName: versionName,
            latestVersionCode: latestVersionCode,
            updateLog: updateLog,
            isForceUpdate: isForceUpdate,
            storeUrl: storeUrl,
          );
        }
        
        print('当前已是最新版本');
        return null; // 没有新版本
      } on LCException catch (e) {
        print('LeanCloud查询异常: 错误码=${e.code}, 错误信息=${e.message}');
        if (e.code == 101) {
          print('提示: 错误码101通常表示AppVersion表不存在，请确认已创建该表');
        }
        return null;
      }
    } catch (e) {
      print('检查更新失败: $e');
      return null;
    }
  }

  /// 只检查强制更新的版本
  static Future<UpdateInfo?> checkForForceUpdate() async {
    try {
      // 1. 获取当前App的版本信息
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      int currentVersionCode = int.parse(packageInfo.buildNumber);
      String platform = Platform.isIOS ? 'iOS' : 'Android';
      print('检查强制更新 - 当前平台: $platform, 版本号: $currentVersionCode');

      // 2. 从LeanCloud查询最新的强制更新版本
      try {
        LCQuery<LCObject> query = LCQuery('AppVersion');
        query.whereEqualTo('platform', platform);
        query.whereEqualTo('isForceUpdate', true);  // 只查询强制更新的版本
        query.orderByDescending('versionCode');
        query.limit(1);
        
        List<LCObject>? results = await query.find();
        
        if (results == null || results.isEmpty) {
          print('未找到强制更新版本');
          return null;
        }
        
        LCObject forceVersion = results.first;
        
        // 安全获取版本号
        int latestVersionCode = 0;
        if (forceVersion['versionCode'] != null) {
          latestVersionCode = forceVersion['versionCode'] as int;
        } else {
          print('警告: 强制更新版本的versionCode字段不存在');
          return null;
        }
        
        // 3. 比较版本号 - 只有当强制更新版本高于当前版本时才返回
        if (latestVersionCode > currentVersionCode) {
          print('发现强制更新版本');
          
          String versionName = forceVersion['versionName'] as String? ?? '未知版本';
          String updateLog = forceVersion['updateLog'] as String? ?? '暂无更新说明';
          
          String storeUrl = forceVersion['storeUrl'] as String? ?? '';
          if (storeUrl.isEmpty) {
            storeUrl = Platform.isAndroid ? defaultAndroidStoreUrl : defaultIosStoreUrl;
          }
          
          return UpdateInfo(
            latestVersionName: versionName,
            latestVersionCode: latestVersionCode,
            updateLog: updateLog,
            isForceUpdate: true,  // 这里一定是强制更新
            storeUrl: storeUrl,
          );
        }
        
        print('当前版本已高于或等于强制更新版本');
        return null;
      } on LCException catch (e) {
        print('检查强制更新异常: 错误码=${e.code}, 错误信息=${e.message}');
        return null;
      }
    } catch (e) {
      print('检查强制更新失败: $e');
      return null;
    }
  }

  /// 执行更新操作
  static Future<void> performUpdate(BuildContext context, UpdateInfo updateInfo) async {
    try {
      if (Platform.isAndroid) {
        // Android 使用应用内更新
        try {
          print('执行Android应用内更新');
          
          // 先调用checkForUpdate
          print('调用InAppUpdate.checkForUpdate()...');
          AppUpdateInfo? appUpdateInfo = await InAppUpdate.checkForUpdate();
          print('checkForUpdate结果: $appUpdateInfo');
          
          if (appUpdateInfo?.updateAvailability == UpdateAvailability.updateAvailable) {
            print('有可用更新，执行immediateUpdate...');
            AppUpdateResult result = await InAppUpdate.performImmediateUpdate();
            print('更新结果: $result');
            if (result == AppUpdateResult.success) {
              print('应用内更新成功');
            }
          } else {
            print('应用内更新不可用，尝试跳转到应用商店');
            _launchAppStore(updateInfo.storeUrl);
          }
        } catch (e) {
          print('应用内更新失败: $e，尝试跳转到应用商店');
          // 如果应用内更新失败，则跳转到应用商店
          _launchAppStore(updateInfo.storeUrl);
        }
      } else if (Platform.isIOS) {
        // iOS 直接跳转到App Store
        print('执行iOS更新，跳转到App Store');
        _launchAppStore(updateInfo.storeUrl);
      }
    } catch (e) {
      print('执行更新操作失败: $e');
    }
  }
  
  /// 打开应用商店
  static Future<void> _launchAppStore(String url) async {
    if (url.isEmpty) {
      url = Platform.isAndroid ? defaultAndroidStoreUrl : defaultIosStoreUrl;
      print('使用默认应用商店链接: $url');
    }
    
    try {
      print('打开URL: $url');
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        print('无法打开URL: $url');
      }
    } catch (e) {
      print('打开应用商店失败: $e');
    }
  }
} 