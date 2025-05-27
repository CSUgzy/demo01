import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:leancloud_storage/leancloud.dart';
import '../../../services/user_service.dart';
import '../../../constants/predefined_tags.dart';

class ProfileSetupStep2Page extends StatefulWidget {
  const ProfileSetupStep2Page({super.key});

  @override
  State<ProfileSetupStep2Page> createState() => _ProfileSetupStep2PageState();
}

class _ProfileSetupStep2PageState extends State<ProfileSetupStep2Page> {
  final _userService = UserService();
  bool _isLoading = false;
  
  // 选中的技能和领域
  final Set<String> _selectedSkills = {};
  final Set<String> _selectedDomains = {};

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final currentUser = await LCUser.getCurrent();
      if (currentUser != null) {
        setState(() {
          final skills = currentUser['skills'] as List<dynamic>?;
          final domains = currentUser['interestedDomains'] as List<dynamic>?;
          
          if (skills != null) {
            _selectedSkills.addAll(skills.map((e) => e.toString()));
          }
          if (domains != null) {
            _selectedDomains.addAll(domains.map((e) => e.toString()));
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载用户信息失败: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (_selectedSkills.isEmpty || _selectedDomains.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请至少选择一个技能和一个感兴趣的领域'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final currentUser = await LCUser.getCurrent();
      if (currentUser == null) {
        throw Exception('用户未登录');
      }

      final success = await _userService.updateUserProfile(
        currentUser,
        {
          'skills': _selectedSkills.toList(),
          'interestedDomains': _selectedDomains.toList(),
          'profileCompletionStage': 2,
        },
      );

      if (success && mounted) {
        Navigator.pushReplacementNamed(context, '/profile-setup-step3');
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

  Widget _buildTagsSection(String title, List<String> tags, Set<String> selectedTags) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: tags.map((tag) {
            final isSelected = selectedTags.contains(tag);
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      selectedTags.remove(tag);
                    } else {
                      selectedTags.add(tag);
                    }
                  });
                },
                hoverColor: const Color(0xFFB3E0FF),
                splashColor: const Color(0xFFB3E0FF).withOpacity(0.3),
                highlightColor: const Color(0xFFB3E0FF).withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFB3E0FF) : Colors.transparent,
                    border: Border.all(
                      color: const Color(0xFFE4E4E7),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('完善您的资料 (2/3) - 核心能力'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ShadCard(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTagsSection('我的技能', predefinedSkills, _selectedSkills),
                      const SizedBox(height: 32),
                      _buildTagsSection('感兴趣的领域/行业', predefinedDomains, _selectedDomains),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // 下一步按钮
              Center(
                child: Container(
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
              ),
            ],
          ),
        ),
      ),
    );
  }
} 