import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:leancloud_storage/leancloud.dart';
import '../../../services/user_service.dart';
import '../../../constants/predefined_tags.dart';
import '../../../constants/cooperation_options.dart';
import 'package:city_pickers/city_pickers.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _userService = UserService();
  
  // 用户数据
  LCUser? _currentUser;
  bool _isLoading = true;
  
  // 表单控制器
  final _nicknameController = TextEditingController();
  final _bioController = TextEditingController();
  final _emailController = TextEditingController();
  final _wechatController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  
  // 选中的值
  String _selectedGender = '未知';
  final Set<String> _selectedSkills = {};
  final Set<String> _selectedDomains = {};
  final Set<String> _selectedCooperationMethods = {};
  
  // 头像
  File? _avatarFile;
  String? _avatarUrl;
  
  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }
  
  @override
  void dispose() {
    _nicknameController.dispose();
    _bioController.dispose();
    _emailController.dispose();
    _wechatController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    super.dispose();
  }
  
  // 加载用户资料
  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    
    try {
      final user = await LCUser.getCurrent();
      if (user == null) {
        throw Exception('用户未登录');
      }
      
      await user.fetch(); // 获取最新数据
      
      // 初始化表单数据
      setState(() {
        _currentUser = user;
        
        // 基本信息
        _nicknameController.text = user['nickname'] ?? '';
        _bioController.text = user['bio'] ?? '';
        _emailController.text = user.email ?? '';
        _wechatController.text = user['wechatId'] ?? '';
        _phoneController.text = user['mobilePhoneNumber'] ?? '';
        _cityController.text = user['city'] ?? '';
        _selectedGender = user['gender'] ?? '未知';
        
        // 技能和领域
        final skills = user['skills'] as List<dynamic>?;
        if (skills != null) {
          _selectedSkills.addAll(skills.map((e) => e.toString()));
        }
        
        final domains = user['interestedDomains'] as List<dynamic>?;
        if (domains != null) {
          _selectedDomains.addAll(domains.map((e) => e.toString()));
        }
        
        // 合作方式
        final methods = user['cooperationMethods'] as List<dynamic>?;
        if (methods != null) {
          _selectedCooperationMethods.addAll(methods.map((e) => e.toString()));
        }
        
        // 头像
        final icon = user['icon'] as LCFile?;
        if (icon != null && icon.url != null) {
          _avatarUrl = icon.url;
        }
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载用户资料失败: $e')),
        );
      }
    }
  }
  
  // 选择头像
  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      
      // 显示选择对话框
      final XFile? image = await showDialog<XFile?>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('选择图片来源'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('从相册选择'),
                  onTap: () async {
                    Navigator.pop(context, await picker.pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 800,
                      maxHeight: 800,
                    ));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('拍照'),
                  onTap: () async {
                    Navigator.pop(context, await picker.pickImage(
                      source: ImageSource.camera,
                      maxWidth: 800,
                      maxHeight: 800,
                    ));
                  },
                ),
              ],
            ),
          );
        },
      );

      if (image != null) {
        // 检查文件大小
        final file = File(image.path);
        final fileSize = await file.length();
        if (fileSize > 5 * 1024 * 1024) { // 5MB
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('图片大小不能超过5MB')),
            );
          }
          return;
        }

        // 检查文件类型
        final extension = image.path.split('.').last.toLowerCase();
        if (!['jpg', 'jpeg', 'png'].contains(extension)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('只支持JPG和PNG格式的图片')),
            );
          }
          return;
        }

        setState(() {
          _avatarFile = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择图片失败: $e')),
        );
      }
    }
  }
  
  // 选择城市
  Future<void> _showCityPicker() async {
    try {
      Result? result = await CityPickers.showCityPicker(
        context: context,
        height: 300,
        cancelWidget: Text(
          '取消',
          style: TextStyle(color: Colors.grey[600]),
        ),
        confirmWidget: Text(
          '确定',
          style: TextStyle(color: Theme.of(context).primaryColor),
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
  
  // 保存资料
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      if (_currentUser == null) {
        throw Exception('用户未登录');
      }
      
      // 如果有新头像，先上传
      LCFile? avatarFile;
      if (_avatarFile != null) {
        avatarFile = await _userService.uploadAvatar(
          _avatarFile!.path,
          _currentUser!.objectId!,
        );
        
        if (avatarFile == null) {
          throw Exception('上传头像失败');
        }
      }
      
      // 更新用户资料
      final success = await _userService.updateUserProfile(
        _currentUser!,
        {
          'nickname': _nicknameController.text,
          'bio': _bioController.text,
          'gender': _selectedGender,
          'wechatId': _wechatController.text,
          'mobilePhoneNumber': _phoneController.text,
          'city': _cityController.text,
          'skills': _selectedSkills.toList(),
          'interestedDomains': _selectedDomains.toList(),
          'cooperationMethods': _selectedCooperationMethods.toList(),
        },
        iconFile: avatarFile,
      );
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('资料更新成功')),
        );
        Navigator.of(context).pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存失败，请重试')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('编辑个人资料'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('保存', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: _isLoading && _currentUser == null
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 头像编辑
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _pickImage,
                            child: Stack(
                              children: [
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.grey[200],
                                    image: _avatarFile != null
                                        ? DecorationImage(
                                            image: FileImage(_avatarFile!),
                                            fit: BoxFit.cover,
                                          )
                                        : _avatarUrl != null
                                            ? DecorationImage(
                                                image: NetworkImage(_avatarUrl!),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                  ),
                                  child: _avatarFile == null && _avatarUrl == null
                                      ? const Icon(Icons.person, size: 60, color: Colors.grey)
                                      : null,
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '点击更换头像',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // 基本信息卡片
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '基本信息',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // 昵称
                            const Text('昵称 *'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _nicknameController,
                              decoration: const InputDecoration(
                                hintText: '请输入昵称',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return '请输入昵称';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // 个人简介
                            const Text('个人简介'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _bioController,
                              decoration: const InputDecoration(
                                hintText: '请输入个人简介',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 3,
                            ),
                            const SizedBox(height: 16),
                            
                            // 性别
                            const Text('性别'),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _selectedGender,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(value: '男', child: Text('男')),
                                DropdownMenuItem(value: '女', child: Text('女')),
                                DropdownMenuItem(value: '未知', child: Text('未知')),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _selectedGender = value);
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // 邮箱
                            const Text('邮箱'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                hintText: '邮箱地址',
                                border: OutlineInputBorder(),
                              ),
                              enabled: false, // 不允许修改邮箱
                            ),
                            const SizedBox(height: 16),
                            
                            // 微信号
                            const Text('微信号'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _wechatController,
                              decoration: const InputDecoration(
                                hintText: '请输入微信号',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // 手机号
                            const Text('手机号'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _phoneController,
                              decoration: const InputDecoration(
                                hintText: '请输入手机号',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 16),
                            
                            // 城市
                            const Text('所在城市'),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: _showCityPicker,
                              child: AbsorbPointer(
                                child: TextFormField(
                                  controller: _cityController,
                                  decoration: const InputDecoration(
                                    hintText: '点击选择所在城市',
                                    border: OutlineInputBorder(),
                                    suffixIcon: Icon(Icons.location_city),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // 技能卡片
                    SizedBox(
                      width: double.infinity,
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '我的技能',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: predefinedSkills.map((skill) {
                                  final isSelected = _selectedSkills.contains(skill);
                                  return FilterChip(
                                    label: Text(skill),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      setState(() {
                                        if (selected) {
                                          _selectedSkills.add(skill);
                                        } else {
                                          _selectedSkills.remove(skill);
                                        }
                                      });
                                    },
                                    backgroundColor: Colors.grey[200],
                                    selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                                    checkmarkColor: Theme.of(context).primaryColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: const BorderSide(
                                        color: Colors.transparent,
                                        width: 0,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // 感兴趣的领域卡片
                    SizedBox(
                      width: double.infinity,
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '感兴趣的领域',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: predefinedDomains.map((domain) {
                                  final isSelected = _selectedDomains.contains(domain);
                                  return FilterChip(
                                    label: Text(domain),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      setState(() {
                                        if (selected) {
                                          _selectedDomains.add(domain);
                                        } else {
                                          _selectedDomains.remove(domain);
                                        }
                                      });
                                    },
                                    backgroundColor: Colors.grey[200],
                                    selectedColor: Colors.orange.withOpacity(0.2),
                                    checkmarkColor: Colors.orange,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: const BorderSide(
                                        color: Colors.transparent,
                                        width: 0,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // 期望合作方式卡片
                    SizedBox(
                      width: double.infinity,
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '期望合作方式',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
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
                                    backgroundColor: Colors.grey[200],
                                    selectedColor: Colors.purple.withOpacity(0.2),
                                    checkmarkColor: Colors.purple,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: const BorderSide(
                                        color: Colors.transparent,
                                        width: 0,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // 保存按钮
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                '保存',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
} 