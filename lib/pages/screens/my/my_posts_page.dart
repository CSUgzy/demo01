import 'package:flutter/material.dart';
import 'package:leancloud_storage/leancloud.dart';
import '../../../models/project_post_model.dart';
import '../../../models/talent_post_model.dart';
import '../../../services/post_service.dart';
import '../detail/post_detail_page.dart';
import 'dart:convert';

// 标签类型枚举 - 保留用于其他地方可能的引用
enum TagType {
  domain,    // 领域标签 - 蓝色
  skill,     // 技能标签 - 蓝色
  projectStatus, // 项目状态 - 绿色
  secondary, // 次要标签 - 灰色
}

class MyPostsPage extends StatefulWidget {
  const MyPostsPage({super.key});

  @override
  State<MyPostsPage> createState() => _MyPostsPageState();
}

class _MyPostsPageState extends State<MyPostsPage> with SingleTickerProviderStateMixin {
  final PostService _postService = PostService();
  
  // 帖子数据
  List<LCObject> _allPosts = [];
  List<LCObject> _projectPosts = [];
  List<LCObject> _talentPosts = [];
  List<LCObject> _reviewingPosts = [];
  
  // 加载状态
  bool _isLoadingAll = true;
  bool _isLoadingProject = true;
  bool _isLoadingTalent = true;
  bool _isLoadingReviewing = true;
  
  // 当前用户信息
  LCUser? _currentUser;
  String? _userAvatarUrl;
  
  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadPosts();
  }
  
  // 加载当前用户信息
  Future<void> _loadCurrentUser() async {
    try {
      final currentUser = await LCUser.getCurrent();
      if (currentUser != null) {
        await currentUser.fetch(); // 获取最新数据
        
        // 获取用户头像URL
        String? avatarUrl;
        if (currentUser['icon'] != null) {
          final icon = currentUser['icon'];
          if (icon != null && icon is LCFile) {
            avatarUrl = icon.url;
          }
        }
        
        // 如果icon字段没有头像，尝试从avatar字段获取
        if (avatarUrl == null && currentUser['avatar'] != null) {
          final avatar = currentUser['avatar'];
          if (avatar != null && avatar is LCFile) {
            avatarUrl = avatar.url;
          }
        }
        
        setState(() {
          _currentUser = currentUser;
          _userAvatarUrl = avatarUrl;
        });
      }
    } catch (e) {
      print('加载用户信息失败: $e');
    }
  }
  
  // 加载帖子数据
  Future<void> _loadPosts() async {
    setState(() {
      _isLoadingAll = true;
      _isLoadingProject = true;
      _isLoadingTalent = true;
      _isLoadingReviewing = true;
    });
    
    try {
      // 加载项目帖子
      final projectPosts = await _postService.fetchCurrentUserProjectPosts();
      
      // 加载人才帖子
      final talentPosts = await _postService.fetchCurrentUserTalentPosts();
      
      // 更新状态
      setState(() {
        _projectPosts = projectPosts;
        _talentPosts = talentPosts;
        _allPosts = [...projectPosts, ...talentPosts];
        
        // 筛选审核中的帖子 (根据实际字段调整)
        _reviewingPosts = _allPosts.where((post) => 
          post['status'] == 'reviewing' || post['status'] == 'pending'
        ).toList();
        
        _isLoadingAll = false;
        _isLoadingProject = false;
        _isLoadingTalent = false;
        _isLoadingReviewing = false;
      });
    } catch (e) {
      print('Error loading posts: $e');
      setState(() {
        _isLoadingAll = false;
        _isLoadingProject = false;
        _isLoadingTalent = false;
        _isLoadingReviewing = false;
      });
    }
  }
  
  // 删除帖子
  Future<void> _deletePost(LCObject post, int tabIndex) async {
    final String? className = post.className;
    if (className == null) {
      print('Error: className is null');
      return;
    }
    
    final String postId = post.objectId!;
    
    // 确认对话框
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个帖子吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      try {
        // 调用删除方法
        final success = await _postService.deletePost(postId, className);
        
        if (success) {
          // 更新UI
          setState(() {
            if (className == 'ProjectPost') {
              _projectPosts.removeWhere((p) => p.objectId == postId);
            } else if (className == 'TalentPost') {
              _talentPosts.removeWhere((p) => p.objectId == postId);
            }
            
            _allPosts.removeWhere((p) => p.objectId == postId);
            _reviewingPosts.removeWhere((p) => p.objectId == postId);
          });
          
          // 显示成功提示
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('帖子删除成功')),
            );
          }
        } else {
          // 显示错误提示
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('删除失败，请重试')),
            );
          }
        }
      } catch (e) {
        print('Error deleting post: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('删除时出错: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 计算宽度收缩比例
    final double screenWidth = MediaQuery.of(context).size.width;
    final double contentWidth = screenWidth * 0.98; // 向内收缩4%
    
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA), // 与主页一致的背景色
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text('我的发布'),
          actions: [
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                // 暂不实现更多功能
              },
            ),
          ],
          bottom: TabBar(
            tabs: const [
              Tab(text: '全部'),
              Tab(text: '项目'),
              Tab(text: '人才'),
              Tab(text: '审核中'),
            ],
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold), // 选中项加粗
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
            indicatorColor: Colors.blue[700],
            indicatorWeight: 2,
            dividerColor: Colors.transparent, // 去掉底部分隔线
          ),
        ),
        body: TabBarView(
          children: [
            // 全部帖子
            _buildPostsTab(_allPosts, _isLoadingAll, 0, contentWidth),
            
            // 项目帖子（找人才）
            _buildPostsTab(_projectPosts, _isLoadingProject, 1, contentWidth),
            
            // 人才帖子（找项目）
            _buildPostsTab(_talentPosts, _isLoadingTalent, 2, contentWidth),
            
            // 审核中帖子
            _buildPostsTab(_reviewingPosts, _isLoadingReviewing, 3, contentWidth),
          ],
        ),
      ),
    );
  }
  
  // 构建帖子列表Tab
  Widget _buildPostsTab(List<LCObject> posts, bool isLoading, int tabIndex, double contentWidth) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '暂无发布内容',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadPosts,
      child: Center(
        child: SizedBox(
          width: contentWidth, // 使用计算后的内容宽度
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16), // 增加列表视图的垂直内边距
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return MyPostCardItem(
                post: post,
                userAvatarUrl: _userAvatarUrl,
                onDelete: () => _deletePost(post, tabIndex),
                onEdit: () {
                  // TODO: 导航到编辑页面
                  print('编辑帖子: ${post.objectId}');
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

// 帖子卡片组件
class MyPostCardItem extends StatelessWidget {
  final LCObject post;
  final String? userAvatarUrl;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const MyPostCardItem({
    super.key,
    required this.post,
    this.userAvatarUrl,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final String? className = post.className;
    final bool isProjectPost = className == 'ProjectPost';
    
    // 获取帖子信息
    String title = '';
    String description = '';
    List<String> tags = [];
    String statusLabel = '';
    Color statusColor = Colors.green; // 默认颜色
    
    if (isProjectPost) {
      // 项目帖子
      title = post['projectName'] as String? ?? '';
      description = post['projectIntro'] as String? ?? '';
      statusLabel = '项目';
      statusColor = Colors.green;
      
      // 获取项目标签
      if (post['projectTags'] != null) {
        final projectTags = post['projectTags'];
        if (projectTags is List) {
          tags = projectTags.map((tag) => tag.toString()).toList();
        }
      }
      
      // 不再添加项目阶段到标签
    } else {
      // 人才帖子
      title = post['title'] as String? ?? '';
      description = post['detailedIntro'] as String? ?? '';
      statusLabel = '人才';
      statusColor = Colors.purple;
      
      // 获取技能标签
      if (post['coreSkillsTags'] != null) {
        final skillTags = post['coreSkillsTags'];
        if (skillTags is List) {
          tags = skillTags.map((tag) => tag.toString()).toList();
        }
      }
    }
    
    // 获取审核状态
    final String status = post['status'] as String? ?? '';
    if (status == 'reviewing' || status == 'pending') {
      statusLabel = '审核中';
      statusColor = Colors.orange;
    }
    
    // 计算发布时间
    final DateTime createdAt = post.createdAt ?? DateTime.now();
    final String timeAgo = _getTimeAgo(createdAt);
    
    // 构建卡片
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2), // 只有垂直方向的偏移
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          // 导航到帖子详情页
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostDetailPage(
                postId: post.objectId!,
                postType: isProjectPost ? 'Project' : 'Talent',
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 帖子内容
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 发布者信息
                  Row(
                    children: [
                      // 头像
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: userAvatarUrl != null ? NetworkImage(userAvatarUrl!) : null,
                        child: userAvatarUrl == null
                            ? Icon(
                                isProjectPost ? Icons.business_center_outlined : Icons.person_outline,
                                color: Colors.grey,
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      // 名称 - 这里使用"我"作为发布者名称
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '我',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              timeAgo,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 帖子类型标签
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // 标题
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // 描述
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  // 标签
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: tags.map((tag) => _buildTagChip(tag, isProjectPost)).toList(),
                    ),
                  ],
                ],
              ),
            ),
            
            // 分割线 - 不贯穿卡片的样式
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Divider(
                height: 1,
                thickness: 1,
                color: Colors.grey[200],
              ),
            ),
            
            // 底部操作栏 - 保留原有的编辑和删除按钮
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // 编辑按钮
                  _buildActionButton(
                    context,
                    Icons.edit_outlined,
                    '编辑',
                    onEdit,
                    Colors.grey[600]!,
                  ),
                  const SizedBox(width: 16),
                  
                  // 删除按钮
                  _buildActionButton(
                    context,
                    Icons.delete_outline,
                    '删除',
                    onDelete,
                    Colors.red,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // 构建标签组件
  Widget _buildTagChip(String label, bool isProjectPost) {
    // 根据标签类型选择颜色
    late Color bgColor;
    late Color textColor;
    
    if (isProjectPost) {
      // 项目标签 - 蓝色
      bgColor = Colors.green[50]!;
      textColor = Colors.green[700]!;
    } else {
      // 人才标签 - 紫色
      bgColor = Colors.purple[50]!;
      textColor = Colors.purple[700]!;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: textColor,
        ),
      ),
    );
  }
  
  // 构建操作按钮
  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onPressed,
    Color color,
  ) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // 解析字符串列表
  List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    
    // 如果是列表类型
    if (value is List) {
      return value.where((item) => item != null).map((item) => item.toString()).toList();
    }
    
    // 如果是字符串类型，可能是JSON字符串
    if (value is String) {
      try {
        // 尝试解析JSON
        dynamic parsed = json.decode(value);
        if (parsed is List) {
          return parsed.where((item) => item != null).map((item) => item.toString()).toList();
        }
      } catch (e) {
        // 如果不是JSON，则直接作为单个字符串返回
        return [value];
      }
    }
    
    // 如果是Map类型
    if (value is Map) {
      return value.values.where((item) => item != null).map((item) => item.toString()).toList();
    }
    
    return [];
  }
  
  // 获取时间差
  String _getTimeAgo(DateTime dateTime) {
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(dateTime);
    
    if (difference.inDays > 30) {
      return '${difference.inDays ~/ 30}个月前';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }
} 