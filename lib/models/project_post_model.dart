import 'package:leancloud_storage/leancloud.dart';
import 'dart:convert';
import 'user_model.dart'; // 假设你有一个简化的UserModel来处理发布者信息

class ProjectPost {
  final String? objectId;
  final DateTime? createdAt;
  final DateTime? publishedAt;
  final dynamic publisher; // 修改为dynamic类型，可以接受LCUser或LCObject
  final String projectName;
  final String projectStatus;
  final String projectIntro;
  final String? projectDetails;
  final List<Map<String, dynamic>> talentNeeds; // [{role, skills, count, cooperationType, ...}]
  final List<String> projectTags;
  // 联系方式等其他字段...

  ProjectPost({
    this.objectId,
    this.createdAt,
    this.publishedAt,
    this.publisher,
    required this.projectName,
    required this.projectStatus,
    required this.projectIntro,
    this.projectDetails,
    required this.talentNeeds,
    required this.projectTags,
  });

  factory ProjectPost.fromLCObject(LCObject object) {
    // 安全地处理talentNeeds字段 - 从talentNeedsJson解析
    List<Map<String, dynamic>> parsedTalentNeeds = [];
    
    // 首先尝试解析talentNeedsJson字段
    final String? talentNeedsJson = object['talentNeedsJson'] as String?;
    if (talentNeedsJson != null && talentNeedsJson.isNotEmpty) {
      try {
        final List<dynamic> decodedList = json.decode(talentNeedsJson);
        for (var item in decodedList) {
          if (item is Map) {
            // 安全地转换Map<dynamic, dynamic>到Map<String, dynamic>
            final Map<String, dynamic> safeNeed = {};
            item.forEach((key, value) {
              if (key is String) {
                safeNeed[key] = value;
              }
            });
            parsedTalentNeeds.add(safeNeed);
          }
        }
      } catch (e) {
        print('Error parsing talentNeedsJson: $e');
      }
    }
    
    // 如果talentNeedsJson解析失败，尝试使用旧的talentNeeds字段
    if (parsedTalentNeeds.isEmpty) {
      final rawTalentNeeds = object['talentNeeds'];
      if (rawTalentNeeds != null) {
        if (rawTalentNeeds is List) {
          // 如果是列表，尝试解析每一个元素
          for (var need in rawTalentNeeds) {
            if (need is Map) {
              // 安全地转换Map<dynamic, dynamic>到Map<String, dynamic>
              final Map<String, dynamic> safeNeed = {};
              need.forEach((key, value) {
                if (key is String) {
                  safeNeed[key] = value;
                }
              });
              parsedTalentNeeds.add(safeNeed);
            }
          }
        } else if (rawTalentNeeds is Map) {
          // 如果是单个Map，也转换成列表中的一个元素
          final Map<String, dynamic> safeNeed = {};
          rawTalentNeeds.forEach((key, value) {
            if (key is String) {
              safeNeed[key] = value;
            }
          });
          parsedTalentNeeds.add(safeNeed);
        }
      }
    }
    
    // 安全地处理projectTags字段
    List<String> parsedProjectTags = [];
    final rawProjectTags = object['projectTags'];
    if (rawProjectTags != null) {
      if (rawProjectTags is List) {
        for (var tag in rawProjectTags) {
          if (tag is String) {
            parsedProjectTags.add(tag);
          } else if (tag != null) {
            // 如果不是字符串但也不是null，则转换为字符串
            parsedProjectTags.add(tag.toString());
          }
        }
      } else if (rawProjectTags is String) {
        // 如果是单个字符串，转换为列表
        parsedProjectTags.add(rawProjectTags);
      }
    }

    // 处理publishedAt字段
    DateTime? publishedAt;
    final rawPublishedAt = object['publishedAt'];
    if (rawPublishedAt != null) {
      if (rawPublishedAt is DateTime) {
        publishedAt = rawPublishedAt;
      } else if (rawPublishedAt is String) {
        // 尝试解析字符串为DateTime
        try {
          publishedAt = DateTime.parse(rawPublishedAt);
        } catch (e) {
          // 解析失败，保持null
        }
      }
    }

    return ProjectPost(
      objectId: object.objectId,
      createdAt: object.createdAt,
      publishedAt: publishedAt,
      publisher: object['publisher'], // 直接使用原始publisher对象，不进行类型转换
      projectName: object['projectName'] as String? ?? '',
      projectStatus: object['projectStatus'] as String? ?? '',
      projectIntro: object['projectIntro'] as String? ?? '',
      projectDetails: object['projectDetails'] as String?,
      talentNeeds: parsedTalentNeeds,
      projectTags: parsedProjectTags,
    );
  }
} 