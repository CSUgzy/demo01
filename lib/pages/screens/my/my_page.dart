import 'package:flutter/material.dart';
import 'package:leancloud_storage/leancloud.dart';
import '../../../services/post_service.dart';
import 'my_posts_page.dart';
import 'my_collections_page.dart';
import 'edit_profile_page.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  LCUser? _currentUser;
  bool _isLoading = true;
  int _collectionsCount = 0;
  int _postsCount = 0;
  int _followingCount = 0;
  final PostService _postService = PostService();

  @override
  void initState() {
    super.initState();
    _loadCurrentUserProfile();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("我的"),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined),
            onPressed: () {
              // 导航到消息页面
              print("导航到消息页面");
            },
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
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyPostsPage()),
              ).then((_) {
                // 返回时刷新页面数据
                _loadCurrentUserProfile();
              });
            },
            child: _buildStatItem("我发布的", "$_postsCount"),
          ),
          _buildVerticalDivider(),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyCollectionsPage()),
              ).then((_) {
                // 返回时刷新页面数据
                _loadCurrentUserProfile();
              });
            },
            child: _buildStatItem("我收藏的", "$_collectionsCount"),
          ),
          _buildVerticalDivider(),
          _buildStatItem("我关注的", "$_followingCount"),
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
    return GestureDetector(
      onTap: () {
        if (label == "我收藏的") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MyCollectionsPage()),
          );
        } else if (label == "我发布的") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MyPostsPage()),
          );
        } else {
          print("导航到$label页面");
        }
      },
      child: Column(
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
      ),
    );
  }
} 