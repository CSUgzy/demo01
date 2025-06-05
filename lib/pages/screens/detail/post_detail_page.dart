import 'package:flutter/material.dart';
import 'package:leancloud_storage/leancloud.dart';
import '../../../models/user_model.dart';
import '../../../services/post_service.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'dart:convert';
import 'package:timeago/timeago.dart' as timeago;
import 'package:share_plus/share_plus.dart';

class PostDetailPage extends StatefulWidget {
  final String postId;
  final String postType; // 'Project' 或 'Talent'

  const PostDetailPage({
    Key? key,
    required this.postId,
    required this.postType,
  }) : super(key: key);

  @override
  _PostDetailPageState createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  LCObject? _postData;
  AppUser? _publisherData;
  bool _isLoading = true;
  bool _isCollected = false;

  @override
  void initState() {
    super.initState();
    _loadPostData();
  }

  // 加载帖子数据
  Future<void> _loadPostData() async {
    try {
      // 获取帖子数据
      String className = widget.postType == 'Project' ? 'ProjectPost' : 'TalentPost';
      print('加载$className帖子数据，ID: ${widget.postId}');
      final post = await PostService().fetchPostDetails(widget.postId, className);
      
      if (post != null) {
        print('成功获取帖子数据');
      }
      
      // 检查收藏状态
      final isCollected = await PostService().isPostCollected(widget.postId, widget.postType);
      
      if (mounted) {
        setState(() {
          _postData = post;
          
          // 如果成功获取到了帖子数据，解析发布者信息
          if (post != null && post['publisher'] != null) {
            final publisher = post['publisher'] as LCUser;
            _publisherData = AppUser.fromLCUser(publisher);
          }
          
          _isCollected = isCollected;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载帖子数据失败: $e')),
        );
      }
    }
  }

  // 切换收藏状态
  Future<void> _toggleCollectionStatus() async {
    try {
      bool success = await PostService().toggleCollectionStatus(
        widget.postId,
        widget.postType,
        _isCollected,
      );

      if (success && mounted) {
        setState(() {
          _isCollected = !_isCollected;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isCollected ? '已收藏' : '已取消收藏')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e')),
        );
      }
    }
  }

  // 联系发布者
  void _contactPublisher() {
    // 获取联系方式
    String? contactMethod;
    String? contactValue;
    
    // 优先使用电话，其次微信，再次邮箱
    if (_postData != null) {
      if (_postData!['contactPhone'] != null && _postData!['contactPhone'].toString().isNotEmpty) {
        contactMethod = 'phone';
        contactValue = _postData!['contactPhone'].toString();
      } else if (_postData!['contactWeChat'] != null && _postData!['contactWeChat'].toString().isNotEmpty) {
        contactMethod = 'wechat';
        contactValue = _postData!['contactWeChat'].toString();
      } else if (_postData!['contactEmail'] != null && _postData!['contactEmail'].toString().isNotEmpty) {
        contactMethod = 'email';
        contactValue = _postData!['contactEmail'].toString();
      }
    }

    if (contactMethod != null && contactValue != null) {
      switch (contactMethod) {
        case 'phone':
          _launchUrl('tel:$contactValue');
          break;
        case 'email':
          _launchUrl('mailto:$contactValue');
          break;
        case 'wechat':
          // 无法直接启动微信聊天
          _showContactDialog('微信号', contactValue);
          break;
      }
    } else {
      _showContactDialog('提示', '未提供联系方式');
    }
  }

  // 启动URL
  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await url_launcher.launchUrl(url)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('无法打开 $urlString')),
        );
      }
    }
  }

  // 显示联系方式对话框
  void _showContactDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('确定'),
          ),
        ],
      ),
    );
  }

  // 分享帖子
  void _sharePost() {
    if (_postData == null) return;
    
    String title = '';
    String description = '';
    
    if (widget.postType == 'Project') {
      title = _postData!['projectName'] ?? '未知项目';
      description = _postData!['projectIntro'] ?? '';
    } else {
      title = _postData!['title'] ?? '未知人才';
      description = _postData!['detailedIntro'] ?? '';
    }
    
    // 限制描述长度
    if (description.length > 100) {
      description = description.substring(0, 97) + '...';
    }
    
    String shareText = '来看看这个${widget.postType == "Project" ? "项目" : "人才"}：$title - 来自良师益友App';
    if (description.isNotEmpty) {
      shareText += '\n\n$description';
    }
    
    Share.share(shareText);
  }

  // 构建项目详情
  Widget _buildProjectDetails() {
    if (_postData == null) return Center(child: Text('无法加载项目详情'));
    return _buildProjectDetailsUI(_postData!, _publisherData);
  }
  
  // 构建项目详情UI
  Widget _buildProjectDetailsUI(LCObject projectData, AppUser? publisherData) {
    // 从 projectData 获取项目信息
    final String projectName = projectData['projectName'] ?? '未知项目';
    final String projectStatus = projectData['projectStatus'] ?? '未知状态';
    final String projectIntro = projectData['projectIntro'] ?? '暂无项目简介';
    final String? projectDetails = projectData['projectDetails'];
    final List<dynamic>? projectTags = projectData['projectTags'];
    final DateTime createdAt = projectData.createdAt ?? DateTime.now();
    final String timeAgo = timeago.format(createdAt, locale: 'zh_CN');
    
    // 获取人才需求
    List<Map<String, dynamic>> talentNeedsList = [];
    
    try {
      // 直接从talentNeedsJson获取人才需求（这是最可靠的方式）
      if (projectData['talentNeedsJson'] != null) {
        final String jsonStr = projectData['talentNeedsJson'];
        final List<dynamic> jsonList = json.decode(jsonStr);
        
        // 将JSON对象直接转换为Map<String, dynamic>
        for (var i = 0; i < jsonList.length; i++) {
          Map<String, dynamic> needMap = {};
          Map<dynamic, dynamic> originalItem = Map<dynamic, dynamic>.from(jsonList[i] as Map);
          
          // 显式复制所有字段
          originalItem.forEach((key, value) {
            needMap[key.toString()] = value;
          });
          
          talentNeedsList.add(needMap);
        }
      } else if (projectData['talentNeeds'] != null) {
        // 备用方法：如果没有talentNeedsJson，尝试从talentNeeds对象获取
        Map<dynamic, dynamic>? talentNeeds = projectData['talentNeeds'] as Map<dynamic, dynamic>;
        
        // 将对象转换为列表
        talentNeeds.forEach((key, value) {
          if (value is Map) {
            final Map<String, dynamic> needMap = Map<String, dynamic>.from(value);
            talentNeedsList.add(needMap);
          }
        });
      }
    } catch (e) {
      print('解析人才需求失败: $e');
    }
    
    // 联系方式
    final bool isContactPublic = projectData['isContactPublic'] ?? true; // 默认公开
    final String? contactWeChat = projectData['contactWeChat'];
    final String? contactEmail = projectData['contactEmail'];
    final String? contactPhone = projectData['contactPhone'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 发布者信息区块
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: Colors.white,
          ),
          child: Row(
            children: [
              // 头像
              CircleAvatar(
                radius: 24,
                backgroundImage: publisherData?.avatarUrl != null 
                    ? NetworkImage(publisherData!.avatarUrl!) 
                    : null,
                backgroundColor: publisherData?.avatarUrl == null ? Colors.grey[300] : null,
                child: publisherData?.avatarUrl == null
                    ? Text(publisherData?.nickname?.isNotEmpty == true 
                        ? publisherData!.nickname![0].toUpperCase() 
                        : '?',
                        style: TextStyle(color: Colors.white, fontSize: 20),
                    )
                    : null,
              ),
              const SizedBox(width: 12),
              // 发布者昵称和角色
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    publisherData?.nickname ?? '未知用户',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '项目发起人 · $timeAgo发布',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
     
        
        // 项目标题和内容
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 项目名称
              Text(
                projectName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 项目标签
              if (projectTags != null && projectTags.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...projectTags.map((tag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        tag.toString(),
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 13,
                        ),
                      ),
                    )).toList(),
                    // 项目状态标签
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        projectStatus,
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
        
        // 添加分割线
        Container(
          height: 8.0,
          color: Colors.grey.withOpacity(0.05),
        ),
        
        // 项目详情内容
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 项目详情标题
              const Text(
                '项目详情',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 项目简介
              Text(
                projectIntro,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Colors.black87,
                ),
              ),
              
              // 项目详细描述
              if (projectDetails != null && projectDetails.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  projectDetails,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
            ],
          ),
        ),
        
        // 添加分割线
        Container(
          height: 8.0,
          color: Colors.grey.withOpacity(0.05),
        ),
        
        // 人才需求
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '人才需求',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 人才需求列表
              if (talentNeedsList.isNotEmpty)
                ...talentNeedsList.map((need) {
                  // 调试信息
                  final String role = need['role']?.toString() ?? '未知职位';
                  final int count = need['count'] is int 
                      ? need['count'] 
                      : int.tryParse(need['count']?.toString() ?? '1') ?? 1;
                  final String cooperationType = need['cooperationType']?.toString() ?? '未知合作方式';
                  final List<dynamic>? skills = need['skills'] as List<dynamic>?;
                  final String? salaryRange = need['salaryRange']?.toString();
                  
                  // 获取workLocation
                  String? workLocation = need.containsKey('workLocation') ? need['workLocation']?.toString() : null;
                  
                  final bool isRemote = need['isRemote'] ?? false;
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 职位名称和需求数量
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              role,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '急需 · ${count}人',
                              style: TextStyle(
                                color: Colors.red[700],
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // 技能标签
                      if (skills != null && skills.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: skills.map((skill) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                skill.toString(),
                                style: TextStyle(
                                  color: Colors.grey[800],
                                  fontSize: 13,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      
                      const SizedBox(height: 12),
                      
                      // 工作信息
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            workLocation != null && workLocation.isNotEmpty 
                                ? workLocation 
                                : need.containsKey('workLocation') && need['workLocation'] != null 
                                    ? need['workLocation'].toString() 
                                    : '北京',
                            style: TextStyle(
                              color: Colors.grey[800],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.business_center, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            cooperationType,
                            style: TextStyle(
                              color: Colors.grey[800],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      
                      // 添加细分割线，除了最后一个需求
                      if (talentNeedsList.indexOf(need) < talentNeedsList.length - 1)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Container(
                            height: 1,
                            color: Colors.grey.withOpacity(0.3),
                            width: double.infinity,
                          ),
                        )
                      else
                        const SizedBox(height: 16),
                    ],
                  );
                }).toList()
              else
                Text(
                  '暂无人才需求信息',
                  style: TextStyle(color: Colors.grey[600]),
                ),
            ],
          ),
        ),
        
        // 添加分割线
        Container(
          height: 8.0,
          color: Colors.grey.withOpacity(0.05),
        ),
        
        // 联系方式
        if (isContactPublic) 
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '联系方式',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (contactPhone != null && contactPhone.isNotEmpty)
                  _buildContactItem(Icons.phone, '电话', contactPhone),
                if (contactWeChat != null && contactWeChat.isNotEmpty)
                  _buildContactItem(Icons.wechat, '微信', contactWeChat, isWechat: true),
                if (contactEmail != null && contactEmail.isNotEmpty)
                  _buildContactItem(Icons.email_outlined, '邮箱', contactEmail),
                if ((contactPhone == null || contactPhone.isEmpty) && 
                    (contactWeChat == null || contactWeChat.isEmpty) && 
                    (contactEmail == null || contactEmail.isEmpty))
                  const Text('发布者未提供联系方式'),
              ],
            ),
          ),
        
        // 底部间距
        const SizedBox(height: 80),
      ],
    );
  }
  
  // 构建带有圆点的文本项
  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.black87,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // 构建联系方式项
  Widget _buildContactItem(IconData icon, String label, String value, {bool isWechat = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          if (isWechat)
            Icon(
              Icons.wechat,
              size: 24,
              color: const Color(0xFF07C160),
            )
          else
            Icon(icon, size: 24, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              // 复制到剪贴板的逻辑
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '复制',
                style: TextStyle(
                  color: Colors.blue[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 构建人才详情
  Widget _buildTalentDetails() {
    if (_postData == null) return Center(child: Text('无法加载人才详情'));
    return _buildTalentDetailsUI(_postData!, _publisherData);
  }
  
  // 构建人才详情UI
  Widget _buildTalentDetailsUI(LCObject talentData, AppUser? publisherData) {
    // 从 talentData 获取人才信息
    final String title = talentData['title'] ?? '未知标题';
    final String? coreSkillsText = talentData['coreSkillsText'];
    final List<dynamic>? coreSkillsTags = talentData['coreSkillsTags'];
    final String? detailedIntro = talentData['detailedIntro'];
    final List<dynamic>? expectedCooperationMethods = talentData['expectedCooperationMethods'];
    final List<dynamic>? expectedDomains = talentData['expectedDomains'];
    final String? expectedCity = talentData['expectedCity'];
    final bool acceptsRemote = talentData['acceptsRemote'] ?? false;
    final String? expectedSalary = talentData['expectedSalary'];
    final DateTime createdAt = talentData.createdAt ?? DateTime.now();
    final String timeAgo = timeago.format(createdAt, locale: 'zh_CN');
    
    // 联系方式
    final bool isContactPublic = talentData['isContactPublic'] ?? true; // 默认公开
    final String? contactWeChat = talentData['contactWeChat'];
    final String? contactEmail = talentData['contactEmail'];
    final String? contactPhone = talentData['contactPhone'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 发布者信息区块
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            // border: Border(
            //   bottom: BorderSide(
            //     color: Colors.grey.withOpacity(0.2),
            //     width: 1,
            //   ),
            // ),
          ),
          child: Row(
            children: [
              // 头像
              CircleAvatar(
                radius: 24,
                backgroundImage: publisherData?.avatarUrl != null 
                    ? NetworkImage(publisherData!.avatarUrl!) 
                    : null,
                backgroundColor: publisherData?.avatarUrl == null ? Colors.grey[300] : null,
                child: publisherData?.avatarUrl == null
                    ? Text(publisherData?.nickname?.isNotEmpty == true 
                        ? publisherData!.nickname![0].toUpperCase() 
                        : '?')
                    : null,
              ),
              const SizedBox(width: 12),
              // 发布者昵称和发布时间
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    publisherData?.nickname ?? '未知用户',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${timeAgo}发布',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              Spacer(),
              // 状态标签
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '找项目',
                  style: TextStyle(
                    color: Colors.purple[700],
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // 人才标题和技能
        Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 人才标题
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
        
        // 添加分割线
        Container(
          height: 8.0,
          color: Colors.grey.withOpacity(0.05),
          width: double.infinity,
        ),
        
        Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 个人介绍标题
              const Text(
                '个人介绍',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 详细介绍
              if (detailedIntro != null && detailedIntro.isNotEmpty)
                Text(
                  detailedIntro,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                ),
                
              const SizedBox(height: 24),
            ],
          ),
        ),
        
        // 添加分割线
        Container(
          height: 8.0,
          color: Colors.grey.withOpacity(0.05),
          width: double.infinity,
        ),
        
        Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 核心技能
              const Text(
                '核心技能',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 核心技能标签
              if (coreSkillsTags != null && coreSkillsTags.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: coreSkillsTags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.purple[50],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        tag.toString(),
                        style: TextStyle(
                          color: Colors.purple[700],
                          fontSize: 13,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                
              const SizedBox(height: 12),
            ],
          ),
        ),
        
        // 添加分割线
        Container(
          height: 8.0,
          color: Colors.grey.withOpacity(0.05),
          width: double.infinity,
        ),
        
        // 期望合作
        Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '期望合作',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 期望行业领域
              if (expectedDomains != null && expectedDomains.isNotEmpty) ...[
                Text(
                  '期望加入的项目类型',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: expectedDomains.map((domain) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        domain.toString(),
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 13,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
              
              // 期望合作方式
              if (expectedCooperationMethods != null && expectedCooperationMethods.isNotEmpty) ...[
                Text(
                  '期望合作方式',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: expectedCooperationMethods.map((method) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        method.toString(),
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 13,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
              
              // 期望工作地点
              if (expectedCity != null && expectedCity.isNotEmpty || acceptsRemote) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '期望城市',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        if (expectedCity != null && expectedCity.isNotEmpty)
                          Text(
                            expectedCity,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        // if (expectedCity != null && expectedCity.isNotEmpty && acceptsRemote)
                        //   Text(
                        //     ' / ',
                        //     style: TextStyle(
                        //       fontSize: 16,
                        //       color: Colors.grey[600],
                        //     ),
                        //   ),
                        // if (acceptsRemote)
                        //   Text(
                        //     '远程',
                        //     style: TextStyle(
                        //       fontSize: 16,
                        //       color: Colors.black87,
                        //     ),
                        //   ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              
              // 期望薪资
              if (expectedSalary != null && expectedSalary.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.attach_money, size: 20, color: Colors.grey[600]),
                    const SizedBox(width: 12),
                    Text(
                      '期望薪资：',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      expectedSalary,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
        
        // 添加分割线
        Container(
          height: 8.0,
          color: Colors.grey.withOpacity(0.05),
          width: double.infinity,
        ),
        
        // 联系方式
        if (isContactPublic) 
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              // border: Border(
              //   top: BorderSide(
              //     color: Colors.grey.withOpacity(0.2),
              //     width: 1,
              //   ),
              // ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '联系方式',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (contactPhone != null && contactPhone.isNotEmpty)
                  _buildContactItem(Icons.phone, '电话', contactPhone),
                if (contactWeChat != null && contactWeChat.isNotEmpty)
                  _buildContactItem(Icons.wechat, '微信', contactWeChat, isWechat: true),
                if (contactEmail != null && contactEmail.isNotEmpty)
                  _buildContactItem(Icons.email_outlined, '邮箱', contactEmail),
                if ((contactPhone == null || contactPhone.isEmpty) && 
                    (contactWeChat == null || contactWeChat.isEmpty) && 
                    (contactEmail == null || contactEmail.isEmpty))
                  const Text('发布者未提供联系方式'),
              ],
            ),
          ),
        
        // 底部间距
        const SizedBox(height: 80),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.postType == 'Project' ? '项目详情' : '人才详情',
          style: TextStyle(color: Colors.black, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: Colors.black),
            onPressed: _sharePost,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _postData == null
              ? Center(child: Text('帖子不存在或已被删除'))
              : Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.96, // 宽度为屏幕的96%
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 根据帖子类型构建不同的详情内容
                          widget.postType == 'Project'
                              ? _buildProjectDetails()
                              : _buildTalentDetails(),
                        ],
                      ),
                    ),
                  ),
                ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              // 收藏按钮
              InkWell(
                onTap: _toggleCollectionStatus,
                child: Row(
                  children: [
                    Icon(
                      _isCollected ? Icons.star : Icons.star_border,
                      color: _isCollected ? Colors.amber : Colors.grey,
                      size: 24,
                    ),
                    SizedBox(width: 4),
                    Text(
                      '收藏',
                      style: TextStyle(
                        color: _isCollected ? Colors.amber : Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Spacer(),
              // 聊一聊按钮
              Container(
                width: 160,
                child: ElevatedButton(
                  onPressed: _contactPublisher,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1677FF),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 4.0),
                    minimumSize: Size(160, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    '聊一聊',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 