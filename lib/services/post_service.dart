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
    String? contactPhone
  }) async {
    try {
      final currentUser = await _getCurrentUser();
      if (currentUser == null) {
        throw Exception('用户未登录');
      }

      // 创建项目需求对象
      final projectPost = LCObject('ProjectPost');
      
      // 设置基本信息
      projectPost['projectName'] = projectName;
      projectPost['projectStatus'] = projectStatus;
      projectPost['projectIntro'] = projectIntro;
      projectPost['projectDetails'] = projectDetails;
      projectPost['projectTags'] = projectTags;
      projectPost['talentNeeds'] = talentNeeds;
      
      // 设置联系方式
      final contactInfo = {
        'wechat': contactWeChat,
        'email': contactEmail,
        'phone': contactPhone,
      };
      projectPost['contactInfo'] = contactInfo;
      
      // 设置创建者信息
      projectPost['createdBy'] = LCObject.createWithoutData('_User', currentUser.objectId!);
      projectPost['creatorUsername'] = currentUser['username'];
      
      // 保存到LeanCloud
      await projectPost.save();
      return true;
    } catch (e) {
      print('创建项目需求失败: $e');
      return false;
    }
  }

  // 发布合作意愿
  Future<bool> createTalentPost({
    required String title,
    required String cooperationStatement,
    required String coreSkillsText,
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
      final currentUser = await _getCurrentUser();
      if (currentUser == null) {
        throw Exception('用户未登录');
      }

      // 创建人才信息对象
      final talentPost = LCObject('TalentPost');
      
      // 设置基本信息
      talentPost['title'] = title;
      talentPost['cooperationStatement'] = cooperationStatement;
      talentPost['coreSkillsText'] = coreSkillsText;
      talentPost['detailedIntro'] = detailedIntro;
      talentPost['expectedCooperationMethods'] = expectedCooperationMethods;
      talentPost['expectedDomains'] = expectedDomains;
      talentPost['expectedCity'] = expectedCity;
      talentPost['acceptsRemote'] = acceptsRemote;
      talentPost['expectedSalary'] = expectedSalary;
      
      // 设置联系方式
      final contactInfo = {
        'wechat': contactWeChat,
        'email': contactEmail,
        'phone': contactPhone,
      };
      talentPost['contactInfo'] = contactInfo;
      
      // 设置创建者信息
      talentPost['createdBy'] = LCObject.createWithoutData('_User', currentUser.objectId!);
      talentPost['creatorUsername'] = currentUser['username'];
      
      // 保存到LeanCloud
      await talentPost.save();
      return true;
    } catch (e) {
      print('创建人才信息失败: $e');
      return false;
    }
  }
} 