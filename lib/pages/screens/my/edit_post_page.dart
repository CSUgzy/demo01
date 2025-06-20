import 'package:flutter/material.dart';
import 'package:leancloud_storage/leancloud.dart';
import 'dart:convert';
import '../../../models/project_post_model.dart';
import '../../../models/talent_post_model.dart';
import '../../../services/post_service.dart';
import '../../screens/postings/create_project_post_page.dart';
import '../../screens/postings/create_talent_post_page.dart';
import 'package:city_pickers/city_pickers.dart';
import '../../../constants/predefined_tags.dart';
import '../../../constants/cooperation_options.dart';
import '../../../widgets/custom_dropdown_select.dart';
import '../../../utils/feedback_service.dart';

// 人才需求数据类 - 专门为编辑页面使用的修改版
class TalentRequirement {
  final TextEditingController roleController = TextEditingController();
  final TextEditingController countController = TextEditingController();
  final TextEditingController workLocationController = TextEditingController();
  String? selectedCooperationType;
  List<String> selectedSkills = []; // 非final，可以修改

  // 检查是否有效
  bool isValid() {
    return roleController.text.isNotEmpty &&
        selectedSkills.isNotEmpty &&
        countController.text.isNotEmpty &&
        selectedCooperationType != null;
  }

  // 清理控制器
  void dispose() {
    roleController.dispose();
    countController.dispose();
    workLocationController.dispose();
  }
}

class EditPostPage extends StatefulWidget {
  final String postId;
  final String postType; // "Project" 或 "Talent"

  const EditPostPage({
    Key? key,
    required this.postId,
    required this.postType,
  }) : super(key: key);

  @override
  State<EditPostPage> createState() => _EditPostPageState();
}

class _EditPostPageState extends State<EditPostPage> {
  final PostService _postService = PostService();
  bool _isLoading = true;
  LCObject? _post;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadPostData();
  }

  // 加载帖子数据
  Future<void> _loadPostData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      String className = widget.postType == "Project" ? "ProjectPost" : "TalentPost";
      final post = await _postService.fetchPostDetails(widget.postId, className);

      if (post == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = '帖子不存在或已被删除';
        });
        return;
      }

      setState(() {
        _post = post;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '加载帖子失败：$e';
      });
      print('加载帖子失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('编辑帖子')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('编辑帖子')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text(_errorMessage, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('返回'),
              ),
            ],
          ),
        ),
      );
    }

    if (_post == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('编辑帖子')),
        body: const Center(child: Text('无法加载帖子数据')),
      );
    }

    // 根据帖子类型选择不同的编辑界面
    if (widget.postType == "Project") {
      return _buildProjectPostEditor(_post!);
    } else {
      return _buildTalentPostEditor(_post!);
    }
  }

  // 构建项目帖子编辑器
  Widget _buildProjectPostEditor(LCObject post) {
    return EditProjectPostPage(post: post);
  }

  // 构建人才帖子编辑器
  Widget _buildTalentPostEditor(LCObject post) {
    return EditTalentPostPage(post: post);
  }
}

// 项目帖子编辑页面
class EditProjectPostPage extends StatefulWidget {
  final LCObject post;

  const EditProjectPostPage({
    Key? key,
    required this.post,
  }) : super(key: key);

  @override
  State<EditProjectPostPage> createState() => _EditProjectPostPageState();
}

class _EditProjectPostPageState extends State<EditProjectPostPage> {
  final _formKey = GlobalKey<FormState>();
  final _projectNameController = TextEditingController();
  final _projectIntroController = TextEditingController();
  String? _selectedProjectStatus;
  List<String> _selectedDomains = [];
  List<TalentRequirement> _talentRequirements = [];
  final _wechatController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  final PostService _postService = PostService();

  @override
  void initState() {
    super.initState();
    _initializeFormData();
  }

  // 初始化表单数据
  void _initializeFormData() {
    final post = widget.post;
    
    // 填充基本信息
    _projectNameController.text = post['projectName'] ?? '';
    _projectIntroController.text = post['projectIntro'] ?? '';
    _selectedProjectStatus = post['projectStatus'] ?? '';
    
    // 领域标签
    if (post['projectTags'] != null) {
      if (post['projectTags'] is List) {
        _selectedDomains = List<String>.from(post['projectTags']);
      }
    }
    
    // 联系方式
    if (post['contactWeChat'] != null) _wechatController.text = post['contactWeChat'];
    if (post['contactEmail'] != null) _emailController.text = post['contactEmail'];
    if (post['contactPhone'] != null) _phoneController.text = post['contactPhone'];
    
    // 处理人才需求
    _processTalentNeeds(post);
  }

  // 处理人才需求数据
  void _processTalentNeeds(LCObject post) {
    try {
      // 首先尝试从talentNeedsJson获取数据
      if (post['talentNeedsJson'] != null) {
        final jsonStr = post['talentNeedsJson'];
        final List<dynamic> talentNeedsData = jsonDecode(jsonStr);
        
        for (var need in talentNeedsData) {
          final req = TalentRequirement();
          req.roleController.text = need['role'] ?? '';
          req.selectedSkills = List<String>.from(need['skills'] ?? []);
          req.countController.text = need['count']?.toString() ?? '1';
          req.selectedCooperationType = need['cooperationType'] ?? '';
          if (need['workLocation'] != null) {
            req.workLocationController.text = need['workLocation'];
          }
          _talentRequirements.add(req);
        }
      } else if (post['talentNeeds'] != null && post['talentNeeds'] is Map) {
        // 如果talentNeeds是对象格式
        final Map<String, dynamic> needsMap = Map<String, dynamic>.from(post['talentNeeds']);
        
        for (var entry in needsMap.entries) {
          final need = entry.value;
          if (need is Map) {
            final req = TalentRequirement();
            req.roleController.text = need['role'] ?? '';
            if (need['skills'] is List) {
              req.selectedSkills = List<String>.from(need['skills'] ?? []);
            }
            req.countController.text = need['count']?.toString() ?? '1';
            req.selectedCooperationType = need['cooperationType'] ?? '';
            if (need['workLocation'] != null) {
              req.workLocationController.text = need['workLocation'];
            }
            _talentRequirements.add(req);
          }
        }
      }
      
      // 如果没有加载到任何人才需求，添加一个默认的
      if (_talentRequirements.isEmpty) {
        _talentRequirements.add(TalentRequirement());
      }
    } catch (e) {
      print('处理人才需求数据失败: $e');
      // 添加一个默认的人才需求
      _talentRequirements.add(TalentRequirement());
    }
  }

  @override
  void dispose() {
    _projectNameController.dispose();
    _projectIntroController.dispose();
    _wechatController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    
    // 清理人才需求控制器
    for (var req in _talentRequirements) {
      req.dispose();
    }
    
    super.dispose();
  }

  // 添加人才需求
  void _addTalentRequirement() {
    setState(() {
      _talentRequirements.add(TalentRequirement());
    });
  }

  // 移除人才需求
  void _removeTalentRequirement(int index) {
    setState(() {
      final requirement = _talentRequirements.removeAt(index);
      requirement.dispose();
    });
  }

  // 更新帖子
  Future<void> _updatePost() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedDomains.isEmpty) {
      FeedbackService.showToast(context, '请至少选择一个项目领域', isError: true);
      return;
    }

    if (_talentRequirements.isEmpty) {
      FeedbackService.showToast(context, '请至少添加一个人才需求', isError: true);
      return;
    }

    // 检查每个人才需求是否有效
    for (var requirement in _talentRequirements) {
      if (!requirement.isValid()) {
        FeedbackService.showToast(context, '请完善所有人才需求信息', isError: true);
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 准备人才需求数据
      final List<Map<String, dynamic>> talentNeedsData = _talentRequirements.map((req) {
        final List<String> skills = req.selectedSkills.map((s) => s.toString()).toList();
        final int count = int.parse(req.countController.text);
        
        return {
          'role': req.roleController.text,
          'skills': skills,
          'count': count,
          'cooperationType': req.selectedCooperationType,
          'workLocation': req.workLocationController.text.isNotEmpty ? req.workLocationController.text : null,
        };
      }).toList();

      // 调用更新方法
      final result = await _postService.updateProjectPost(
        postId: widget.post.objectId!,
        projectName: _projectNameController.text,
        projectStatus: _selectedProjectStatus!,
        projectIntro: _projectIntroController.text,
        talentNeeds: talentNeedsData,
        projectTags: _selectedDomains,
        contactWeChat: _wechatController.text.isEmpty ? null : _wechatController.text,
        contactEmail: _emailController.text.isEmpty ? null : _emailController.text,
        contactPhone: _phoneController.text.isEmpty ? null : _phoneController.text,
      );

      setState(() {
        _isLoading = false;
      });

      if (result && mounted) {
        // 显示成功提示
        FeedbackService.showSuccessToast(context, '项目帖子更新成功');
        // 返回上一页
        Navigator.of(context).pop(true);
      } else if (mounted) {
        FeedbackService.showErrorToast(context, '更新失败，请重试');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        FeedbackService.showErrorToast(context, '更新时出错: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 重用创建项目帖子页面的UI结构和样式
    // 只需要修改标题和提交按钮的处理函数
    
    // 获取屏幕宽度
    final screenWidth = MediaQuery.of(context).size.width;
    // 计算内边距值
    final paddingValue = screenWidth * 0.06;
    // 计算内容宽度
    final contentWidth = screenWidth - (paddingValue * 2);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('编辑项目帖子'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _updatePost,
            child: _isLoading 
              ? const SizedBox(
                  width: 16, 
                  height: 16, 
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                )
              : const Text('保存', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                paddingValue, 
                16.0, 
                paddingValue, 
                16.0
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 项目名称
                  _buildSectionTitle('项目名称/主题', true),
                  SizedBox(
                    width: contentWidth,
                    child: TextFormField(
                      controller: _projectNameController,
                      decoration: InputDecoration(
                        hintText: '请输入项目名称',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.0),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.0),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.0),
                          borderSide: BorderSide(color: Colors.blue.shade400),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        counterText: '${_projectNameController.text.length}/30',
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      maxLength: 30,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '请输入项目名称';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        setState(() {}); // 更新计数器
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 项目阶段
                  _buildSectionTitle('项目阶段', true),
                  CustomDropdownSelect<String>(
                    hint: '请选择当前项目所处阶段',
                    items: projectStatusOptions,
                    selectedItems: _selectedProjectStatus != null ? [_selectedProjectStatus!] : [],
                    onItemSelected: (value) {
                      setState(() {
                        _selectedProjectStatus = value;
                      });
                    },
                    onItemRemoved: (_) {
                      setState(() {
                        _selectedProjectStatus = null;
                      });
                    },
                    labelBuilder: (status) => status,
                    width: contentWidth,
                  ),
                  if (_selectedProjectStatus == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, left: 12.0),
                      child: Text(
                        '请选择项目阶段',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),

                  // 项目标签/领域
                  _buildSectionTitle('项目标签/领域', true),
                  CustomDropdownSelect<String>(
                    hint: '请添加项目所属领域标签，最多5个',
                    items: predefinedDomains.where((domain) => !_selectedDomains.contains(domain)).toList(),
                    selectedItems: _selectedDomains,
                    onItemSelected: (domain) {
                      setState(() {
                        if (!_selectedDomains.contains(domain)) {
                          if (_selectedDomains.length < 5) {
                            _selectedDomains.add(domain);
                          } else {
                            FeedbackService.showToast(
                              context, 
                              '最多只能选择5个领域标签',
                              isError: true
                            );
                          }
                        }
                      });
                    },
                    onItemRemoved: (domain) {
                      setState(() {
                        _selectedDomains.remove(domain);
                      });
                    },
                    labelBuilder: (domain) => domain,
                    isMultiSelect: true,
                    width: contentWidth,
                  ),
                  if (_selectedDomains.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, left: 12.0),
                      child: Text(
                        '请至少选择一个项目领域',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),

                  // 项目简介
                  _buildSectionTitle('项目简介', true),
                  SizedBox(
                    width: contentWidth,
                    child: TextFormField(
                      controller: _projectIntroController,
                      decoration: InputDecoration(
                        hintText: '请详细描述您的项目，包括背景、愿景、目前进展等',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.0),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.0),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.0),
                          borderSide: BorderSide(color: Colors.blue.shade400),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        alignLabelWithHint: true,
                        counterText: '${_projectIntroController.text.length}/1000',
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      maxLength: 1000,
                      maxLines: 8,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '请输入项目简介';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        setState(() {}); // 更新计数器
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 人才需求
                  _buildSectionTitle('人才需求', true),
                  const Text('请添加项目所需的人才需求'),
                  const SizedBox(height: 8),
                  ..._buildTalentRequirements(contentWidth),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: contentWidth,
                    child: ElevatedButton.icon(
                      onPressed: _addTalentRequirement,
                      icon: const Icon(Icons.add),
                      label: const Text('添加需求'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF5F7FA),
                        foregroundColor: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 联系方式
                  _buildSectionTitle('联系方式', false),
                  const Text('选填，公开后他人可见'),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: contentWidth,
                    child: _buildContactField(
                      controller: _wechatController,
                      label: '微信号',
                      hintText: '请填写您的微信号',
                      icon: Icons.wechat,
                      iconColor: const Color(0xFF07C160),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: contentWidth,
                    child: _buildContactField(
                      controller: _emailController,
                      label: '邮箱',
                      hintText: '请填写您的邮箱',
                      icon: Icons.mail_outline,
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: contentWidth,
                    child: _buildContactField(
                      controller: _phoneController,
                      label: '手机号',
                      hintText: '请填写您的手机号',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: _validatePhone,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // 提交按钮
                  SizedBox(
                    width: contentWidth,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _updatePost,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              '更新项目帖子',
                              style: TextStyle(
                                fontSize: 16, 
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 构建联系方式输入字段
  Widget _buildContactField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    Color? iconColor,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon, color: iconColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: BorderSide(color: Colors.blue.shade400),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        filled: true,
        fillColor: Colors.white,
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  // 邮箱格式验证
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return null; // 邮箱是选填的
    }
    
    // 使用正则表达式验证邮箱格式
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return '请输入有效的邮箱地址';
    }
    return null;
  }
  
  // 手机号格式验证
  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return null; // 手机号是选填的
    }
    
    // 验证中国大陆手机号格式（11位数字，以1开头）
    final phoneRegex = RegExp(r'^1[3-9]\d{9}$');
    if (!phoneRegex.hasMatch(value)) {
      return '请输入有效的手机号码';
    }
    return null;
  }

  // 构建表单区域标题
  Widget _buildSectionTitle(String title, bool isRequired) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (isRequired)
            const Text(
              '*',
              style: TextStyle(
                color: Colors.red,
                fontSize: 16,
              ),
            ),
        ],
      ),
    );
  }

  // 构建人才需求列表
  List<Widget> _buildTalentRequirements(double contentWidth) {
    return _talentRequirements.asMap().entries.map((entry) {
      final index = entry.key;
      final requirement = entry.value;
      
      return Container(
        width: contentWidth,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '需求 ${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (_talentRequirements.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeTalentRequirement(index),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            
            // 职位名称
            const Text('职位名称/角色'),
            const SizedBox(height: 4),
            TextFormField(
              controller: requirement.roleController,
              decoration: InputDecoration(
                hintText: '如：UI设计师',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: BorderSide(color: Colors.blue.shade400),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入职位名称';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // 技能要求
            const Text('技能要求'),
            const SizedBox(height: 4),
            CustomDropdownSelect<String>(
              hint: '请选择所需技能，最多5个',
              items: predefinedSkills
                .where((skill) => !requirement.selectedSkills.contains(skill)).toList(),
              selectedItems: requirement.selectedSkills,
              onItemSelected: (skill) {
                setState(() {
                  if (!requirement.selectedSkills.contains(skill)) {
                    if (requirement.selectedSkills.length < 5) {
                      requirement.selectedSkills.add(skill);
                    } else {
                      FeedbackService.showToast(
                        context, 
                        '每个需求最多选择5个技能',
                        isError: true
                      );
                    }
                  }
                });
              },
              onItemRemoved: (skill) {
                setState(() {
                  requirement.selectedSkills.remove(skill);
                });
              },
              labelBuilder: (skill) => skill,
              isMultiSelect: true,
              width: contentWidth - 32, // 减去Container的padding
            ),
            if (requirement.selectedSkills.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 0.0),
                child: Text(
                  '请至少选择一个技能',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            
            // 需求人数
            const Text('需求人数'),
            const SizedBox(height: 4),
            TextFormField(
              controller: requirement.countController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '请输入需求人数',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: BorderSide(color: Colors.blue.shade400),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入需求人数';
                }
                if (int.tryParse(value) == null || int.parse(value) <= 0) {
                  return '请输入有效的人数';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // 合作类型
            const Text('合作类型'),
            const SizedBox(height: 4),
            CustomDropdownSelect<String>(
              hint: '请选择合作类型',
              items: cooperationMethods,
              selectedItems: requirement.selectedCooperationType != null 
                ? [requirement.selectedCooperationType!] 
                : [],
              onItemSelected: (type) {
                setState(() {
                  requirement.selectedCooperationType = type;
                });
              },
              onItemRemoved: (_) {
                setState(() {
                  requirement.selectedCooperationType = null;
                });
              },
              labelBuilder: (type) => type,
              width: contentWidth - 32, // 减去Container的padding
            ),
            if (requirement.selectedCooperationType == null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 0.0),
                child: Text(
                  '请选择合作类型',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            
            // 工作地点
            const Text('所在城市'),
            const SizedBox(height: 4),
            TextFormField(
              controller: requirement.workLocationController,
              readOnly: true,
              onTap: () async {
                try {
                  final result = await CityPickers.showCityPicker(
                    context: context,
                    height: 300,
                    cancelWidget: Text(
                      '取消',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    confirmWidget: Text(
                      '确定',
                      style: TextStyle(color: Colors.blue[400]),
                    ),
                  );
                  
                  if (result != null) {
                    setState(() {
                      requirement.workLocationController.text = '${result.provinceName} ${result.cityName}';
                    });
                  }
                } catch (e) {
                  if (mounted) {
                    FeedbackService.showErrorToast(context, '选择城市失败: $e');
                  }
                }
              },
              decoration: InputDecoration(
                hintText: '点击选择城市',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: BorderSide(color: Colors.blue.shade400),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                suffixIcon: const Icon(Icons.location_city),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}

// 人才帖子编辑页面 
class EditTalentPostPage extends StatefulWidget {
  final LCObject post;

  const EditTalentPostPage({
    Key? key, 
    required this.post,
  }) : super(key: key);

  @override
  State<EditTalentPostPage> createState() => _EditTalentPostPageState();
}

class _EditTalentPostPageState extends State<EditTalentPostPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _detailedIntroController = TextEditingController();
  final _wechatController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  
  List<String> _selectedSkills = [];
  List<String> _selectedCooperationMethods = [];
  List<String> _selectedDomains = [];
  bool _isLoading = false;
  final PostService _postService = PostService();

  @override
  void initState() {
    super.initState();
    _initializeFormData();
  }

  // 初始化表单数据
  void _initializeFormData() {
    final post = widget.post;
    
    // 填充基本信息
    _titleController.text = post['title'] ?? '';
    _detailedIntroController.text = post['detailedIntro'] ?? '';
    _cityController.text = post['expectedCity'] ?? '';
    
    // 技能标签
    if (post['coreSkillsTags'] != null && post['coreSkillsTags'] is List) {
      _selectedSkills = List<String>.from(post['coreSkillsTags']);
    }
    
    // 合作方式
    if (post['expectedCooperationMethods'] != null && post['expectedCooperationMethods'] is List) {
      _selectedCooperationMethods = List<String>.from(post['expectedCooperationMethods']);
    }
    
    // 期望领域
    if (post['expectedDomains'] != null && post['expectedDomains'] is List) {
      _selectedDomains = List<String>.from(post['expectedDomains']);
    }
    
    // 联系方式
    if (post['contactWeChat'] != null) _wechatController.text = post['contactWeChat'];
    if (post['contactEmail'] != null) _emailController.text = post['contactEmail'];
    if (post['contactPhone'] != null) _phoneController.text = post['contactPhone'];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _detailedIntroController.dispose();
    _wechatController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  // 更新帖子
  Future<void> _updatePost() async {
    if (!_formKey.currentState!.validate()) return;
    
    // 验证必选项
    if (_selectedSkills.isEmpty) {
      FeedbackService.showToast(context, '请选择至少一项核心技能', isError: true);
      return;
    }

    if (_selectedCooperationMethods.isEmpty) {
      FeedbackService.showToast(context, '请选择至少一种期望合作方式', isError: true);
      return;
    }

    if (_selectedDomains.isEmpty) {
      FeedbackService.showToast(context, '请选择至少一个期望行业/领域', isError: true);
      return;
    }

    if (_cityController.text.isEmpty) {
      FeedbackService.showToast(context, '请选择期望城市', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 清理和格式化数据
      final String title = _titleController.text.trim();
      final String detailedIntro = _detailedIntroController.text.trim();
      final String coreSkillsText = _selectedSkills.join('、');
      final List<String> coreSkillsTags = List<String>.from(_selectedSkills);
      final List<String> cooperationMethods = List<String>.from(_selectedCooperationMethods);
      final List<String> domains = List<String>.from(_selectedDomains);
      final String city = _cityController.text.trim();
      
      // 清理联系方式
      String? wechat = _wechatController.text.trim();
      if (wechat.isEmpty) wechat = null;
      
      String? email = _emailController.text.trim();
      if (email.isEmpty) email = null;
      
      String? phone = _phoneController.text.trim();
      if (phone.isEmpty) phone = null;

      // 调用更新方法
      final result = await _postService.updateTalentPost(
        postId: widget.post.objectId!,
        title: title,
        coreSkillsText: coreSkillsText,
        coreSkillsTags: coreSkillsTags,
        detailedIntro: detailedIntro,
        expectedCooperationMethods: cooperationMethods,
        expectedDomains: domains,
        expectedCity: city,
        contactWeChat: wechat,
        contactEmail: email,
        contactPhone: phone,
      );

      setState(() {
        _isLoading = false;
      });

      if (result && mounted) {
        FeedbackService.showSuccessToast(context, '人才帖子更新成功');
        Navigator.of(context).pop(true);
      } else if (mounted) {
        FeedbackService.showErrorToast(context, '更新失败，请重试');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        FeedbackService.showErrorToast(context, '更新时出错: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 重用创建人才帖子页面的UI结构和样式
    // 获取屏幕宽度
    final screenWidth = MediaQuery.of(context).size.width;
    // 计算内边距值
    final paddingValue = screenWidth * 0.06;
    // 计算内容宽度
    final contentWidth = screenWidth - (paddingValue * 2);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('编辑人才帖子'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _updatePost,
            child: _isLoading 
              ? const SizedBox(
                  width: 16, 
                  height: 16, 
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                )
              : const Text('保存', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                paddingValue, 
                16.0, 
                paddingValue, 
                16.0
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 个人定位/标题
                  _buildSectionTitle('一句话介绍自己', true),
                  SizedBox(
                    width: contentWidth,
                    child: TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: '例如：3年经验UI设计师，擅长电商类产品设计',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.0),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.0),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.0),
                          borderSide: BorderSide(color: Colors.blue.shade400),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        counterText: '${_titleController.text.length}/30',
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      maxLength: 30,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '请输入一句话介绍';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        setState(() {}); // 更新计数器
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // 核心技能
                  _buildSectionTitle('核心技能', true),
                  CustomDropdownSelect<String>(
                    hint: '请选择您的核心技能，最多5个',
                    items: predefinedSkills
                      .where((skill) => !_selectedSkills.contains(skill)).toList(),
                    selectedItems: _selectedSkills,
                    onItemSelected: (skill) {
                      setState(() {
                        if (!_selectedSkills.contains(skill)) {
                          if (_selectedSkills.length < 5) {
                            _selectedSkills.add(skill);
                          } else {
                            FeedbackService.showToast(
                              context, 
                              '最多只能选择5个技能标签',
                              isError: true
                            );
                          }
                        }
                      });
                    },
                    onItemRemoved: (skill) {
                      setState(() {
                        _selectedSkills.remove(skill);
                      });
                    },
                    labelBuilder: (skill) => skill,
                    isMultiSelect: true,
                    width: contentWidth,
                  ),
                  if (_selectedSkills.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, left: 12.0),
                      child: Text(
                        '请至少选择一项核心技能',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),

                  // 详细自我介绍
                  _buildSectionTitle('详细自我介绍', true),
                  SizedBox(
                    width: contentWidth,
                    child: TextFormField(
                      controller: _detailedIntroController,
                      decoration: InputDecoration(
                        hintText: '请详细介绍您的专业背景、工作经验、技能专长等',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.0),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.0),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.0),
                          borderSide: BorderSide(color: Colors.blue.shade400),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        alignLabelWithHint: true,
                        counterText: '${_detailedIntroController.text.length}/1000',
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      maxLength: 1000,
                      maxLines: 8,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '请输入详细介绍';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        setState(() {}); // 更新计数器
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 期望合作方式
                  _buildSectionTitle('期望合作方式', true),
                  _buildCooperationMethodsSelector(),
                  const SizedBox(height: 20),

                  // 期望行业/领域
                  _buildSectionTitle('期望行业/领域', true),
                  CustomDropdownSelect<String>(
                    hint: '请添加期望合作的行业/领域标签，最多5个',
                    items: predefinedDomains
                      .where((domain) => !_selectedDomains.contains(domain)).toList(),
                    selectedItems: _selectedDomains,
                    onItemSelected: (domain) {
                      setState(() {
                        if (!_selectedDomains.contains(domain)) {
                          if (_selectedDomains.length < 5) {
                            _selectedDomains.add(domain);
                          } else {
                            FeedbackService.showToast(
                              context, 
                              '最多只能选择5个领域标签',
                              isError: true
                            );
                          }
                        }
                      });
                    },
                    onItemRemoved: (domain) {
                      setState(() {
                        _selectedDomains.remove(domain);
                      });
                    },
                    labelBuilder: (domain) => domain,
                    isMultiSelect: true,
                    width: contentWidth,
                  ),
                  if (_selectedDomains.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, left: 12.0),
                      child: Text(
                        '请至少选择一个期望领域',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),

                  // 期望城市
                  _buildSectionTitle('期望城市', true),
                  SizedBox(
                    width: contentWidth,
                    child: TextFormField(
                      controller: _cityController,
                      readOnly: true,
                      onTap: () async {
                        try {
                          final result = await CityPickers.showCityPicker(
                            context: context,
                            height: 300,
                            cancelWidget: Text(
                              '取消',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            confirmWidget: Text(
                              '确定',
                              style: TextStyle(color: Colors.blue[400]),
                            ),
                          );
                          
                          if (result != null) {
                            setState(() {
                              _cityController.text = '${result.provinceName} ${result.cityName}';
                            });
                          }
                        } catch (e) {
                          if (mounted) {
                            FeedbackService.showErrorToast(context, '选择城市失败: $e');
                          }
                        }
                      },
                      decoration: InputDecoration(
                        hintText: '点击选择期望工作城市',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.0),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.0),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.0),
                          borderSide: BorderSide(color: Colors.blue.shade400),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        suffixIcon: const Icon(Icons.location_city),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请选择期望城市';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 联系方式
                  _buildSectionTitle('联系方式', false),
                  const Text('选填，公开后他人可见'),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: contentWidth,
                    child: _buildContactField(
                      controller: _wechatController,
                      label: '微信号',
                      hintText: '请填写您的微信号',
                      icon: Icons.wechat,
                      iconColor: const Color(0xFF07C160),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: contentWidth,
                    child: _buildContactField(
                      controller: _emailController,
                      label: '邮箱',
                      hintText: '请填写您的邮箱',
                      icon: Icons.mail_outline,
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: contentWidth,
                    child: _buildContactField(
                      controller: _phoneController,
                      label: '手机号',
                      hintText: '请填写您的手机号',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: _validatePhone,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // 提交按钮
                  SizedBox(
                    width: contentWidth,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _updatePost,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              '更新人才帖子',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 构建联系方式输入字段
  Widget _buildContactField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    Color? iconColor,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon, color: iconColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: BorderSide(color: Colors.blue.shade400),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        filled: true,
        fillColor: Colors.white,
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }
  
  // 显示合作方式选择
  Widget _buildCooperationMethodsSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: cooperationMethods.map((method) {
            final isSelected = _selectedCooperationMethods.contains(method);
            return FilterChip(
              label: Text(method),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedCooperationMethods.add(method);
                  } else {
                    _selectedCooperationMethods.remove(method);
                  }
                });
              },
              selectedColor: const Color(0xFF3B82F6).withOpacity(0.2),
              backgroundColor: const Color(0xFFE2E8F0),
              side: const BorderSide(color: Colors.white),
              checkmarkColor: const Color(0xFF3B82F6),
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFF3B82F6) : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
        if (_selectedCooperationMethods.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 12.0),
            child: Text(
              '请至少选择一种合作方式',
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  // 邮箱格式验证
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return null; // 邮箱是选填的
    }
    
    // 使用正则表达式验证邮箱格式
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return '请输入有效的邮箱地址';
    }
    return null;
  }
  
  // 手机号格式验证
  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return null; // 手机号是选填的
    }
    
    // 验证中国大陆手机号格式（11位数字，以1开头）
    final phoneRegex = RegExp(r'^1[3-9]\d{9}$');
    if (!phoneRegex.hasMatch(value)) {
      return '请输入有效的手机号码';
    }
    return null;
  }

  // 构建表单区域标题
  Widget _buildSectionTitle(String title, bool isRequired) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (isRequired)
            const Text(
              '*',
              style: TextStyle(
                color: Colors.red,
                fontSize: 16,
              ),
            ),
        ],
      ),
    );
  }
} 