import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../pages/screens/home/home_page.dart';
import '../pages/screens/my/my_page.dart';
import '../pages/screens/postings/select_post_type_page.dart';
import '../services/update_service.dart';

class MainNavigationWrapper extends StatefulWidget {
  const MainNavigationWrapper({super.key});

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  // 当前选中的Tab索引
  int _currentIndex = 0;
  
  // Tab对应的页面列表
  final List<Widget> _pages = [
    const HomePage(),
    const MyPage(),
  ];

  @override
  void initState() {
    super.initState();
    // 在组件加载后执行强制更新检查
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForForceUpdate();
    });
  }

  // 检查强制更新
  Future<void> _checkForForceUpdate() async {
    final updateInfo = await UpdateService.checkForForceUpdate();
    if (updateInfo != null && mounted) {
      _showUpdateDialog(context, updateInfo);
    }
  }

  // 显示更新对话框
  void _showUpdateDialog(BuildContext context, UpdateInfo updateInfo) {
    showDialog(
      context: context,
      barrierDismissible: !updateInfo.isForceUpdate,
      builder: (BuildContext context) {
        return WillPopScope(
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
    // 定义主题色
    final Color primaryColor = Theme.of(context).primaryColor;
    
    return Scaffold(
      body: _pages[_currentIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 点击"+"按钮时，导航到发布选择页面
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SelectPostTypePage(),
            ),
          );
        },
        backgroundColor: primaryColor,
        elevation: 6.0,
        shape: const CircleBorder(), // 确保按钮是圆形的
        child: const Icon(Icons.add, size: 32, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        elevation: 8.0,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        // 修复选中状态：使用实际的_currentIndex映射到UI索引
        currentIndex: _currentIndex == 0 ? 0 : 2,
        onTap: (index) {
          // 如果点击中间的按钮(索引1)，不做任何事情，因为我们使用FAB
          if (index == 1) return;
          
          // 更新当前索引
          setState(() {
            _currentIndex = index > 1 ? 1 : 0; // 0->首页, 1->我的
          });
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: '首页',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.add, color: Colors.transparent),
            label: '', // 移除"发布"文字
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }
} 