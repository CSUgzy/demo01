import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:city_pickers/city_pickers.dart';
import 'package:leancloud_storage/leancloud.dart';
import '../../../constants/predefined_tags.dart';
import '../../../constants/cooperation_options.dart';
import '../../../services/post_service.dart';
import '../../../widgets/custom_dropdown_select.dart';
import '../../../utils/feedback_service.dart';

// 定义一些全局样式常量，与 CreateProjectPostPage 保持一致
const Color borderColor = Color(0xFFE2E8F0); // 边框颜色 - 浅灰色
const double borderRadius = 16.0; // 边框圆角
const EdgeInsets contentPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 16); // 内边距
const double horizontalPadding = 0.06; // 水平方向的内边距比例
const Color wechatGreen = Color(0xFF07C160); // 微信绿色
const Color themeBlue = Color(0xFF3B82F6); // 主题蓝色

class CreateTalentPostPage extends StatefulWidget {
  const CreateTalentPostPage({super.key});

  @override
  State<CreateTalentPostPage> createState() => _CreateTalentPostPageState();
}

class _CreateTalentPostPageState extends State<CreateTalentPostPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _detailedIntroController = TextEditingController();
  final _wechatController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  
  final List<String> _selectedSkills = [];
  final List<String> _selectedCooperationMethods = [];
  final List<String> _selectedDomains = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
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

  // 添加城市选择方法
  Future<void> _showCityPicker() async {
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
          _cityController.text = '${result.provinceName} ${result.cityName}';
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

  // 显示合作方式选择
  Widget _buildCooperationMethodsSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('期望合作方式', true),
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
              selectedColor: themeBlue.withOpacity(0.2),
              backgroundColor: borderColor,
              side: const BorderSide(color: Colors.white),
              checkmarkColor: themeBlue,
              labelStyle: TextStyle(
                color: isSelected ? themeBlue : Colors.black87,
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

  // 提交表单
  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      // 验证必选项
      if (_selectedSkills.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请选择至少一项核心技能')),
        );
        return;
      }

      if (_selectedCooperationMethods.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请选择至少一种期望合作方式')),
        );
        return;
      }

      if (_selectedDomains.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请选择至少一个期望行业/领域')),
        );
        return;
      }

      if (_cityController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请选择期望城市')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        print('准备提交表单数据...');
        
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
        
        print('标题: $title');
        print('技能: $coreSkillsText');
        print('技能标签: $coreSkillsTags');
        print('合作方式: ${cooperationMethods.join(', ')}');
        print('领域: ${domains.join(', ')}');
        print('城市: $city');
        
        // 使用PostService发布合作意愿
        final postService = PostService();
        final result = await postService.createTalentPost(
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

        // 设置加载状态为false
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }

        if (result && mounted) {
          print('发布成功，准备返回');
          
          // 先导航返回，避免Hero动画冲突
          Navigator.of(context).pop();
          
          // 使用FeedbackService显示成功提示
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              FeedbackService.showSuccessToast(context, '合作意愿发布成功！');
            }
          });
        } else if (mounted) {
          print('发布失败，显示错误提示');
          // 发布失败，显示提示
          FeedbackService.showErrorToast(context, '发布合作意愿失败，请稍后重试');
        }
      } catch (e) {
        print('表单提交过程中出现异常: $e');
        // 设置加载状态为false
        if (mounted) {
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

  @override
  Widget build(BuildContext context) {
    // 获取屏幕宽度
    final screenWidth = MediaQuery.of(context).size.width;
    // 计算内边距值
    final paddingValue = screenWidth * horizontalPadding;
    // 计算内容宽度
    final contentWidth = screenWidth - (paddingValue * 2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('发布合作意愿'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('正在提交，请稍候...'),
                ],
              ),
            )
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
                    // 个人定位/标题
                    _buildSectionTitle('一句话介绍自己', true),
                    SizedBox(
                      width: contentWidth,
                      child: TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          hintText: '例如：资深后端工程师寻求AI创业项目',
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
                          counterText: '${_titleController.text.length}/50',
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        maxLength: 50,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '请输入个人定位/标题';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          setState(() {}); // 更新计数器
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 个人简介/经验
                    _buildSectionTitle('个人简介/经验', true),
                    SizedBox(
                      width: contentWidth,
                      child: TextFormField(
                        controller: _detailedIntroController,
                        decoration: InputDecoration(
                          hintText: '详细介绍您的专业背景、项目经验、成果案例等',
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
                          counterText: '${_detailedIntroController.text.length}/1000',
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        maxLength: 1000,
                        maxLines: 8,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '请输入个人简介/经验';
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
                    _buildSectionTitle('核心技能概述', true),
                    CustomDropdownSelect<String>(
                      hint: '请选择您的核心技能，至少1个',
                      items: predefinedSkills.where((skill) => !_selectedSkills.contains(skill)).toList(),
                      selectedItems: _selectedSkills,
                      onItemSelected: (skill) {
                        setState(() {
                          _selectedSkills.add(skill);
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
                          '请选择至少一项核心技能',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),

                    // 期望合作方式
                    _buildCooperationMethodsSelector(),
                    const SizedBox(height: 20),

                    // 期望行业/领域
                    _buildSectionTitle('期望行业/领域 (最多3个)', true),
                    CustomDropdownSelect<String>(
                      hint: '请选择期望的行业/领域，最多3个',
                      items: predefinedDomains.where((domain) => !_selectedDomains.contains(domain)).toList(),
                      selectedItems: _selectedDomains,
                      onItemSelected: (domain) {
                        if (_selectedDomains.length < 3) {
                          setState(() {
                            _selectedDomains.add(domain);
                          });
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('最多只能选择3个行业/领域')),
                          );
                        }
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
                          '请选择至少一个行业/领域',
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
                        onTap: _showCityPicker,
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
    );
  }
} 