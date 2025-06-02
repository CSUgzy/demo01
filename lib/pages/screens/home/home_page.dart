import 'package:flutter/material.dart';
import '../../../models/project_post_model.dart';
import '../../../models/talent_post_model.dart';
import '../../../services/feed_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 状态变量
  List<dynamic> _feedItems = [];
  bool _isLoading = false;
  bool _canLoadMore = true;
  final ScrollController _scrollController = ScrollController();
  final FeedService _feedService = FeedService();

  @override
  void initState() {
    super.initState();
    // 加载初始数据
    _loadInitialData();
    
    // 添加滚动监听器，实现上拉加载更多
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= 
          _scrollController.position.maxScrollExtent - 200) {
        if (!_isLoading && _canLoadMore) {
          _loadMoreData();
        }
      }
    });
  }

  @override
  void dispose() {
    // 移除滚动监听器
    _scrollController.dispose();
    super.dispose();
  }

  // 加载初始数据
  Future<void> _loadInitialData() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // 使用FeedService获取混合Feed数据
      final feedItems = await _feedService.fetchMixedFeed(refresh: true);
      
      setState(() {
        _feedItems = feedItems;
        _isLoading = false;
        _canLoadMore = feedItems.isNotEmpty;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('加载数据失败: $e');
    }
  }

  // 加载更多数据
  Future<void> _loadMoreData() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // 获取更多数据
      final moreItems = await _feedService.fetchMixedFeed();
      
      setState(() {
        if (moreItems.isEmpty) {
          _canLoadMore = false;
        } else {
          _feedItems.addAll(moreItems);
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('加载更多数据失败: $e');
    }
  }

  // 下拉刷新
  Future<void> _onRefresh() async {
    await _loadInitialData();
  }

  // 显示错误提示
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  // 构建项目帖子卡片
  Widget _buildProjectPostCard(ProjectPost post) {
    // 临时实现，后续会创建专门的ProjectPostCard组件
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.business, color: Colors.blue),
                const SizedBox(width: 8.0),
                Text(
                  '项目: ${post.projectName}',
                  style: const TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Text(post.projectIntro),
            const SizedBox(height: 8.0),
            Wrap(
              spacing: 8.0,
              children: post.projectTags.map((tag) => Chip(
                label: Text(tag),
                backgroundColor: Colors.blue.withOpacity(0.1),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // 构建人才帖子卡片
  Widget _buildTalentPostCard(TalentPost post) {
    // 临时实现，后续会创建专门的TalentPostCard组件
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: Colors.purple),
                const SizedBox(width: 8.0),
                Text(
                  '人才: ${post.title}',
                  style: const TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Text(post.introduction ?? ''),
            const SizedBox(height: 8.0),
            Wrap(
              spacing: 8.0,
              children: post.skills.map((skill) => Chip(
                label: Text(skill),
                backgroundColor: Colors.purple.withOpacity(0.1),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
          ),
          child: const TextField(
            enabled: false, // 暂时禁用，只作为UI展示
            decoration: InputDecoration(
              hintText: '搜索项目或人才',
              prefixIcon: Icon(Icons.search),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // 筛选功能，暂未实现
            },
          ),
        ],
      ),
      body: _isLoading && _feedItems.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _feedItems.isEmpty
              ? const Center(child: Text('暂无内容'))
              : RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: _feedItems.length + (_isLoading && _canLoadMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _feedItems.length) {
                        // 显示底部加载指示器
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      
                      final item = _feedItems[index];
                      if (item is ProjectPost) {
                        return _buildProjectPostCard(item);
                      } else if (item is TalentPost) {
                        return _buildTalentPostCard(item);
                      }
                      
                      // 未知类型，返回空容器
                      return Container();
                    },
                  ),
                ),
    );
  }
} 