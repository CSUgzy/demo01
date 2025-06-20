import 'package:flutter/material.dart';
import 'package:leancloud_storage/leancloud.dart';
import '../../../services/post_service.dart';
import '../detail/post_detail_page.dart';
import '../../../utils/feedback_service.dart';

class MyCollectionsPage extends StatefulWidget {
  const MyCollectionsPage({super.key});

  @override
  State<MyCollectionsPage> createState() => _MyCollectionsPageState();
}

class _MyCollectionsPageState extends State<MyCollectionsPage> {
  final PostService _postService = PostService();
  
  List<dynamic> _collectedItems = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadCollections();
  }
  
  // 加载用户收藏
  Future<void> _loadCollections() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final collectedItems = await _postService.fetchCurrentUserCollections();
      setState(() {
        _collectedItems = collectedItems;
        _isLoading = false;
      });
    } catch (e) {
      print('加载收藏失败: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // 取消收藏
  Future<void> _uncollectPost(dynamic collectionItem, int index) async {
    final originalEntry = collectionItem['originalCollectionEntry'] as LCObject;
    final postObject = collectionItem['postObject'] as LCObject;
    final String postId = postObject.objectId!;
    final String postType = postObject.className == 'ProjectPost' ? 'Project' : 'Talent';
    
    // 确认对话框
    final bool confirm = await FeedbackService.showConfirmationDialog(
      context,
      title: '确认取消收藏',
      content: '确定要取消收藏这个帖子吗？',
      confirmText: '确定',
      cancelText: '取消',
    );
    
    if (confirm) {
      try {
        // 取消收藏
        final success = await _postService.toggleCollectionStatus(postId, postType, true);
        
        if (success) {
          // 减少收藏数量
          try {
            if (postObject['collectionCount'] != null) {
              int currentCount = postObject['collectionCount'] as int;
              if (currentCount > 0) {
                postObject['collectionCount'] = currentCount - 1;
                await postObject.save();
              }
            }
          } catch (e) {
            print('更新收藏数量失败: $e');
          }
          
          // 从列表中移除
          setState(() {
            _collectedItems.removeAt(index);
          });
          
          if (mounted) {
            FeedbackService.showSuccessToast(context, '已取消收藏');
          }
        } else {
          if (mounted) {
            FeedbackService.showErrorToast(context, '取消收藏失败，请重试');
          }
        }
      } catch (e) {
        print('取消收藏时出错: $e');
        if (mounted) {
          FeedbackService.showErrorToast(context, '操作失败: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('我的收藏'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _collectedItems.isEmpty
          ? _buildEmptyView()
          : _buildCollectionsList(),
    );
  }
  
  // 空视图
  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.collections_bookmark_outlined,
            size: 72,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            '您还没有收藏任何内容',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
  
  // 收藏列表
  Widget _buildCollectionsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      itemCount: _collectedItems.length,
      itemBuilder: (context, index) {
        final item = _collectedItems[index];
        final postObject = item['postObject'] as LCObject;
        final bool isProjectPost = postObject.className == 'ProjectPost';
        
        // 基于帖子类型渲染不同的卡片
        return _buildCollectionCard(item, index, isProjectPost);
      },
    );
  }
  
  // 收藏卡片
  Widget _buildCollectionCard(dynamic item, int index, bool isProjectPost) {
    final LCObject postObject = item['postObject'] as LCObject;
    final LCObject? publisher = postObject['publisher'] as LCObject?;
    
    // 获取发布者信息
    String publisherName = '未知用户';
    String? avatarUrl;
    
    try {
      if (publisher != null) {
        publisherName = publisher['nickname'] as String? ?? 
                        publisher['username'] as String? ?? 
                        '未知用户';
        
        if (publisher['icon'] != null) {
          final icon = publisher['icon'];
          if (icon != null && icon is LCFile) {
            avatarUrl = icon.url;
          }
        }
      }
    } catch (e) {
      print('获取发布者信息失败: $e');
    }
    
    // 获取帖子信息
    String title = '';
    String description = '';
    List<String> tags = [];
    
    if (isProjectPost) {
      title = postObject['projectName'] as String? ?? '';
      description = postObject['projectIntro'] as String? ?? '';
      
      // 获取项目标签
      if (postObject['projectTags'] != null) {
        final projectTags = postObject['projectTags'];
        if (projectTags is List) {
          tags = projectTags.map((tag) => tag.toString()).toList();
        }
      }
    } else {
      title = postObject['title'] as String? ?? '';
      description = postObject['detailedIntro'] as String? ?? '';
      
      // 获取技能标签
      if (postObject['coreSkillsTags'] != null) {
        final skillTags = postObject['coreSkillsTags'];
        if (skillTags is List) {
          tags = skillTags.map((tag) => tag.toString()).toList();
        }
      }
    }
    
    // 计算发布时间
    final DateTime createdAt = postObject.createdAt ?? DateTime.now();
    final String timeAgo = _getTimeAgo(createdAt);
    
    // 收藏数量
    final int collectionCount = postObject['collectionCount'] as int? ?? 0;
    
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
                postId: postObject.objectId!,
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
                        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                        child: avatarUrl == null
                            ? const Icon(Icons.person, color: Colors.grey)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      // 名称
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              publisherName,
                              style: const TextStyle(
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
                          color: isProjectPost ? Colors.green.withOpacity(0.1) : Colors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isProjectPost ? '项目' : '人才',
                          style: TextStyle(
                            color: isProjectPost ? Colors.green : Colors.purple,
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
            
            // 分割线 - 修改为不贯穿卡片的样式
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Divider(
                height: 1,
                thickness: 1,
                color: Colors.grey[200],
              ),
            ),
            
            // 底部操作栏
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 收藏数 - 移除星号图标，修改文字
                  Text(
                    '已被 $collectionCount 人收藏',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  
                  // 取消收藏按钮 - 修改样式
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: GestureDetector(
                      onTap: () => _uncollectPost(item, index),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.delete_outline,
                            size: 14,
                            color: Colors.red[400],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '取消收藏',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red[400],
                            ),
                          ),
                        ],
                      ),
                    ),
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
    // 根据帖子类型使用不同颜色
    Color bgColor = isProjectPost ? Colors.green[50]! : Colors.purple[50]!;
    Color textColor = isProjectPost ? Colors.green[700]! : Colors.purple[700]!;
    
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
  
  // 获取时间差描述
  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
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