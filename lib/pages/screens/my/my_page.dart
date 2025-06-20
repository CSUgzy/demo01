import 'package:flutter/material.dart';
import 'package:leancloud_storage/leancloud.dart';
import '../../../services/post_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/notification_service.dart';
import '../auth/email_login_page.dart';
import '../settings/account_security_page.dart';
import '../notifications/notification_page.dart';
import '../settings/privacy_policy_page.dart';
import '../settings/help_and_feedback_page.dart';
import '../settings/about_us_page.dart';
import 'my_posts_page.dart';
import 'my_collections_page.dart';
import 'edit_profile_page.dart';
import '../../../utils/feedback_service.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> with WidgetsBindingObserver {
  LCUser? _currentUser;
  bool _isLoading = true;
  int _collectionsCount = 0;
  int _postsCount = 0;
  int _followingCount = 0;
  int _unreadCount = 0;
  final PostService _postService = PostService();
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCurrentUserProfile();
    _loadUnreadNotificationCount();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 当应用从后台恢复时，重新获取未读消息数量
      _loadUnreadNotificationCount();
    }
  }

  // 加载未读消息数量
  Future<void> _loadUnreadNotificationCount() async {
    try {
      if (await LCUser.getCurrent() != null) {
        final count = await _notificationService.getUnreadNotificationCount();
        if (mounted) {
          setState(() {
            _unreadCount = count;
          });
        }
      }
    } catch (e) {
      print("Error loading unread notification count: $e");
      if (e is LCException) {
        print('LeanCloud error code: ${(e as LCException).code}, message: ${(e as LCException).message}');
      }
    }
  }

  Future<void> _loadCurrentUserProfile() async {
    setState(() { _isLoading = true; });
    
    LCUser? user = await LCUser.getCurrent();
    if (user != null) {
      try {
        await user.fetch(); // 获取最新数据
        _currentUser = user;
        
        // 加载统计数据
        _loadUserStats();
      } catch (e) {
        print("Error fetching user data: $e");
        // 如果fetch失败，仍然使用本地缓存的user
        _currentUser = user;
        _loadUserStats();
      }
    } else {
      setState(() { _isLoading = false; });
    }
  }
  
  // 加载用户统计数据
  Future<void> _loadUserStats() async {
    try {
      // 获取收藏数量
      final collections = await _postService.fetchCurrentUserCollections();
      
      // 获取发布数量
      final projectPosts = await _postService.fetchCurrentUserProjectPosts();
      final talentPosts = await _postService.fetchCurrentUserTalentPosts();
      
      // 更新状态
      setState(() {
        _collectionsCount = collections.length;
        _postsCount = projectPosts.length + talentPosts.length;
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading user stats: $e");
      setState(() { _isLoading = false; });
    }
  }

  // 导航到通知页面
  void _navigateToNotifications() async {
    if (mounted) {
      print("导航到通知页面");
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const NotificationPage()),
      );
      
      // 从通知页面返回后，刷新未读消息数量
      _loadUnreadNotificationCount();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("我的"),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_outlined),
                onPressed: _navigateToNotifications,
              ),
              if (_unreadCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      _unreadCount > 99 ? '99+' : '$_unreadCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _currentUser == null 
          ? const Center(
              child: Text(
                "请先登录",
                style: TextStyle(fontSize: 18),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. 用户信息区块
                  _buildUserInfoSection(),
                  
                  const SizedBox(height: 12),
                  
                  // 2. 数据统计区块
                  _buildStatsSection(),
                  
                  // 分隔区块
                  Container(
                    height: 10,
                    color: const Color(0xFFF5F7FA),
                  ),
                  
                  // 3. 设置功能列表
                  _buildSettingsList(),
                ],
              ),
            ),
    );
  }
  
  // 1. 用户信息区块
  Widget _buildUserInfoSection() {
    String? avatarUrl = _currentUser?['icon']?.url as String?;
    String nickname = _currentUser?['nickname'] as String? ?? _currentUser?.username ?? "未知用户";
    String userId = "ID: ${_currentUser?.objectId?.substring(0, 10) ?? ''}";
    String bio = _currentUser?['bio'] as String? ?? "暂无个人简介";
    
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头像和名称信息
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 头像 (可点击更换)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditProfilePage(),
                    ),
                  ).then((_) {
                    // 返回时刷新页面数据
                    _loadCurrentUserProfile();
                  });
                },
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl == null
                      ? const Icon(Icons.person, size: 40, color: Colors.grey)
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              
              // 昵称和ID
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nickname,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userId,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // 编辑资料按钮
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EditProfilePage(),
                          ),
                        ).then((_) {
                          // 返回时刷新页面数据
                          _loadCurrentUserProfile();
                        });
                      },
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text("编辑资料"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        side: BorderSide(color: Colors.grey[300]!),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        minimumSize: const Size(0, 30),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // 个性签名/一句话简介
          if (bio.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              bio,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
  
  // 2. 数据统计区块
  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MyPostsPage()),
                ).then((_) {
                  // 返回时刷新页面数据
                  _loadCurrentUserProfile();
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: _buildStatItem("我发布的", "$_postsCount"),
              ),
            ),
          ),
          _buildVerticalDivider(),
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MyCollectionsPage()),
                ).then((_) {
                  // 返回时刷新页面数据
                  _loadCurrentUserProfile();
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: _buildStatItem("我收藏的", "$_collectionsCount"),
              ),
            ),
          ),
          _buildVerticalDivider(),
          Expanded(
            child: InkWell(
              onTap: () {
                print("导航到我关注的页面");
                // TODO: 导航到关注页面
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: _buildStatItem("我关注的", "$_followingCount"),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // 垂直分隔线
  Widget _buildVerticalDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.grey[200],
    );
  }
  
  // 构建统计项目
  Widget _buildStatItem(String label, String value) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  // 3. 设置功能列表
  Widget _buildSettingsList() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // 账号与安全
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            title: const Text("账号与安全", style: TextStyle(fontSize: 16)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () {
              print("导航到账号与安全页面");
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AccountSecurityPage()),
              );
            },
          ),
          Divider(height: 1, indent: 24, endIndent: 24, color: Colors.grey[200]),
          
          // 隐私设置
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            title: const Text("隐私政策", style: TextStyle(fontSize: 16)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () {
              print("导航到隐私政策页面");
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PrivacyPolicyPage()),
              );
            },
          ),
          Divider(height: 1, indent: 24, endIndent: 24, color: Colors.grey[200]),
          
          // 帮助与反馈
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            title: const Text("帮助与反馈", style: TextStyle(fontSize: 16)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () {
              print("导航到帮助与反馈页面");
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HelpAndFeedbackPage()),
              );
            },
          ),
          Divider(height: 1, indent: 24, endIndent: 24, color: Colors.grey[200]),
          
          // 关于我们
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            title: const Text("关于我们", style: TextStyle(fontSize: 16)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () {
              print("导航到关于我们页面");
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutUsPage()),
              );
            },
          ),
          
          // 退出登录按钮
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _handleLogout,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide.none,
                  ),
                ),
                child: const Text(
                  "退出登录",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // 处理退出登录
  Future<void> _handleLogout() async {
    // 显示确认对话框
    final bool confirm = await FeedbackService.showConfirmationDialog(
      context,
      title: '确认退出',
      content: '确定要退出登录吗？',
      confirmText: '退出',
      cancelText: '取消',
    );
    
    // 如果用户确认退出
    if (confirm) {
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
          FeedbackService.showErrorSnackBar(context, '退出登录失败: $e');
        }
      }
    }
  }
} 