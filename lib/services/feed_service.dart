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

  /// 使用LeanCloud全文搜索功能实现搜索
  Future<Map<String, dynamic>> search(String keyword, {int skip = 0, int limit = 10}) async {
    if (keyword.isEmpty) return {'results': <LCObject>[], 'totalHits': 0, 'hasMore': false, 'currentSkip': skip};

    print('FeedService.search - 开始搜索关键词: $keyword, skip: $skip, limit: $limit');

    try {
      List<LCObject> allResults = [];
      int projectTotalHits = 0;
      int talentTotalHits = 0;
      
      // 创建项目帖子的搜索查询
      LCSearchQuery<LCObject> projectSearchQuery = LCSearchQuery<LCObject>('ProjectPost');
      projectSearchQuery.queryString(keyword);
      projectSearchQuery.limit(limit);
      projectSearchQuery.skip(skip);
      // 指定高亮显示的字段 - 使用字符串列表
      projectSearchQuery.highlights(['projectName', 'projectIntro']);
      // 包含发布者信息
      projectSearchQuery.include(['publisher']);
      
      print('FeedService.search - 准备执行项目搜索查询，skip: $skip, limit: $limit');
      
      // 执行项目搜索
      try {
        final projectResponse = await projectSearchQuery.find();
        print('FeedService.search - 项目搜索查询执行完成');
        
        if (projectResponse != null) {
          final results = projectResponse.results;
          if (results != null && results.isNotEmpty) {
            print('FeedService.search - 项目搜索返回结果数: ${results.length}');
            allResults.addAll(results);
            
            // 打印项目结果详情
            for (var project in results) {
              try {
                print('找到项目: ${project['projectName'] ?? '未知名称'}, ID: ${project.objectId}');
              } catch (e) {
                print('处理项目结果时出错: $e');
              }
            }
          }
          
          // 获取总命中数
          projectTotalHits = projectResponse.hits ?? 0;
          
          print('项目搜索结果数: $projectTotalHits, 当前返回: ${results?.length ?? 0}, skip: $skip, limit: $limit');
        } else {
          print('FeedService.search - 项目搜索响应为null');
        }
      } catch (e) {
        print('项目搜索出错: $e');
        print('错误堆栈: ${StackTrace.current}');
        // 继续执行人才搜索
      }
      
      print('FeedService.search - 准备执行人才搜索查询，skip: $skip, limit: $limit');
      
      // 创建人才帖子的搜索查询
      LCSearchQuery<LCObject> talentSearchQuery = LCSearchQuery<LCObject>('TalentPost');
      talentSearchQuery.queryString(keyword);
      talentSearchQuery.limit(limit);
      talentSearchQuery.skip(skip);
      // 指定高亮显示的字段 - 使用字符串列表
      talentSearchQuery.highlights(['title', 'detailedIntro', 'coreSkillsText']);
      // 包含发布者信息
      talentSearchQuery.include(['publisher']);
      
      // 执行人才搜索
      try {
        final talentResponse = await talentSearchQuery.find();
        print('FeedService.search - 人才搜索查询执行完成');
        
        if (talentResponse != null) {
          final results = talentResponse.results;
          if (results != null && results.isNotEmpty) {
            print('FeedService.search - 人才搜索返回结果数: ${results.length}');
            allResults.addAll(results);
            
            // 打印人才结果详情
            for (var talent in results) {
              try {
                print('找到人才: ${talent['title'] ?? '未知标题'}, ID: ${talent.objectId}');
              } catch (e) {
                print('处理人才结果时出错: $e');
              }
            }
          }
          
          // 获取总命中数
          talentTotalHits = talentResponse.hits ?? 0;
          
          print('人才搜索结果数: $talentTotalHits, 当前返回: ${results?.length ?? 0}, skip: $skip, limit: $limit');
        } else {
          print('FeedService.search - 人才搜索响应为null');
        }
      } catch (e) {
        print('人才搜索出错: $e');
        print('错误堆栈: ${StackTrace.current}');
      }
      
      // 计算总命中数
      int totalHits = projectTotalHits + talentTotalHits;
      
      print('FeedService.search - 搜索完成，总结果数: ${allResults.length}, 总命中数: $totalHits');
      
      // 按创建时间排序
      try {
        allResults.sort((a, b) {
          DateTime? aTime = a['createdAt'];
          DateTime? bTime = b['createdAt'];
          return (bTime ?? DateTime.now()).compareTo(aTime ?? DateTime.now());
        });
      } catch (e) {
        print('排序搜索结果时出错: $e');
        // 排序失败时不影响返回结果
      }
      
      // 计算是否有更多结果
      bool hasMore = (skip + allResults.length) < totalHits;
      
      // 返回结果、总命中数、是否有更多结果和当前skip值
      return {
        'results': allResults,
        'totalHits': totalHits,
        'hasMore': hasMore,
        'currentSkip': skip
      };
    } catch (e) {
      print('全文搜索执行出错: $e');
      print('错误堆栈: ${StackTrace.current}');
      
      // 如果全文搜索失败，回退到普通查询
      print('回退到普通查询...');
      return await searchWithRegularQuery(keyword);
    }
  }
  
  /// 使用普通查询实现搜索（临时解决方案）
  Future<Map<String, dynamic>> searchWithRegularQuery(String keyword) async {
    print('FeedService.searchWithRegularQuery - 使用普通查询搜索: $keyword');
    try {
      if (keyword.isEmpty) {
        print('FeedService.searchWithRegularQuery - 关键词为空，返回空结果');
        return {
          'results': <LCObject>[],
          'projectSid': null,
          'talentSid': null,
          'hasMore': false
        };
      }
      
      print('FeedService.searchWithRegularQuery - 开始执行搜索...');
      final results = await _fallbackSearch(keyword);
      print('FeedService.searchWithRegularQuery - 普通查询完成，结果数: ${results.length}');
      
      // 打印每个结果的类型和标识信息
      for (var obj in results) {
        try {
          if (obj.className == 'ProjectPost') {
            print('找到项目: ${obj['projectName'] ?? '未知项目名'}');
          } else if (obj.className == 'TalentPost') {
            print('找到人才: ${obj['title'] ?? '未知标题'}');
          } else {
            print('找到未知类型: ${obj.className}');
          }
        } catch (e) {
          print('处理搜索结果时出错: $e');
        }
      }
      
      return {
        'results': results,
        'projectSid': null,
        'talentSid': null,
        'hasMore': false // 普通查询不支持分页
      };
    } catch (e) {
      print('普通查询搜索出错: $e');
      print('错误堆栈: ${StackTrace.current}');
      return {
        'results': <LCObject>[],
        'projectSid': null,
        'talentSid': null,
        'hasMore': false
      };
    }
  }
  
  /// 普通查询搜索（作为全文搜索的备选方案）
  Future<List<LCObject>> _fallbackSearch(String keyword) async {
    print('FeedService._fallbackSearch - 开始执行普通查询: $keyword');
    try {
      // 搜索项目帖子
      LCQuery<LCObject> projectQuery = LCQuery('ProjectPost');
      projectQuery.whereContains('projectName', keyword);
      LCQuery<LCObject> projectIntroQuery = LCQuery('ProjectPost');
      projectIntroQuery.whereContains('projectIntro', keyword);
      LCQuery<LCObject> combinedProjectQuery = LCQuery.or([projectQuery, projectIntroQuery]);
      combinedProjectQuery.include('publisher');
      combinedProjectQuery.limit(10);
      
      // 搜索人才帖子
      LCQuery<LCObject> talentQuery = LCQuery('TalentPost');
      talentQuery.whereContains('title', keyword);
      LCQuery<LCObject> talentIntroQuery = LCQuery('TalentPost');
      talentIntroQuery.whereContains('detailedIntro', keyword);
      LCQuery<LCObject> talentSkillsQuery = LCQuery('TalentPost');
      talentSkillsQuery.whereContains('coreSkillsText', keyword);
      LCQuery<LCObject> combinedTalentQuery = LCQuery.or([talentQuery, talentIntroQuery, talentSkillsQuery]);
      combinedTalentQuery.include('publisher');
      combinedTalentQuery.limit(10);
      
      print('FeedService._fallbackSearch - 执行项目和人才查询');
      
      // 并行执行两个查询
      List<List<LCObject>?> results;
      try {
        results = await Future.wait([
          combinedProjectQuery.find(),
          combinedTalentQuery.find()
        ]);
        print('FeedService._fallbackSearch - 查询执行完成');
      } catch (e) {
        print('FeedService._fallbackSearch - 查询执行出错: $e');
        print('错误堆栈: ${StackTrace.current}');
        return [];
      }
      
      List<LCObject> projectResults = results[0] ?? [];
      List<LCObject> talentResults = results[1] ?? [];
      
      print('FeedService._fallbackSearch - 项目结果数: ${projectResults.length}, 人才结果数: ${talentResults.length}');
      
      // 打印项目结果详情
      for (var project in projectResults) {
        try {
          print('项目: ${project['projectName'] ?? '未知名称'}, ID: ${project.objectId}');
        } catch (e) {
          print('处理项目结果时出错: $e');
        }
      }
      
      // 打印人才结果详情
      for (var talent in talentResults) {
        try {
          print('人才: ${talent['title'] ?? '未知标题'}, ID: ${talent.objectId}');
        } catch (e) {
          print('处理人才结果时出错: $e');
        }
      }
      
      // 合并结果
      List<LCObject> allResults = [...projectResults, ...talentResults];
      
      // 按创建时间排序
      try {
        allResults.sort((a, b) {
          DateTime? aTime = a['createdAt'];
          DateTime? bTime = b['createdAt'];
          return (bTime ?? DateTime.now()).compareTo(aTime ?? DateTime.now());
        });
      } catch (e) {
        print('排序搜索结果时出错: $e');
        // 排序失败时不影响返回结果
      }
      
      print('FeedService._fallbackSearch - 返回合并结果，总数: ${allResults.length}');
      return allResults;
    } catch (e) {
      print('备选搜索出错: $e');
      print('错误堆栈: ${StackTrace.current}');
      return [];
    }
  }

  void resetPage() {
    _projectPageSkip = 0;
    _talentPageSkip = 0;
  }
} 