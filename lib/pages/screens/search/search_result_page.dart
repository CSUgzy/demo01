import 'package:flutter/material.dart';
import 'package:leancloud_storage/leancloud.dart';
import '../../../models/project_post_model.dart';
import '../../../models/talent_post_model.dart';
import '../../../services/search_service.dart';
import '../../../widgets/home/project_post_card.dart';
import '../../../widgets/home/talent_post_card.dart';
import '../detail/post_detail_page.dart';

class SearchResultPage extends StatefulWidget {
  final String keyword;

  const SearchResultPage({Key? key, required this.keyword}) : super(key: key);

  @override
  State<SearchResultPage> createState() => _SearchResultPageState();
}

class _SearchResultPageState extends State<SearchResultPage> {
  final SearchService _searchService = SearchService();
  final ScrollController _scrollController = ScrollController();
  
  List<dynamic> _searchResults = [];
  bool _isLoading = false; // 初始设置为false
  bool _isLoadingMore = false;
  bool _hasMore = false;
  int _currentSkip = 0;
  int _totalHits = 0;
  final int _pageSize = 10;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    print('SearchResultPage - initState - 关键词: ${widget.keyword}');
    // 延迟一帧执行搜索，确保界面已经构建
    Future.microtask(() => _performInitialSearch());
    
    // 添加滚动监听器，实现上拉加载更多
    _scrollController.addListener(() {
      // 当滚动到距离底部200像素时，如果还有更多结果且不在加载中，则加载更多
      if (_scrollController.position.pixels >= 
          _scrollController.position.maxScrollExtent - 200) {
        if (!_isLoading && !_isLoadingMore && _hasMore) {
          print('SearchResultPage - 滚动触发加载更多');
          _loadMoreResults();
        }
      }
    });
  }
  
  @override
  void dispose() {
    print('SearchResultPage - dispose');
    _scrollController.dispose();
    super.dispose();
  }

  // 执行初始搜索
  Future<void> _performInitialSearch() async {
    print('SearchResultPage - _performInitialSearch - 开始');
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentSkip = 0; // 重置skip
    });

    try {
      print('SearchResultPage - 开始初始搜索: ${widget.keyword}, skip: $_currentSkip, limit: $_pageSize');
      
      // 使用SearchService执行搜索
      final searchResponse = await _searchService.search(
        widget.keyword,
        skip: _currentSkip,
        limit: _pageSize
      );
      
      // 获取结果列表
      final results = searchResponse['results'] as List<dynamic>;
      
      // 保存分页信息
      _totalHits = searchResponse['totalHits'] as int;
      _hasMore = searchResponse['hasMore'] as bool;
      _currentSkip = searchResponse['currentSkip'] as int;
      
      print('SearchResultPage - 搜索完成，结果数量: ${results.length}, 总命中数: $_totalHits, hasMore: $_hasMore');
      print('SearchResultPage - 当前skip: $_currentSkip, 下一页skip: ${_currentSkip + results.length}');
      
      if (mounted) { // 检查widget是否还在树中
        setState(() {
          _searchResults = results;
          _isLoading = false;
          // 更新下一页的skip值
          _currentSkip += results.length;
        });
      }
    } catch (e) {
      print('SearchResultPage - 搜索出错: $e');
      print('错误堆栈: ${StackTrace.current}');
      if (mounted) { // 检查widget是否还在树中
        setState(() {
          _errorMessage = '搜索出错: $e';
          _isLoading = false;
        });
      }
    }
  }
  
  // 加载更多搜索结果
  Future<void> _loadMoreResults() async {
    if (_isLoadingMore || !_hasMore) return;
    
    print('SearchResultPage - _loadMoreResults - 开始');
    print('SearchResultPage - 当前skip: $_currentSkip, pageSize: $_pageSize');
    
    setState(() {
      _isLoadingMore = true;
    });

    try {
      print('SearchResultPage - 加载更多结果: ${widget.keyword}, skip: $_currentSkip, limit: $_pageSize');
      
      // 使用当前skip值继续搜索
      final searchResponse = await _searchService.search(
        widget.keyword,
        skip: _currentSkip,
        limit: _pageSize
      );
      
      // 获取结果列表
      final newResults = searchResponse['results'] as List<dynamic>;
      
      // 更新分页信息
      _totalHits = searchResponse['totalHits'] as int;
      _hasMore = searchResponse['hasMore'] as bool;
      
      print('SearchResultPage - 加载更多完成，新结果数量: ${newResults.length}, 总命中数: $_totalHits, hasMore: $_hasMore');
      
      if (newResults.isEmpty) {
        print('SearchResultPage - 加载更多返回了空结果，设置hasMore=false');
        _hasMore = false;
      }
      
      // 检查是否有重复项
      final Set<String> existingIds = _searchResults
          .where((item) => item != null && item.objectId != null)
          .map<String>((item) => item.objectId)
          .toSet();
      
      print('SearchResultPage - 现有结果ID数量: ${existingIds.length}');
          
      final uniqueNewResults = newResults
          .where((item) => item != null && item.objectId != null && !existingIds.contains(item.objectId))
          .toList();
      
      print('SearchResultPage - 过滤后的新结果数量: ${uniqueNewResults.length}');
      
      if (mounted) { // 检查widget是否还在树中
        setState(() {
          _searchResults.addAll(uniqueNewResults);
          _isLoadingMore = false;
          // 更新下一页的skip值
          _currentSkip += newResults.length;
        });
      }
    } catch (e) {
      print('SearchResultPage - 加载更多搜索结果出错: $e');
      print('错误堆栈: ${StackTrace.current}');
      if (mounted) { // 检查widget是否还在树中
        setState(() {
          _isLoadingMore = false;
          // 加载更多失败时，设置hasMore为false，避免继续尝试
          _hasMore = false;
        });
      }
    }
  }
  
  // 下拉刷新
  Future<void> _onRefresh() async {
    print('SearchResultPage - _onRefresh - 开始');
    // 重置状态
    _currentSkip = 0;
    _totalHits = 0;
    _hasMore = false;
    await _performInitialSearch();
    return Future.value();
  }

  @override
  Widget build(BuildContext context) {
    print('SearchResultPage - build - isLoading: $_isLoading, resultsCount: ${_searchResults.length}, hasMore: $_hasMore, totalHits: $_totalHits');
    
    // 计算宽度收缩比例
    final double screenWidth = MediaQuery.of(context).size.width;
    final double contentWidth = screenWidth * 0.94; // 向内收缩4%
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('搜索: ${widget.keyword}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _searchResults.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '未找到与"${widget.keyword}"相关的内容',
                            style: const TextStyle(fontSize: 16),
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
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            itemCount: _searchResults.length + (_isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _searchResults.length) {
                                // 显示底部加载指示器
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              
                              final item = _searchResults[index];
                              if (item is ProjectPost) {
                                return _buildProjectPostCard(item);
                              } else if (item is TalentPost) {
                                return _buildTalentPostCard(item);
                              }
                              
                              // 未知类型，返回空容器
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                    ),
    );
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
} 