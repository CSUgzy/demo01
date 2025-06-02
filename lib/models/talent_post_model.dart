import 'package:leancloud_storage/leancloud.dart';
import 'user_model.dart';

class TalentPost {
  final String objectId;
  final DateTime? createdAt;
  final LCUser? publisher; // 或者 UserModel publisher;
  final String title;
  final String? introduction;
  final List<String> skills;
  final String? cooperationType;
  final List<String> talentTags;

  TalentPost({
    required this.objectId,
    this.createdAt,
    this.publisher,
    required this.title,
    this.introduction,
    required this.skills,
    this.cooperationType,
    required this.talentTags,
  });

  factory TalentPost.fromLCObject(LCObject object) {
    return TalentPost(
      objectId: object.objectId!,
      createdAt: object.createdAt,
      publisher: object['publisher'] as LCUser?,
      title: object['title'] as String? ?? '',
      introduction: object['introduction'] as String?,
      skills: List<String>.from(object['skills'] as List? ?? []),
      cooperationType: object['cooperationType'] as String?,
      talentTags: List<String>.from(object['talentTags'] as List? ?? []),
    );
  }
} 