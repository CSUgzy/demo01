import 'package:flutter/material.dart';
import 'package:leancloud_storage/leancloud.dart';
import '../../../models/project_post_model.dart';
import '../../../models/talent_post_model.dart';
import '../../../services/feed_service.dart';
import '../../../widgets/home/project_post_card.dart';
import '../../../widgets/home/talent_post_card.dart';
import '../../../constants/predefined_tags.dart';
import '../../screens/detail/post_detail_page.dart';
import '../../../services/notification_service.dart';
import '../notifications/notification_page.dart';
import '../../../utils/feedback_service.dart';
import '../search/search_result_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  // 状态变量
  List<dynamic> _allFeedItems = []; // 存储所有未筛选的数据
  List<dynamic> _displayedFeedItems = []; // 存储筛选后要显示的数据
  bool _isLoading = false;
  bool _canLoadMore = true;
  final ScrollController _scrollController = ScrollController();
  final FeedService _feedService = FeedService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  // 筛选相关状态
  String? _selectedDomain;
  String? _selectedMainIntent; // 可为 'Talent', 'Project', 或 null 表示"全部"

  // 通知服务
  final NotificationService _notificationService = NotificationService();
  // 未读通知数量
  int _unreadNotificationCount = 0;
  
  @override
  void initState() {
    super.initState();
    // 添加生命周期观察者
    WidgetsBinding.instance.addObserver(this);
    // 加载初始数据
    _loadInitialData();
    _loadUnreadNotificationCount();
    
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
    // 移除生命周期观察者
    WidgetsBinding.instance.removeObserver(this);
    // 移除滚动监听器
    _scrollController.dispose();
    // 销毁搜索控制器
    _searchController.dispose();
    // 销毁焦点节点
    _searchFocusNode.dispose();
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 当应用从后台恢复时，重新获取未读消息数量
      _loadUnreadNotificationCount();
    }
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
    // 首先获取所有内容的副本
    List<dynamic> filteredItems = List.from(_allFeedItems);
    
    // 应用主要意图筛选
    if (_selectedMainIntent != null) {
      filteredItems = filteredItems.where((item) {
        if (_selectedMainIntent == 'Project') {
          return item is ProjectPost;
        } else if (_selectedMainIntent == 'Talent') {
          return item is TalentPost;
        }
        return true; // 如果是null或其他值，不筛选
      }).toList();
    }
    
    // 应用领域筛选
    if (_selectedDomain != null) {
      filteredItems = filteredItems.where((item) {
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
    }
    
    _displayedFeedItems = filteredItems;
    
    // 打印筛选结果
    print('已筛选 ${_displayedFeedItems.length} 个内容，领域: $_selectedDomain，主要意图: $_selectedMainIntent');
  }

  // 更新筛选条件
  void _updateFilters({String? domain, String? mainIntent, bool apply = true}) {
    setState(() {
      if (domain != null) {
        _selectedDomain = domain;
      }
      if (mainIntent != null) {
        _selectedMainIntent = mainIntent;
      }
      if (apply) {
        _applyFilters();
      }
    });
  }

  // 下拉刷新
  Future<void> _onRefresh() async {
    await _loadInitialData();
  }

  // 显示错误提示
  void _showErrorSnackBar(String message) {
    if (mounted) {
      FeedbackService.showErrorSnackBar(context, message);
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
    return Stack(
      children: [
        Container(
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
        ),
        // 右侧筛选按钮（半透明背景）
        Positioned(
          right: 8,
          top: 0,
          bottom: 0,
          child: Center(
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.8),
              ),
              child: IconButton(
                icon: const Icon(Icons.filter_list, size: 20),
                padding: EdgeInsets.zero,
                onPressed: () {
                  _showFilterBottomSheet(context);
                },
                tooltip: '筛选',
                constraints: const BoxConstraints(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 显示筛选底部面板
  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      '筛选类型',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  RadioListTile<String?>(
                    title: const Text('全部'),
                    value: null,
                    groupValue: _selectedMainIntent,
                    onChanged: (value) {
                      setState(() {
                        _selectedMainIntent = value;
                      });
                      _updateFilters(mainIntent: value);
                      Navigator.pop(context);
                    },
                  ),
                  RadioListTile<String?>(
                    title: const Text('只看项目'),
                    value: 'Project',
                    groupValue: _selectedMainIntent,
                    onChanged: (value) {
                      setState(() {
                        _selectedMainIntent = value;
                      });
                      _updateFilters(mainIntent: value);
                      Navigator.pop(context);
                    },
                  ),
                  RadioListTile<String?>(
                    title: const Text('只看人才'),
                    value: 'Talent',
                    groupValue: _selectedMainIntent,
                    onChanged: (value) {
                      setState(() {
                        _selectedMainIntent = value;
                      });
                      _updateFilters(mainIntent: value);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 加载未读消息数量
  Future<void> _loadUnreadNotificationCount() async {
    try {
      if (await LCUser.getCurrent() != null) {
        final count = await _notificationService.getUnreadNotificationCount();
        if (mounted) {
          setState(() {
            _unreadNotificationCount = count;
          });
        }
      }
    } catch (e) {
      print("Error loading unread notification count: $e");
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

  // 导航到搜索结果页
  void _navigateToSearchResultPage(String keyword) async {
    final trimmedKeyword = keyword.trim();
    if (trimmedKeyword.isNotEmpty) {
      print('HomePage - 准备导航到搜索结果页，关键词: $trimmedKeyword');
      
      // 先清空搜索框，避免用户返回时看到之前的搜索词
      _searchController.clear();
      // 移除焦点
      _searchFocusNode.unfocus();
      
      // 导航到搜索结果页
      await Navigator.push(
        context, 
        MaterialPageRoute(
          builder: (context) => SearchResultPage(keyword: trimmedKeyword),
        )
      );
      
      print('HomePage - 从搜索结果页返回');
      
      // 从搜索结果页返回后，确保搜索框是空的
      if (_searchController.text.isNotEmpty) {
        _searchController.clear();
      }
    } else {
      print('HomePage - 搜索关键词为空，不导航');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 计算宽度收缩比例
    final double screenWidth = MediaQuery.of(context).size.width;
    final double contentWidth = screenWidth * 0.94; // 向内收缩4%
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            // 当整个容器被点击时，让输入框获得焦点
            _searchFocusNode.requestFocus();
          },
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: const InputDecoration(
                hintText: '搜索项目或人才',
                prefixIcon: Icon(Icons.search),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (String keyword) {
                _navigateToSearchResultPage(keyword);
              },
            ),
          ),
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_outlined),
                onPressed: _navigateToNotifications,
              ),
              if (_unreadNotificationCount > 0)
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
                      _unreadNotificationCount > 99 ? '99+' : '$_unreadNotificationCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
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