import 'package:flutter/material.dart';
import 'package:leancloud_storage/leancloud.dart';
import '../../../services/post_service.dart';
import 'my_posts_page.dart';
import 'my_collections_page.dart';

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
            icon: const Icon(Icons.settings),
            onPressed: () {
              // 导航到设置页面（暂未创建）
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(
              //     builder: (context) => const SettingsPage(),
              //   ),
              // );
              print("导航到设置页面");
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
                  
                  const SizedBox(height: 12),
                  
                  // 3. 核心信息标签列表
                  _buildUserTagsSection(),
                  
                  const SizedBox(height: 12),
                  
                  // 4. 功能入口列表
                  _buildFunctionListSection(),
                ],
              ),
            ),
    );
  }
  
  // 1. 用户信息区块
  Widget _buildUserInfoSection() {
    String? avatarUrl = _currentUser?['avatar']?.url as String?;
    String nickname = _currentUser?['nickname'] as String? ?? _currentUser?.username ?? "未知用户";
    String userId = "ID: ${_currentUser?.objectId?.substring(0, 8) ?? ''}";
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
                  print("更换头像");
                  // TODO: 实现头像更换逻辑
                },
                child: Stack(
                  children: [
                    // 头像
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                      child: avatarUrl == null
                          ? const Icon(Icons.person, size: 40, color: Colors.grey)
                          : null,
                    ),
                    // 编辑图标
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
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
                        print("编辑个人资料");
                        // TODO: 导航到编辑个人资料页面
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
  
  // 3. 核心信息标签列表
  Widget _buildUserTagsSection() {
    // 从用户对象获取标签数据
    List<String> profileTags = (_currentUser?['profileSystemTags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    List<String> skills = (_currentUser?['skills'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    List<String> interestedDomains = (_currentUser?['interestedDomains'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    List<String> cooperationMethods = (_currentUser?['cooperationMethods'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    
    // 如果所有列表都为空，则不显示此部分
    if (profileTags.isEmpty && skills.isEmpty && interestedDomains.isEmpty && cooperationMethods.isEmpty) {
      return Container();
    }
    
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 个人标签/技能
          if (profileTags.isNotEmpty || skills.isNotEmpty) ...[
            _buildTagSectionTitle("我的标签"),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...profileTags.map((tag) => _buildTag(tag, Colors.blue[50]!, Colors.blue[700]!)),
                ...skills.map((skill) => _buildTag(skill, Colors.green[50]!, Colors.green[700]!)),
              ],
            ),
            const SizedBox(height: 16),
          ],
          
          // 感兴趣的领域
          if (interestedDomains.isNotEmpty) ...[
            _buildTagSectionTitle("感兴趣的领域"),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: interestedDomains
                  .map((domain) => _buildTag(domain, Colors.orange[50]!, Colors.orange[700]!))
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],
          
          // 期望合作方式
          if (cooperationMethods.isNotEmpty) ...[
            _buildTagSectionTitle("期望合作"),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: cooperationMethods
                  .map((method) => _buildTag(method, Colors.purple[50]!, Colors.purple[700]!))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
  
  // 标签组标题
  Widget _buildTagSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
    );
  }
  
  // 单个标签
  Widget _buildTag(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
        ),
      ),
    );
  }
  
  // 4. 功能入口列表
  Widget _buildFunctionListSection() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          _buildFunctionItem(
            Icons.description_outlined,
            "我的发布",
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyPostsPage()),
              );
            },
          ),
          _buildDivider(),
          _buildFunctionItem(
            Icons.bookmark_outline,
            "我的收藏",
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyCollectionsPage()),
              );
            },
          ),
          _buildDivider(),
          _buildFunctionItem(
            Icons.people_outline,
            "我的关注",
            () { print("导航到我的关注页面"); },
          ),
          _buildDivider(),
          _buildFunctionItem(
            Icons.history,
            "浏览历史",
            () { print("导航到浏览历史页面"); },
          ),
        ],
      ),
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
  
  // 构建功能项
  Widget _buildFunctionItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
  
  // 构建分隔线
  Widget _buildDivider() {
    return const Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
    );
  }
} 