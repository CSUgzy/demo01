import 'package:leancloud_storage/leancloud.dart';

class AppUser { // 避免与LCUser冲突
  final String objectId;
  final String? nickname;
  final String? avatarUrl;
  final List<String>? profileSystemTags; // 例如："技术大牛"

  AppUser({required this.objectId, this.nickname, this.avatarUrl, this.profileSystemTags});

  factory AppUser.fromLCUser(LCUser lcUser) {
    return AppUser(
      objectId: lcUser.objectId!,
      nickname: lcUser['nickname'] as String?,
      avatarUrl: (lcUser['icon'] as LCFile?)?.url,
      profileSystemTags: List<String>.from(lcUser['profileSystemTags'] as List? ?? []),
    );
  }
} 