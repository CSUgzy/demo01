import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:leancloud_storage/leancloud.dart';
import '../../models/talent_post_model.dart';

class TalentPostCard extends StatelessWidget {
  final TalentPost talentPost;
  final Function()? onTap;

  const TalentPostCard({
    Key? key,
    required this.talentPost,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    try {
      // 获取发布时间的相对表示
      final DateTime postTime = talentPost.publishedAt ?? talentPost.createdAt ?? DateTime.now();
      final String timeAgo = timeago.format(postTime, locale: 'zh_CN');
      
      // 获取发布者信息
      final publisher = talentPost.publisher;
      String? avatarUrl;
      String nickname = '用户';
      
      // 安全地获取发布者信息
      try {
        if (publisher != null) {
          // 尝试以不同方式获取昵称
          if (publisher is LCUser) {
            if (publisher['nickname'] != null) {
              nickname = publisher['nickname'].toString();
            } else if (publisher.username != null) {
              nickname = publisher.username!;
            }
            
            // 尝试从icon字段获取头像
            if (publisher['icon'] != null) {
              final icon = publisher['icon'];
              if (icon != null && icon is LCFile) {
                avatarUrl = icon.url;
                print('Found avatar URL from icon: $avatarUrl');
              }
            }
            
            // 如果icon字段没有头像，尝试从avatar字段获取
            if (avatarUrl == null && publisher['avatar'] != null) {
              final avatar = publisher['avatar'];
              if (avatar != null && avatar is LCFile) {
                avatarUrl = avatar.url;
                print('Found avatar URL from avatar: $avatarUrl');
              }
            }
          } else if (publisher is LCObject) {
            if (publisher['nickname'] != null) {
              nickname = publisher['nickname'].toString();
            }
            
            // 尝试从icon字段获取头像
            if (publisher['icon'] != null) {
              final icon = publisher['icon'];
              if (icon != null && icon is LCFile) {
                avatarUrl = icon.url;
                print('Found avatar URL from icon: $avatarUrl');
              }
            }
            
            // 如果icon字段没有头像，尝试从avatar字段获取
            if (avatarUrl == null && publisher['avatar'] != null) {
              final avatar = publisher['avatar'];
              if (avatar != null && avatar is LCFile) {
                avatarUrl = avatar.url;
                print('Found avatar URL from avatar: $avatarUrl');
              }
            }
          } else if (publisher is Map) {
            if (publisher.containsKey('nickname') && publisher['nickname'] != null) {
              nickname = publisher['nickname'].toString();
            }
            
            // 尝试从icon字段获取头像
            if (publisher.containsKey('icon') && publisher['icon'] != null) {
              final icon = publisher['icon'];
              if (icon != null && icon is LCFile) {
                avatarUrl = icon.url;
                print('Found avatar URL from icon: $avatarUrl');
              }
            }
            
            // 如果icon字段没有头像，尝试从avatar字段获取
            if (avatarUrl == null && publisher.containsKey('avatar') && publisher['avatar'] != null) {
              final avatar = publisher['avatar'];
              if (avatar != null && avatar is LCFile) {
                avatarUrl = avatar.url;
                print('Found avatar URL from avatar: $avatarUrl');
              }
            }
          }
        }
        
        // 调试输出发布者信息
        print('Publisher info - Nickname: $nickname, Avatar URL: $avatarUrl');
        if (publisher != null) {
          print('Publisher type: ${publisher.runtimeType}');
        }
      } catch (e) {
        print('Error getting publisher info: $e');
      }
      
      // 获取核心技能
      final List<String> skills = talentPost.coreSkillsTags;
      
      // 调试输出
      print('Talent: ${talentPost.title}, Skills: $skills');

      return Card(
        margin: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
        elevation: 1.5,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.0),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 顶部发布者信息
                Row(
                  children: [
                    // 头像
                    CircleAvatar(
                      radius: 22,
                      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                      backgroundColor: avatarUrl == null ? Colors.grey[300] : null,
                      child: avatarUrl == null
                          ? Text(nickname.isNotEmpty ? nickname[0].toUpperCase() : '?')
                          : null,
                    ),
                    const SizedBox(width: 14),
                    // 发布者昵称和发布时间
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nickname,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            timeAgo,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 右侧"找项目"标签
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.purple[50],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        talentPost.cooperationType ?? '找项目',
                        style: TextStyle(
                          color: Colors.purple[700],
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // 个人定位/标题
                Text(
                  talentPost.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // 个人简介/经验摘要
                if (talentPost.detailedIntro!= null && talentPost.detailedIntro!.isNotEmpty)
                  Text(
                    talentPost.detailedIntro!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15.5,
                      height: 1.5,
                    ),
                  ),
                
                // 添加分隔线
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: Container(
                    height: 1.0,
                    color: Colors.grey.withOpacity(0.1), // 非常浅的灰色
                  ),
                ),
                
                // 核心技能展示
                if (skills.isNotEmpty) Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '核心技能',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: skills.map((skill) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            skill,
                            style: TextStyle(
                              color: Colors.purple[800],
                              fontSize: 13,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      print('Error building TalentPostCard: $e');
      // 返回一个错误卡片而不是崩溃
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
        color: Colors.red[50],
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '加载人才卡片失败',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                '人才ID: ${talentPost.objectId ?? "未知"}',
                style: TextStyle(fontSize: 12.0, color: Colors.grey[600]),
              ),
              TextButton(
                onPressed: onTap,
                child: const Text('点击尝试查看详情'),
              ),
            ],
          ),
        ),
      );
    }
  }
} 