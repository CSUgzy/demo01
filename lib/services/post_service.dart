import 'dart:convert';
import 'package:leancloud_storage/leancloud.dart';

class PostService {
  // 获取当前登录用户
  Future<LCUser?> _getCurrentUser() async {
    return await LCUser.getCurrent();
  }

  // 发布项目需求
  Future<bool> createProjectPost({
    required String projectName,
    required String projectStatus,
    required String projectIntro,
    String? projectDetails,
    required List<Map<String, dynamic>> talentNeeds,
    required List<String> projectTags,
    String? contactWeChat,
    String? contactEmail,
    String? contactPhone,
    
  }) async {
    try {
      LCUser? currentUser = await _getCurrentUser();
      if (currentUser == null) {
        print('创建项目失败: 用户未登录');
        return false;
      }

      print('开始创建项目帖子...');
      
      // 创建一个简化版的项目需求对象
      LCObject projectPost = LCObject('ProjectPost');
      
      // 设置所有基本字段
      projectPost['projectName'] = projectName;
      projectPost['projectStatus'] = projectStatus;
      projectPost['projectIntro'] = projectIntro;
      projectPost['publisher'] = LCObject.createWithoutData('_User', currentUser.objectId!);
      projectPost['projectTags'] = projectTags;
      projectPost['collectionCount'] = 0; // 初始化收藏计数为0
      
      if (projectDetails != null) {
        projectPost['projectDetails'] = projectDetails;
      }
      
      if (contactWeChat != null && contactWeChat.isNotEmpty) {
        projectPost['contactWeChat'] = contactWeChat;
      }
      if (contactEmail != null && contactEmail.isNotEmpty) {
        projectPost['contactEmail'] = contactEmail;
      }
      if (contactPhone != null && contactPhone.isNotEmpty) {
        projectPost['contactPhone'] = contactPhone;
      }
      
      // 处理人才需求数据
      print('处理人才需求数据...');
      
      // 根据错误信息，talentNeeds应该是一个对象而不是数组
      // 将数组转换为对象格式，使用索引作为键
      try {
        Map<String, dynamic> talentNeedsObject = {};
        
        for (int i = 0; i < talentNeeds.length; i++) {
          var need = talentNeeds[i];
          talentNeedsObject['need_$i'] = {
            'role': need['role'].toString(),
            'skills': need['skills'],
            'count': need['count'] is int ? need['count'] : int.parse(need['count'].toString()),
            'cooperationType': need['cooperationType'].toString(),
            'workLocation': need['workLocation'],
          };
        }
        
        projectPost['talentNeeds'] = talentNeedsObject;
        print('保存talentNeeds为对象格式');
      } catch (e) {
        print('保存talentNeeds为对象格式失败: $e');
      }
      
      // 将talentNeeds转换为JSON字符串作为备份
      try {
        String talentNeedsJson = jsonEncode(talentNeeds);
        projectPost['talentNeedsJson'] = talentNeedsJson;
        print('保存talentNeedsJson字符串');
      } catch (e) {
        print('保存talentNeedsJson字符串失败: $e');
      }
      
      // 保存对象
      print('保存项目帖子到LeanCloud...');
      await projectPost.save();
      print('项目帖子保存成功!');
      return true;
    } catch (e) {
      if (e is LCException) {
        print('创建项目失败: 错误码 ${e.code}, 错误信息 ${e.message}');
      } else {
        print('创建项目失败: $e');
      }
      return false;
    }
  }

  // 发布合作意愿
  Future<bool> createTalentPost({
    required String title,
    required String coreSkillsText,
    required List<String> coreSkillsTags,
    required String detailedIntro,
    required List<String> expectedCooperationMethods,
    required List<String> expectedDomains,
    required String expectedCity,
    bool acceptsRemote = false,
    String? expectedSalary,
    String? contactWeChat,
    String? contactEmail,
    String? contactPhone
  }) async {
    try {
      print('开始创建人才帖子...');
      
      LCUser? currentUser = await _getCurrentUser();
      if (currentUser == null) {
        print('创建人才帖子失败: 用户未登录');
        return false;
      }
      
      print('当前用户ID: ${currentUser.objectId}');
      print('创建TalentPost对象...');
      
      LCObject talentPost = LCObject('TalentPost');
      
      // 尝试不同的方式设置发布者
      try {
        print('尝试方式1: 直接设置currentUser');
        talentPost['publisher'] = currentUser;
      } catch (e) {
        print('方式1失败: $e');
        try {
          print('尝试方式2: 使用createWithoutData');
          talentPost['publisher'] = LCObject.createWithoutData('_User', currentUser.objectId!);
        } catch (e) {
          print('方式2失败: $e');
          try {
            print('尝试方式3: 使用objectId字符串');
            talentPost['publisherId'] = currentUser.objectId;
          } catch (e) {
            print('方式3失败: $e');
          }
        }
      }
      
      print('设置基本字段...');
      talentPost['title'] = title;
      talentPost['coreSkillsText'] = coreSkillsText;
      talentPost['coreSkillsTags'] = coreSkillsTags;
      talentPost['detailedIntro'] = detailedIntro;
      talentPost['expectedCooperationMethods'] = expectedCooperationMethods;
      talentPost['expectedDomains'] = expectedDomains;
      talentPost['expectedCity'] = expectedCity;
      talentPost['acceptsRemote'] = acceptsRemote;
      talentPost['collectionCount'] = 0; // 初始化收藏计数为0

      print('设置可选字段...');
      if (expectedSalary != null && expectedSalary.isNotEmpty) talentPost['expectedSalary'] = expectedSalary;
      if (contactWeChat != null && contactWeChat.isNotEmpty) talentPost['contactWeChat'] = contactWeChat;
      if (contactEmail != null && contactEmail.isNotEmpty) talentPost['contactEmail'] = contactEmail;
      if (contactPhone != null && contactPhone.isNotEmpty) talentPost['contactPhone'] = contactPhone;

      print('保存TalentPost对象到LeanCloud...');
      print('核心技能标签: $coreSkillsTags');
      await talentPost.save();
      print('人才帖子保存成功!');
      return true;
    } catch (e) {
      if (e is LCException) {
        print('创建人才帖子失败: 错误码 ${e.code}, 错误信息 ${e.message}');
      } else {
        print('创建人才帖子失败: $e');
      }
      return false;
    }
  }

  // 获取单个帖子详情
  Future<LCObject?> fetchPostDetails(String postId, String className) async {
    try {
      LCQuery<LCObject> query = LCQuery(className); // className 会是 'ProjectPost' 或 'TalentPost'
      query.include('publisher'); // 非常重要，获取发布者完整信息
      // 如果有其他 Pointer 类型的字段需要完整信息，也在这里 include
      return await query.get(postId);
    } catch (e) {
      print('Error fetching post details for $postId in $className: $e');
      return null;
    }
  }

  // 收藏/取消收藏帖子的方法
  Future<bool> toggleCollectionStatus(String postId, String postType, bool currentCollectionState) async {
    LCUser? currentUser = await LCUser.getCurrent();
    if (currentUser == null) return false;

    try {
      // 获取帖子对象
      String className = postType == 'Project' ? 'ProjectPost' : 'TalentPost';
      LCObject post = LCObject.createWithoutData(className, postId);
      
      // 尝试获取完整的帖子数据，以便更新收藏计数
      try {
        await post.fetch();
      } catch (e) {
        print('获取帖子数据失败: $e');
        // 即使获取失败，我们仍然继续处理收藏状态
      }
      
      if (currentCollectionState) { // 如果当前是已收藏，则取消收藏
        LCQuery<LCObject> query = LCQuery('Collection');
        query.whereEqualTo('user', currentUser);
        query.whereEqualTo('postType', postType);
        // 根据 Module 2 中 Collection 表的设计，我们用两个Pointer字段
        if (postType == 'Project') {
            LCObject projectPointer = LCObject.createWithoutData('ProjectPost', postId);
            query.whereEqualTo('collectedProjectPost', projectPointer);
        } else if (postType == 'Talent') {
            LCObject talentPointer = LCObject.createWithoutData('TalentPost', postId);
            query.whereEqualTo('collectedTalentPost', talentPointer);
        }

        LCObject? collectionEntry = await query.first();
        if (collectionEntry != null) {
          await collectionEntry.delete();
          
          // 减少帖子的收藏计数
          try {
            int currentCount = post['collectionCount'] as int? ?? 0;
            if (currentCount > 0) {
              post['collectionCount'] = currentCount - 1;
              await post.save();
              print('帖子收藏计数减少到: ${currentCount - 1}');
            }
          } catch (e) {
            print('更新帖子收藏计数失败: $e');
          }
        }
      } else { // 如果当前未收藏，则添加收藏
        LCObject collectionEntry = LCObject('Collection');
        collectionEntry['user'] = currentUser;
        collectionEntry['postType'] = postType;
        if (postType == 'Project') {
            collectionEntry['collectedProjectPost'] = LCObject.createWithoutData('ProjectPost', postId);
        } else if (postType == 'Talent') {
            collectionEntry['collectedTalentPost'] = LCObject.createWithoutData('TalentPost', postId);
        }
        await collectionEntry.save();
        
        // 增加帖子的收藏计数
        try {
          int currentCount = post['collectionCount'] as int? ?? 0;
          post['collectionCount'] = currentCount + 1;
          await post.save();
          print('帖子收藏计数增加到: ${currentCount + 1}');
        } catch (e) {
          print('更新帖子收藏计数失败: $e');
        }
      }
      return true;
    } catch (e) {
      print('Error toggling collection status: $e');
      return false;
    }
  }

  // 检查帖子是否已被当前用户收藏
  Future<bool> isPostCollected(String postId, String postType) async {
    LCUser? currentUser = await LCUser.getCurrent();
    if (currentUser == null) return false;

    LCQuery<LCObject> query = LCQuery('Collection');
    query.whereEqualTo('user', currentUser);
    query.whereEqualTo('postType', postType);
    if (postType == 'Project') {
        query.whereEqualTo('collectedProjectPost', LCObject.createWithoutData('ProjectPost', postId));
    } else if (postType == 'Talent') {
        query.whereEqualTo('collectedTalentPost', LCObject.createWithoutData('TalentPost', postId));
    }
    // 设置limit为1，只需要知道是否存在即可
    query.limit(1);
    int? count = await query.count();
    return (count ?? 0) > 0;
  }

  // 获取当前用户发布的项目帖子
  Future<List<LCObject>> fetchCurrentUserProjectPosts({bool refresh = false}) async {
    LCUser? currentUser = await LCUser.getCurrent();
    if (currentUser == null) return [];

    try {
      LCQuery<LCObject> query = LCQuery('ProjectPost');
      query.whereEqualTo('publisher', currentUser); // 核心筛选条件
      query.include('publisher'); // 虽然是自己，但保持数据结构一致性
      query.orderByDescending('createdAt');
      // 为简化，先不实现分页，一次性获取所有，如果帖子多，后续再加入分页
      return await query.find() ?? [];
    } catch (e) {
      print('Error fetching current user project posts: $e');
      return [];
    }
  }

  // 获取当前用户发布的人才帖子
  Future<List<LCObject>> fetchCurrentUserTalentPosts({bool refresh = false}) async {
    LCUser? currentUser = await LCUser.getCurrent();
    if (currentUser == null) return [];

    try {
      LCQuery<LCObject> query = LCQuery('TalentPost');
      query.whereEqualTo('publisher', currentUser);
      query.include('publisher');
      query.orderByDescending('createdAt');
      return await query.find() ?? [];
    } catch (e) {
      print('Error fetching current user talent posts: $e');
      return [];
    }
  }

  // 删除帖子的方法 (通用)
  Future<bool> deletePost(String postId, String className) async {
    try {
      LCObject post = LCObject.createWithoutData(className, postId);
      await post.delete();
      return true;
    } catch (e) {
      print('Error deleting post $postId from $className: $e');
      return false;
    }
  }

  // 获取当前用户收藏列表
  Future<List<dynamic>> fetchCurrentUserCollections({bool refresh = false}) async {
    LCUser? currentUser = await LCUser.getCurrent();
    if (currentUser == null) return [];

    try {
      LCQuery<LCObject> query = LCQuery('Collection');
      query.whereEqualTo('user', currentUser); // 筛选当前用户的收藏记录
      query.orderByDescending('createdAt'); // 按收藏时间倒序

      // 为了在卡片上显示发布者信息，我们需要include嵌套的publisher
      query.include('collectedProjectPost');
      query.include('collectedProjectPost.publisher'); // 深入包含项目发布者
      query.include('collectedTalentPost');
      query.include('collectedTalentPost.publisher');  // 深入包含人才发布者

      List<LCObject>? collectionEntries = await query.find();

      if (collectionEntries == null || collectionEntries.isEmpty) {
        return [];
      }

      List<dynamic> collectedPosts = [];
      for (var entry in collectionEntries) {
        LCObject? post;
        if (entry['postType'] == 'Project' && entry['collectedProjectPost'] != null) {
          post = entry['collectedProjectPost'] as LCObject;
        } else if (entry['postType'] == 'Talent' && entry['collectedTalentPost'] != null) {
          post = entry['collectedTalentPost'] as LCObject;
        }

        if (post != null) {
          // 将LCObject转换为你的Flutter数据模型 (ProjectPost/TalentPost)
          // 例如:
          if (post.className == 'ProjectPost') {
            // collectedPosts.add(ProjectPost.fromLCObject(post)); // 假设你有 ProjectPost.fromLCObject
          } else if (post.className == 'TalentPost') {
            // collectedPosts.add(TalentPost.fromLCObject(post)); // 假设你有 TalentPost.fromLCObject
          }
          // 为简化，先直接返回LCObject，在UI层判断和转换，或确保模型转换已实现
          collectedPosts.add({'originalCollectionEntry': entry, 'postObject': post});
        }
      }

      return collectedPosts;

    } catch (e) {
      print('Error fetching current user collections: $e');
      return [];
    }
  }
} 