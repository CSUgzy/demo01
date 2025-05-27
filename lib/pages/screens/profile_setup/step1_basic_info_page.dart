import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../services/user_service.dart';
import 'package:leancloud_storage/leancloud.dart';
import 'package:city_pickers/city_pickers.dart';

class ProfileSetupStep1Page extends StatefulWidget {
  const ProfileSetupStep1Page({super.key});

  @override
  State<ProfileSetupStep1Page> createState() => _ProfileSetupStep1PageState();
}

class _ProfileSetupStep1PageState extends State<ProfileSetupStep1Page> {
  final _formKey = GlobalKey<ShadFormState>();
  final _userService = UserService();
  
  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _wechatController = TextEditingController();
  final _cityController = TextEditingController();
  
  String _selectedGender = '未知';
  File? _avatarFile;
  String? _avatarUrl;
  bool _isLoading = false;

  // 添加表单数据
  final Map<String, dynamic> _formData = {
    'nickname': '',
    'wechatId': '',
    'city': '',
  };

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _wechatController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    final currentUser = await LCUser.getCurrent();
    if (currentUser != null) {
      setState(() {
        _emailController.text = currentUser.email ?? '';
        _nicknameController.text = currentUser['nickname'] ?? '';
        _wechatController.text = currentUser['wechatId'] ?? '';
        _cityController.text = currentUser['city'] ?? '';
        _selectedGender = currentUser['gender'] ?? '未知';
        
        // 如果用户已有头像，获取URL并显示
        final icon = currentUser['icon'] as LCFile?;
        if (icon != null && icon.url != null) {
          _avatarUrl = icon.url;
          print('加载用户头像: $_avatarUrl');
        }
      });
    }
  }

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
          SnackBar(
            content: Text('选择图片失败: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  // 添加城市选择方法
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
          _formData['city'] = _cityController.text;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('选择城市失败: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final currentUser = await LCUser.getCurrent();
      if (currentUser == null) {
        throw Exception('用户未登录');
      }

      // 如果有新头像，先上传
      LCFile? avatarFile;
      if (_avatarFile != null) {
        avatarFile = await _userService.uploadAvatar(
          _avatarFile!.path,
          currentUser.objectId!,
        );
      }

      // 更新用户信息
      final success = await _userService.updateUserProfile(
        currentUser,
        {
          'nickname': _nicknameController.text,
          'gender': _selectedGender,
          'wechatId': _wechatController.text,
          'city': _cityController.text,
          'profileCompletionStage': 1,
        },
        iconFile: avatarFile,
      );

      if (success && mounted) {
        Navigator.pushReplacementNamed(context, '/profile-setup-step2');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('保存失败，请重试'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
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
    final theme = ShadTheme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('完善您的资料 (1/3) - 基本信息'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ShadForm(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // 头像选择
                  Center(
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey[50],
                                  border: Border.all(
                                    color: Colors.grey[200]!,
                                    width: 1,
                                  ),
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
                                    ? const Icon(Icons.add_a_photo, size: 40, color: Colors.grey)
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '点击选择头像',
                          style: theme.textTheme.small.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 基本信息卡片
                  ShadCard(
                    width: 400,
                    title: Text('基本信息', style: theme.textTheme.h4),
                    description: const Text('请完善你的基本个人信息，让其他用户更好地了解你。'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 昵称
                          const Text('昵称'),
                          ShadInputFormField(
                            controller: _nicknameController,
                            placeholder: const Text('请输入你的昵称'),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return '昵称不能为空';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              _formData['nickname'] = value;
                            },
                          ),
                          const SizedBox(height: 16),

                          // 性别
                          const Text('性别'),
                          ShadSelect<String>(
                            placeholder: const Text('请选择性别'),
                            options: [
                              ShadOption(value: '男', child: const Text('男')),
                              ShadOption(value: '女', child: const Text('女')),
                              ShadOption(value: '未知', child: const Text('未知')),
                            ],
                            selectedOptionBuilder: (context, value) {
                              return Text(value);
                            },
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedGender = value);
                              }
                            },
                          ),
                          const SizedBox(height: 16),

                          // 邮箱
                          const Text('邮箱'),
                          ShadInputFormField(
                            controller: _emailController,
                            placeholder: const Text('您的注册邮箱'),
                            enabled: false,
                          ),
                          const SizedBox(height: 16),

                          // 微信号
                          const Text('微信号'),
                          ShadInputFormField(
                            controller: _wechatController,
                            placeholder: const Text('请输入你的微信号'),
                            onChanged: (value) {
                              _formData['wechatId'] = value;
                            },
                          ),
                          const SizedBox(height: 16),

                          // 城市
                          const Text('所在城市'),
                          GestureDetector(
                            onTap: _showCityPicker,
                            child: AbsorbPointer(
                              child: ShadInputFormField(
                                controller: _cityController,
                                placeholder: const Text('点击选择所在城市'),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return '请选择所在城市';
                                  }
                                  return null;
                                },
                                trailing: Icon(
                                  Icons.location_city,
                                  color: Colors.grey[600],
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 下一步按钮
                  Container(
                    width: 400,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1677FF),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('下一步'),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.arrow_forward,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 