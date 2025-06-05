import 'package:flutter/material.dart';
import 'package:leancloud_storage/leancloud.dart';
import '../../../models/project_post_model.dart';
import '../../../models/talent_post_model.dart';
import '../../../services/feed_service.dart';
import '../../../widgets/home/project_post_card.dart';
import '../../../widgets/home/talent_post_card.dart';
import '../../../constants/predefined_tags.dart';
import '../../screens/detail/post_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 状态变量
  List<dynamic> _allFeedItems = []; // 存储所有未筛选的数据
  List<dynamic> _displayedFeedItems = []; // 存储筛选后要显示的数据
  bool _isLoading = false;
  bool _canLoadMore = true;
  final ScrollController _scrollController = ScrollController();
  final FeedService _feedService = FeedService();
  
  // 筛选相关状态
  String? _selectedDomain;

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
        _allFeedItems = feedItems;
        _applyFilters(); // 应用当前筛选条件
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
    // 如果有筛选条件，暂时不支持加载更多
    if (_selectedDomain != null) return;
    
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
          _allFeedItems.addAll(moreItems);
          _applyFilters(); // 应用当前筛选条件
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

  // 应用筛选条件
  void _applyFilters() {
    if (_selectedDomain == null) {
      // 如果没有选中任何领域，显示所有内容
      _displayedFeedItems = List.from(_allFeedItems);
      return;
    }
    
    // 根据选中的领域筛选内容
    _displayedFeedItems = _allFeedItems.where((item) {
      if (item is ProjectPost) {
        // 检查项目标签中是否包含所选领域
        return item.projectTags.contains(_selectedDomain);
      } else if (item is TalentPost) {
        // 检查人才期望领域中是否包含所选领域
        if (item.expectedDomains.isNotEmpty) {
          return item.expectedDomains.contains(_selectedDomain);
        } else {
          // 如果expectedDomains为空，尝试从其他字段匹配，例如从coreSkillsTags或标题中
          // 这里是一个备选方案，如果数据不完整
          final String domainLower = _selectedDomain!.toLowerCase();
          
          // 检查标题中是否包含领域关键词
          if (item.title.toLowerCase().contains(domainLower)) {
            return true;
          }
          
          // 检查核心技能中是否有与领域相关的技能
          for (final skill in item.coreSkillsTags) {
            if (skill.toLowerCase().contains(domainLower)) {
              return true;
            }
          }
        }
        return false;
      }
      return false;
    }).toList();
    
    // 打印筛选结果
    print('已筛选 ${_displayedFeedItems.length} 个内容，领域: $_selectedDomain');
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
    return ProjectPostCard(
      projectPost: post,
      onTap: () {
        // 导航到项目详情页面
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailPage(
              postId: post.objectId!,
              postType: 'Project',
            ),
          ),
        );
      },
    );
  }

  // 构建人才帖子卡片
  Widget _buildTalentPostCard(TalentPost post) {
    return TalentPostCard(
      talentPost: post,
      onTap: () {
        // 导航到人才详情页面
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailPage(
              postId: post.objectId!,
              postType: 'Talent',
            ),
          ),
        );
      },
    );
  }

  // 构建横向滚动的标签栏
  Widget _buildTagsBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            // 全部标签
            Padding(
              padding: const EdgeInsets.only(right: 24.0),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedDomain = null;
                    _applyFilters(); // 应用筛选
                  });
                },
                child: Text(
                  '全部',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: _selectedDomain == null ? FontWeight.bold : FontWeight.normal,
                    color: _selectedDomain == null ? Colors.blue[700] : Colors.grey[600],
                  ),
                ),
              ),
            ),
            // 领域标签
            ...predefinedDomains.map((domain) {
              return Padding(
                padding: const EdgeInsets.only(right: 24.0),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedDomain = _selectedDomain == domain ? null : domain;
                      _applyFilters(); // 应用筛选
                    });
                  },
                  child: Text(
                    domain,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: _selectedDomain == domain ? FontWeight.bold : FontWeight.normal,
                      color: _selectedDomain == domain ? Colors.blue[700] : Colors.grey[600],
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 计算宽度收缩比例
    final double screenWidth = MediaQuery.of(context).size.width;
    final double contentWidth = screenWidth * 0.94; // 向内收缩4%
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
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
            icon: const Icon(Icons.notifications_none_outlined),
            tooltip: '消息',
            onPressed: () {
              // 导航到消息中心页面，暂时打印日志
              print('导航到消息中心页面');
              // TODO: 导航到NotificationPage
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(
              //     builder: (context) => NotificationPage(),
              //   ),
              // );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56.0),
          child: _buildTagsBar(),
        ),
      ),
      body: _isLoading && _displayedFeedItems.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _displayedFeedItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '暂无${_selectedDomain != null ? '相关' : ''}内容',
                        style: const TextStyle(fontSize: 16),
                      ),
                      if (_selectedDomain != null)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedDomain = null;
                              _applyFilters();
                            });
                          },
                          child: const Text('查看全部内容'),
                        ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: Center(
                    child: SizedBox(
                      width: contentWidth,
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: _displayedFeedItems.length + (_isLoading && _canLoadMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _displayedFeedItems.length) {
                            // 显示底部加载指示器
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          
                          final item = _displayedFeedItems[index];
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
                  ),
                ),
    );
  }
} 