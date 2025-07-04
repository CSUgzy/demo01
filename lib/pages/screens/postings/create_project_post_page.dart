import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:city_pickers/city_pickers.dart';
import '../../../constants/predefined_tags.dart';
import '../../../constants/cooperation_options.dart';
import '../../../services/post_service.dart';
import '../../../widgets/custom_dropdown_select.dart';
import '../../../utils/feedback_service.dart';

// 定义一些全局样式常量
const Color borderColor = Color(0xFFE2E8F0); // 边框颜色 - 浅灰色
const double borderRadius = 16.0; // 边框圆角
const EdgeInsets contentPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 16); // 内边距
const double horizontalPadding = 0.06; // 水平方向的内边距比例
const Color wechatGreen = Color(0xFF07C160); // 微信绿色
const Color themeBlue = Color(0xFF3B82F6); // 主题蓝色

class CreateProjectPostPage extends StatefulWidget {
  const CreateProjectPostPage({super.key});

  @override
  State<CreateProjectPostPage> createState() => _CreateProjectPostPageState();
}

class _CreateProjectPostPageState extends State<CreateProjectPostPage> {
  final _formKey = GlobalKey<FormState>();
  final _projectNameController = TextEditingController();
  final _projectIntroController = TextEditingController();
  String? _selectedProjectStatus;
  final List<String> _selectedDomains = [];
  final List<TalentRequirement> _talentRequirements = [];
  final _wechatController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  
  bool _isLoading = false;
  final TextEditingController _domainSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 添加一个初始的人才需求
    _addTalentRequirement();
  }

  @override
  void dispose() {
    _projectNameController.dispose();
    _projectIntroController.dispose();
    _wechatController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _domainSearchController.dispose();
    
    // 清理所有人才需求中的控制器
    for (var requirement in _talentRequirements) {
      requirement.dispose();
    }
    
    super.dispose();
  }

  void _addTalentRequirement() {
    setState(() {
      _talentRequirements.add(TalentRequirement());
    });
  }

  void _removeTalentRequirement(int index) {
    setState(() {
      final requirement = _talentRequirements.removeAt(index);
      requirement.dispose();
    });
  }

  // 添加领域标签
  void _addDomain(String domain) {
    setState(() {
      if (!_selectedDomains.contains(domain)) {
        if (_selectedDomains.length < 5) {
          _selectedDomains.add(domain);
          _domainSearchController.clear();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('最多只能选择5个领域标签')),
          );
        }
      }
    });
  }

  // 移除领域标签
  void _removeDomain(String domain) {
    setState(() {
      _selectedDomains.remove(domain);
    });
  }

  // 添加城市选择方法
  Future<void> _showCityPicker(TalentRequirement requirement) async {
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
          style: TextStyle(color: themeBlue),
        ),
      );
      
      if (result != null) {
        setState(() {
          requirement.workLocationController.text = '${result.provinceName} ${result.cityName}';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择城市失败: $e')),
        );
      }
    }
  }

  // 提交表单
  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedDomains.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请至少选择一个项目领域')),
        );
        return;
      }

      if (_talentRequirements.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请至少添加一个人才需求')),
        );
        return;
      }

      // 检查每个人才需求是否有效
      for (var requirement in _talentRequirements) {
        if (!requirement.isValid()) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('请完善所有人才需求信息')),
          );
          return;
        }
      }

      setState(() {
        _isLoading = true;
      });

      try {
        // 准备人才需求数据
        final List<Map<String, dynamic>> talentNeedsData = _talentRequirements.map((req) {
          // 确保skills是List<String>而不是其他类型
          final List<String> skills = req.selectedSkills.map((s) => s.toString()).toList();
          
          // 确保count是整数
          final int count = int.parse(req.countController.text);
          
          return {
            'role': req.roleController.text,
            'skills': skills,
            'count': count,
            'cooperationType': req.selectedCooperationType,
            'workLocation': req.workLocationController.text.isNotEmpty ? req.workLocationController.text : null,
          };
        }).toList();
        
        // 调试信息
        print('准备提交的人才需求数据:');
        print(talentNeedsData);

        // 使用PostService发布项目需求
        final postService = PostService();
        final result = await postService.createProjectPost(
          projectName: _projectNameController.text,
          projectStatus: _selectedProjectStatus!,
          projectIntro: _projectIntroController.text,
          talentNeeds: talentNeedsData,
          projectTags: _selectedDomains,
          contactWeChat: _wechatController.text.isEmpty ? null : _wechatController.text,
          contactEmail: _emailController.text.isEmpty ? null : _emailController.text,
          contactPhone: _phoneController.text.isEmpty ? null : _phoneController.text,
        );

        // 设置加载状态为false
        setState(() {
          _isLoading = false;
        });

        // 简化处理方式：直接导航返回，不显示SnackBar
        if (result && mounted) {
          // 成功发布，直接返回
          Navigator.of(context).pop();
          // 使用FeedbackService显示成功提示
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              FeedbackService.showSuccessToast(context, '项目需求发布成功！');
            }
          });
        } else if (mounted) {
          // 发布失败，显示提示
          FeedbackService.showErrorToast(context, '项目需求发布失败，请稍后重试');
        }
      } catch (e) {
        // 设置加载状态为false
        setState(() {
          _isLoading = false;
        });
        
        // 显示错误提示
        if (mounted) {
          FeedbackService.showErrorToast(context, '发生错误: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 获取屏幕宽度
    final screenWidth = MediaQuery.of(context).size.width;
    // 计算内边距值
    final paddingValue = screenWidth * horizontalPadding;
    // 计算内容宽度
    final contentWidth = screenWidth - (paddingValue * 2);

    return Hero(
      tag: 'post_card_project',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('发布项目需求'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
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
                              borderRadius: BorderRadius.circular(borderRadius),
                              borderSide: const BorderSide(color: borderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(borderRadius),
                              borderSide: const BorderSide(color: borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(borderRadius),
                              borderSide: BorderSide(color: Colors.blue.shade400),
                            ),
                            contentPadding: contentPadding,
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
                        onItemSelected: _addDomain,
                        onItemRemoved: _removeDomain,
                        labelBuilder: (domain) => domain,
                        isMultiSelect: true,
                        width: contentWidth,
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
                              borderRadius: BorderRadius.circular(borderRadius),
                              borderSide: const BorderSide(color: borderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(borderRadius),
                              borderSide: const BorderSide(color: borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(borderRadius),
                              borderSide: BorderSide(color: Colors.blue.shade400),
                            ),
                            contentPadding: contentPadding,
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
                            backgroundColor: Colors.grey[100],
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
                          iconColor: wechatGreen,
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
                          icon: Icons.phone,
                          iconColor: themeBlue,
                          keyboardType: TextInputType.phone,
                          validator: _validatePhone,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // 发布按钮
                      SizedBox(
                        width: contentWidth,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(borderRadius),
                            ),
                          ),
                          child: const Text('发布', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
      ),
    );
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
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: Colors.blue.shade400),
        ),
        contentPadding: contentPadding,
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
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(borderRadius),
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
                hintText: '请输入职位名称',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(borderRadius),
                  borderSide: const BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(borderRadius),
                  borderSide: const BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(borderRadius),
                  borderSide: BorderSide(color: Colors.blue.shade400),
                ),
                contentPadding: contentPadding,
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
            const SizedBox(height: 12),
            
            // 所需技能
            const Text('所需技能'),
            const SizedBox(height: 4),
            CustomDropdownSelect<String>(
              hint: '请添加技能标签',
              items: predefinedSkills.where((skill) => !requirement.selectedSkills.contains(skill)).toList(),
              selectedItems: requirement.selectedSkills,
              onItemSelected: (skill) {
                setState(() {
                  requirement.selectedSkills.add(skill);
                });
              },
              onItemRemoved: (skill) {
                setState(() {
                  requirement.selectedSkills.remove(skill);
                });
              },
              labelBuilder: (skill) => skill,
              isMultiSelect: true,
              width: contentWidth - 32, // 减去内边距
            ),
            const SizedBox(height: 12),
            
            // 需求数量和合作方式
            Row(
              children: [
                // 需求数量
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('需求数量'),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: requirement.countController,
                        decoration: InputDecoration(
                          hintText: '1',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(borderRadius),
                            borderSide: const BorderSide(color: borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(borderRadius),
                            borderSide: const BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(borderRadius),
                            borderSide: BorderSide(color: Colors.blue.shade400),
                          ),
                          contentPadding: contentPadding,
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '请输入数量';
                          }
                          final number = int.tryParse(value);
                          if (number == null || number <= 0) {
                            return '请输入有效数字';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                
                // 合作方式
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('合作方式*'),
                      const SizedBox(height: 4),
                      CustomDropdownSelect<String>(
                        hint: '请选择',
                        items: cooperationMethods,
                        selectedItems: requirement.selectedCooperationType != null 
                            ? [requirement.selectedCooperationType!] 
                            : [],
                        onItemSelected: (value) {
                          setState(() {
                            requirement.selectedCooperationType = value;
                          });
                        },
                        onItemRemoved: (_) {
                          setState(() {
                            requirement.selectedCooperationType = null;
                          });
                        },
                        labelBuilder: (type) => type,
                        width: double.infinity,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // 工作地点
            const Text('所在城市'),
            const SizedBox(height: 4),
            TextFormField(
              controller: requirement.workLocationController,
              readOnly: true,
              onTap: () => _showCityPicker(requirement),
              decoration: InputDecoration(
                hintText: '点击选择城市',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(borderRadius),
                  borderSide: const BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(borderRadius),
                  borderSide: const BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(borderRadius),
                  borderSide: BorderSide(color: Colors.blue.shade400),
                ),
                contentPadding: contentPadding,
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

// 人才需求数据类
class TalentRequirement {
  final TextEditingController roleController = TextEditingController();
  final TextEditingController countController = TextEditingController();
  final TextEditingController workLocationController = TextEditingController();
  String? selectedCooperationType;
  final List<String> selectedSkills = [];

  // 检查是否有效
  bool isValid() {
    return roleController.text.isNotEmpty &&
        selectedSkills.isNotEmpty &&
        countController.text.isNotEmpty &&
        selectedCooperationType != null;
  }

  // 释放资源
  void dispose() {
    roleController.dispose();
    countController.dispose();
    workLocationController.dispose();
  }
} 