import 'package:leancloud_storage/leancloud.dart';
import '../models/project_post_model.dart';
import '../models/talent_post_model.dart';

class FeedService {
  int _pageSkip = 0;
  final int _pageSize = 10; // 每页加载数量

  // 获取混合的帖子列表 (项目和人才)
  // 为了简化，可以先分别获取，然后在UI层混合，或在云函数中混合
  // 这里提供分别获取的示例

  Future<List<LCObject>> fetchProjectPosts({bool refresh = false}) async {
    if (refresh) {
      _pageSkip = 0;
    }
    try {
      LCQuery<LCObject> query = LCQuery('ProjectPost');
      query.include('publisher'); // 包含发布者信息
      query.orderByDescending('createdAt');
      query.skip(_pageSkip);
      query.limit(_pageSize);
      List<LCObject>? posts = await query.find();
      if (posts != null && posts.isNotEmpty) {
        _pageSkip += posts.length;
      }
      return posts ?? [];
    } catch (e) {
      print('Error fetching project posts: $e');
      return [];
    }
  }

  Future<List<LCObject>> fetchTalentPosts({bool refresh = false}) async {
    if (refresh) {
      _pageSkip = 0;
    }
    try {
      LCQuery<LCObject> query = LCQuery('TalentPost');
      query.include('publisher'); // 包含发布者信息
      query.orderByDescending('createdAt');
      query.skip(_pageSkip);
      query.limit(_pageSize);
      List<LCObject>? posts = await query.find();
      if (posts != null && posts.isNotEmpty) {
        _pageSkip += posts.length;
      }
      return posts ?? [];
    } catch (e) {
      print('Error fetching talent posts: $e');
      return [];
    }
  }

  // 将LCObject转换为模型对象的辅助方法
  List<ProjectPost> convertToProjectPosts(List<LCObject> objects) {
    return objects.map((obj) => ProjectPost.fromLCObject(obj)).toList();
  }

  List<TalentPost> convertToTalentPosts(List<LCObject> objects) {
    return objects.map((obj) => TalentPost.fromLCObject(obj)).toList();
  }

  // (可选) 获取混合并排序的Feed流
  Future<List<dynamic>> fetchMixedFeed({bool refresh = false}) async {
    // 分别获取项目和人才帖子
    List<LCObject> projectObjects = await fetchProjectPosts(refresh: refresh);
    List<LCObject> talentObjects = await fetchTalentPosts(refresh: refresh);
    
    // 转换为模型对象
    List<ProjectPost> projects = convertToProjectPosts(projectObjects);
    List<TalentPost> talents = convertToTalentPosts(talentObjects);
    
    // 创建混合列表并按创建时间排序
    List<dynamic> mixedFeed = [...projects, ...talents];
    mixedFeed.sort((a, b) {
      DateTime aTime = a.createdAt ?? DateTime.now();
      DateTime bTime = b.createdAt ?? DateTime.now();
      return bTime.compareTo(aTime); // 降序排序，最新的在前面
    });
    
    return mixedFeed;
  }

  void resetPage() {
    _pageSkip = 0;
  }
} 