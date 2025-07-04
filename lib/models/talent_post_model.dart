import 'package:leancloud_storage/leancloud.dart';
import 'dart:convert';

class TalentPost {
  final String? objectId;
  final DateTime? createdAt;
  final DateTime? publishedAt;
  final dynamic publisher; // 发布者，可以是LCUser或LCObject
  final String title; // 个人定位/标题
  final String? detailedIntro; // 个人简介
  final List<String> coreSkillsTags; // 核心技能
  final String? cooperationType; // 合作类型，如"找项目"
  final String? workExperience; // 工作经验
  final String? educationBackground; // 教育背景
  final String? contactInfo; // 联系方式
  final String? portfolioUrl; // 作品集链接
  final List<String> expectedDomains; // 期望的工作领域

  TalentPost({
    this.objectId,
    this.createdAt,
    this.publishedAt,
    this.publisher,
    required this.title,
    this.detailedIntro,
    required this.coreSkillsTags,
    this.cooperationType,
    this.workExperience,
    this.educationBackground,
    this.contactInfo,
    this.portfolioUrl,
    this.expectedDomains = const [], // 默认为空列表
  });

  factory TalentPost.fromLCObject(LCObject object) {
    // 安全地处理coreSkillsTags字段
    List<String> parsedSkills = [];
    
    // 首先尝试解析coreSkillsTagsJson字段
    final String? skillsJson = object['coreSkillsTagsJson'] as String?;
    if (skillsJson != null && skillsJson.isNotEmpty) {
      try {
        final List<dynamic> decodedList = json.decode(skillsJson);
        for (var item in decodedList) {
          if (item is String) {
            parsedSkills.add(item);
          }
        }
      } catch (e) {
        print('Error parsing coreSkillsTagsJson: $e');
      }
    }
    
    // 如果coreSkillsTagsJson解析失败，尝试使用coreSkillsTags字段
    if (parsedSkills.isEmpty) {
      final rawSkills = object['coreSkillsTags'];
      if (rawSkills != null) {
        if (rawSkills is List) {
          for (var skill in rawSkills) {
            if (skill is String) {
              parsedSkills.add(skill);
            } else if (skill != null) {
              parsedSkills.add(skill.toString());
            }
          }
        } else if (rawSkills is String) {
          parsedSkills.add(rawSkills);
        }
      }
    }
    
    // 如果coreSkillsTags也解析失败，尝试使用旧的skills字段
    if (parsedSkills.isEmpty) {
      final rawSkills = object['skills'];
      if (rawSkills != null) {
        if (rawSkills is List) {
          for (var skill in rawSkills) {
            if (skill is String) {
              parsedSkills.add(skill);
            } else if (skill != null) {
              parsedSkills.add(skill.toString());
            }
          }
        } else if (rawSkills is String) {
          parsedSkills.add(rawSkills);
        }
      }
    }

    // 处理expectedDomains字段
    List<String> parsedDomains = [];
    
    // 首先尝试解析expectedDomainsJson字段
    final String? domainsJson = object['expectedDomainsJson'] as String?;
    if (domainsJson != null && domainsJson.isNotEmpty) {
      try {
        final List<dynamic> decodedList = json.decode(domainsJson);
        for (var item in decodedList) {
          if (item is String) {
            parsedDomains.add(item);
          }
        }
      } catch (e) {
        print('Error parsing expectedDomainsJson: $e');
      }
    }
    
    // 如果expectedDomainsJson解析失败，尝试使用expectedDomains字段
    if (parsedDomains.isEmpty) {
      final rawDomains = object['expectedDomains'];
      if (rawDomains != null) {
        if (rawDomains is List) {
          for (var domain in rawDomains) {
            if (domain is String) {
              parsedDomains.add(domain);
            } else if (domain != null) {
              parsedDomains.add(domain.toString());
            }
          }
        } else if (rawDomains is String) {
          parsedDomains.add(rawDomains);
        }
      }
    }
    
    // 如果expectedDomains字段也没有，尝试从domainTags获取
    if (parsedDomains.isEmpty) {
      final domainTags = object['domainTags'];
      if (domainTags != null) {
        if (domainTags is List) {
          for (var domain in domainTags) {
            if (domain is String) {
              parsedDomains.add(domain);
            } else if (domain != null) {
              parsedDomains.add(domain.toString());
            }
          }
        } else if (domainTags is String) {
          parsedDomains.add(domainTags);
        }
      }
    }

    // 处理publishedAt字段
    DateTime? publishedAt;
    final rawPublishedAt = object['publishedAt'];
    if (rawPublishedAt != null) {
      if (rawPublishedAt is DateTime) {
        publishedAt = rawPublishedAt;
      } else if (rawPublishedAt is String) {
        try {
          publishedAt = DateTime.parse(rawPublishedAt);
        } catch (e) {
          // 解析失败，保持null
        }
      }
    }

    return TalentPost(
      objectId: object.objectId,
      createdAt: object.createdAt,
      publishedAt: publishedAt,
      publisher: object['publisher'], // 直接使用原始publisher对象
      title: object['title'] as String? ?? '',
      detailedIntro: object['detailedIntro'] as String?,
      coreSkillsTags: parsedSkills,
      cooperationType: object['cooperationType'] as String?,
      workExperience: object['workExperience'] as String?,
      educationBackground: object['educationBackground'] as String?,
      contactInfo: object['contactInfo'] as String?,
      portfolioUrl: object['portfolioUrl'] as String?,
      expectedDomains: parsedDomains,
    );
  }
} 