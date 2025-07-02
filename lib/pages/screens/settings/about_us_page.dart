import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../services/update_service.dart';
import '../../../utils/toast_util.dart';

class AboutUsPage extends StatefulWidget {
  const AboutUsPage({super.key});

  @override
  State<AboutUsPage> createState() => _AboutUsPageState();
}

class _AboutUsPageState extends State<AboutUsPage> {
  String _version = '加载中...';

  @override
  void initState() {
    super.initState();
    _loadVersionInfo();
  }

  // 加载版本信息
  Future<void> _loadVersionInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _version = '${packageInfo.version}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _version = '获取失败';
        });
      }
      print('获取版本信息失败: $e');
    }
  }

  // 处理检查更新
  Future<void> _handleCheckForUpdate(BuildContext context) async {
    // 显示一个加载中的提示
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final updateInfo = await UpdateService.checkForUpdate();
    
    if (mounted) {
      Navigator.of(context).pop(); // 关闭加载提示

      if (updateInfo != null) {
        // 如果有新版本，显示更新对话框
        _showUpdateDialog(context, updateInfo);
      } else {
        // 如果没有新版本，使用Toast提示
        ToastUtil.showSuccess(context, "您当前已是最新版本");
      }
    }
  }

  // 显示更新提示对话框
  void _showUpdateDialog(BuildContext context, UpdateInfo updateInfo) {
    showDialog(
      context: context,
      barrierDismissible: !updateInfo.isForceUpdate, // 如果是强制更新，则不允许点击外部关闭
      builder: (BuildContext context) {
        return WillPopScope( // 防止强制更新时用户通过安卓返回键关闭
          onWillPop: () async => !updateInfo.isForceUpdate,
          child: AlertDialog(
            title: Text("发现新版本 v${updateInfo.latestVersionName}"),
            content: SingleChildScrollView(
              child: Text(updateInfo.updateLog),
            ),
            actions: <Widget>[
              if (!updateInfo.isForceUpdate)
                // 非强制更新时显示"稍后提醒"按钮
                TextButton(
                  child: const Text("稍后提醒"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                )
              else
                // 强制更新时显示"取消"按钮，点击也会退出应用
                TextButton(
                  child: const Text("取消"),
                  onPressed: () {
                    // 退出应用
                    SystemNavigator.pop();
                  },
                ),
              TextButton(
                child: const Text("立即更新"),
                onPressed: () {
                  if (updateInfo.isForceUpdate) {
                    // 强制更新时，先启动更新，然后退出应用
                    UpdateService.performUpdate(context, updateInfo);
                    // 延迟一小段时间后退出应用，确保更新操作已经启动
                    Future.delayed(const Duration(seconds: 1), () {
                      SystemNavigator.pop();
                    });
                  } else {
                    // 非强制更新时，关闭对话框并执行更新
                    Navigator.of(context).pop();
                    UpdateService.performUpdate(context, updateInfo);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('关于我们'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 顶部内容区
            Column(
              children: [
                const SizedBox(height: 40),
                // 应用Logo
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/icons/logo.png',
                    width: 120,
                    height: 120,
                  ),
                ),
                const SizedBox(height: 20),
                // 应用名称
                Text(
                  "良师益友",
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                // 版本号
                Text(
                  "版本号: $_version",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                // 应用简介
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    "我们致力于搭建一个高效连接创新项目与专业人才的平台，促进优质合作，让天下没有难创的业。",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            
            // 功能入口
            Column(
              children: [
                // const Divider(),
                ListTile(
                  title: const Text("检查更新"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _handleCheckForUpdate(context),
                ),
                // const Divider(),
              ],
            ),
            
            // 底部版权区
            Column(
              children: [
                Text(
                  "Copyright © 2025 良师谊友. All Rights Reserved.",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 