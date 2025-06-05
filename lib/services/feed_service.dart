import 'package:leancloud_storage/leancloud.dart';
import '../models/project_post_model.dart';
import '../models/talent_post_model.dart';

class FeedService {
  int _projectPageSkip = 0;
  int _talentPageSkip = 0;
  final int _pageSize = 10; // 每页加载数量
  bool _useTestData = false; // 改为false，使用真实数据而非测试数据

  // 获取混合的帖子列表 (项目和人才)
  // 为了简化，可以先分别获取，然后在UI层混合，或在云函数中混合
  // 这里提供分别获取的示例

  Future<List<LCObject>> fetchProjectPosts({bool refresh = false}) async {
    if (refresh) {
      _projectPageSkip = 0;
    }
    
    // 使用测试数据
    if (_useTestData) {
      return _getTestProjectPosts();
    }
    
    try {
      LCQuery<LCObject> query = LCQuery('ProjectPost');
      query.include('publisher'); // 包含发布者信息
      query.orderByDescending('createdAt');
      query.skip(_projectPageSkip);
      query.limit(_pageSize);
      List<LCObject>? posts = await query.find();
      if (posts != null && posts.isNotEmpty) {
        _projectPageSkip += posts.length;
      }
      return posts ?? [];
    } catch (e) {
      print('Error fetching project posts: $e');
      return [];
    }
  }

  // 生成测试项目帖子数据
  List<LCObject> _getTestProjectPosts() {
    List<LCObject> testPosts = [];
    
    // 创建测试帖子1
    final post1 = LCObject('ProjectPost');
    post1['projectName'] = '智能课程推荐平台';
    post1['projectStatus'] = '产品研发中';
    post1['projectIntro'] = '基于AI技术的个性化学习平台，可根据学生的学习情况智能推荐课程。目前已有产品原型，正在寻找技术人才加入...';
    
    // 创建发布者信息
    final publisher1 = LCObject('_User');
    publisher1['nickname'] = '张创业';
    post1['publisher'] = publisher1;
    // 不要手动设置createdAt，这是LeanCloud保留字段
    post1['publishedAt'] = DateTime.now().subtract(const Duration(hours: 2)); // 使用自定义字段存储发布时间
    
    // 创建人才需求
    post1['talentNeeds'] = [
      {'role': '后端工程师', 'count': 1},
      {'role': 'UI设计师', 'count': 1}
    ];
    
    post1['projectTags'] = ['人工智能', '教育科技', '个性化学习'];
    
    // 创建测试帖子2
    final post2 = LCObject('ProjectPost');
    post2['projectName'] = '健康数据分析平台';
    post2['projectStatus'] = '创意阶段';
    post2['projectIntro'] = '通过可穿戴设备收集用户健康数据，利用AI算法分析并提供个性化健康建议。寻找对医疗健康领域有兴趣的技术合作伙伴。';
    
    // 创建发布者信息
    final publisher2 = LCObject('_User');
    publisher2['nickname'] = '李医生';
    post2['publisher'] = publisher2;
    // 不要手动设置createdAt，这是LeanCloud保留字段
    post2['publishedAt'] = DateTime.now().subtract(const Duration(hours: 5)); // 使用自定义字段存储发布时间
    
    // 创建人才需求
    post2['talentNeeds'] = [
      {'role': '数据科学家', 'count': 1},
      {'role': '移动开发工程师', 'count': 2},
      {'role': '产品经理', 'count': 1}
    ];
    
    post2['projectTags'] = ['健康科技', '数据分析', 'AI应用'];
    
    testPosts.add(post1);
    testPosts.add(post2);
    
    return testPosts;
  }

  Future<List<LCObject>> fetchTalentPosts({bool refresh = false}) async {
    if (refresh) {
      _talentPageSkip = 0;
    }
    
    // 使用测试数据
    if (_useTestData) {
      return _getTestTalentPosts();
    }
    
    try {
      LCQuery<LCObject> query = LCQuery('TalentPost');
      query.include('publisher'); // 包含发布者信息
      query.orderByDescending('createdAt');
      query.skip(_talentPageSkip);
      query.limit(_pageSize);
      List<LCObject>? posts = await query.find();
      if (posts != null && posts.isNotEmpty) {
        _talentPageSkip += posts.length;
      }
      return posts ?? [];
    } catch (e) {
      print('Error fetching talent posts: $e');
      return [];
    }
  }
  
  // 生成测试人才帖子数据
  List<LCObject> _getTestTalentPosts() {
    List<LCObject> testPosts = [];
    
    // 创建测试帖子1
    final post1 = LCObject('TalentPost');
    post1['title'] = '资深Java工程师寻求AI项目';
    post1['introduction'] = '5年Java开发经验，熟悉Spring Boot，微服务架构设计，对AI领域有浓厚兴趣，希望加入有前景的AI创业项目...';
    
    // 创建发布者信息
    final publisher1 = LCObject('_User');
    publisher1['nickname'] = '李工程';
    post1['publisher'] = publisher1;
    // 不要手动设置createdAt，这是LeanCloud保留字段
    post1['publishedAt'] = DateTime.now().subtract(const Duration(days: 1)); // 使用自定义字段存储发布时间
    
    post1['skills'] = ['Java', 'Spring Boot', '微服务', 'Docker', 'Kubernetes'];
    post1['cooperationType'] = '全职';
    post1['talentTags'] = ['后端开发', '架构设计', 'AI应用'];
    
    testPosts.add(post1);
    
    return testPosts;
  }

  // 将LCObject转换为模型对象的辅助方法
  List<ProjectPost> convertToProjectPosts(List<LCObject> objects) {
    List<ProjectPost> result = [];
    
    for (var obj in objects) {
      try {
        result.add(ProjectPost.fromLCObject(obj));
      } catch (e) {
        print('Error converting to ProjectPost: $e');
        // 跳过转换失败的对象
      }
    }
    
    return result;
  }

  List<TalentPost> convertToTalentPosts(List<LCObject> objects) {
    List<TalentPost> result = [];
    
    for (var obj in objects) {
      try {
        result.add(TalentPost.fromLCObject(obj));
      } catch (e) {
        print('Error converting to TalentPost: $e');
        // 跳过转换失败的对象
      }
    }
    
    return result;
  }

  // (可选) 获取混合并排序的Feed流
  Future<List<dynamic>> fetchMixedFeed({bool refresh = false}) async {
    try {
      // 分别获取项目和人才帖子
      List<LCObject> projectObjects = await fetchProjectPosts(refresh: refresh);
      List<LCObject> talentObjects = await fetchTalentPosts(refresh: refresh);
      
      // 转换为模型对象
      List<ProjectPost> projects = convertToProjectPosts(projectObjects);
      List<TalentPost> talents = convertToTalentPosts(talentObjects);
      
      // 创建混合列表并按创建时间排序
      List<dynamic> mixedFeed = [...projects, ...talents];
      mixedFeed.sort((a, b) {
        // 使用publishedAt或createdAt字段进行排序
        DateTime aTime = a.publishedAt ?? a.createdAt ?? DateTime.now();
        DateTime bTime = b.publishedAt ?? b.createdAt ?? DateTime.now();
        return bTime.compareTo(aTime); // 降序排序，最新的在前面
      });
      
      // 去重逻辑
      final Set<String> objectIds = {};
      final List<dynamic> uniqueFeed = [];

      for (var item in mixedFeed) {
        final String? objectId = item.objectId;
        if (objectId != null && !objectIds.contains(objectId)) {
          objectIds.add(objectId);
          uniqueFeed.add(item);
        }
      }

      // 返回去重后的列表
      return uniqueFeed;
    } catch (e) {
      print('Error fetching mixed feed: $e');
      return [];
    }
  }

  void resetPage() {
    _projectPageSkip = 0;
    _talentPageSkip = 0;
  }
} 