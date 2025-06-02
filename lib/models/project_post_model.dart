import 'package:leancloud_storage/leancloud.dart';
import 'user_model.dart'; // 假设你有一个简化的UserModel来处理发布者信息

class ProjectPost {
  final String objectId;
  final DateTime? createdAt;
  final LCUser? publisher; // 或者 UserModel publisher;
  final String projectName;
  final String projectStatus;
  final String projectIntro;
  final String? projectDetails;
  final List<Map<String, dynamic>> talentNeeds; // [{role, skills, count, cooperationType, ...}]
  final List<String> projectTags;
  // 联系方式等其他字段...

  ProjectPost({
    required this.objectId,
    this.createdAt,
    this.publisher,
    required this.projectName,
    required this.projectStatus,
    required this.projectIntro,
    this.projectDetails,
    required this.talentNeeds,
    required this.projectTags,
  });

  factory ProjectPost.fromLCObject(LCObject object) {
    return ProjectPost(
      objectId: object.objectId!,
      createdAt: object.createdAt,
      publisher: object['publisher'] as LCUser?, // 需要 include('publisher') 查询
      projectName: object['projectName'] as String? ?? '',
      projectStatus: object['projectStatus'] as String? ?? '',
      projectIntro: object['projectIntro'] as String? ?? '',
      projectDetails: object['projectDetails'] as String?,
      talentNeeds: List<Map<String, dynamic>>.from(object['talentNeeds'] as List? ?? []),
      projectTags: List<String>.from(object['projectTags'] as List? ?? []),
      // ... 解析其他字段
    );
  }
} 