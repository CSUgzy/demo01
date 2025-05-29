import 'package:flutter/material.dart';

class SelectPostTypePage extends StatefulWidget {
  const SelectPostTypePage({super.key});

  @override
  State<SelectPostTypePage> createState() => _SelectPostTypePageState();
}

class _SelectPostTypePageState extends State<SelectPostTypePage> {
  // 卡片渐变色
  final List<Color> _projectCardGradient = const [
    Color(0xFF4A80FF),
    Color(0xFF6A95FF),
  ];

  final List<Color> _talentCardGradient = const [
    Color(0xFF8B5CF6),
    Color(0xFFA78BFA),
  ];

  // 构建标签组件
  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // 构建选项卡片
  Widget _buildOptionCard({
    required String title,
    required String description,
    required IconData icon,
    required List<String> tags,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题行
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(icon, color: Colors.white, size: 24),
                ],
              ),
              const SizedBox(height: 12),
              // 描述文本
              Text(
                description,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              // 底部标签和箭头
              Row(
                children: [
                  ...tags.map((tag) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildChip(tag),
                  )),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('发布'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              // 主标题
              const Text(
                '您想要发布什么？',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              // 项目发布卡片
              _buildOptionCard(
                title: '发布项目，寻找伙伴',
                description: '发布您的创业项目或创意，寻找合适的技术、产品或运营合作伙伴',
                icon: Icons.group_outlined,
                tags: ['找人才', '项目合作'],
                gradientColors: _projectCardGradient,
                onTap: () {
                  // TODO: 导航到项目发布页面
                  // Navigator.push(context, MaterialPageRoute(
                  //   builder: (context) => const CreateProjectPostPage(),
                  // ));
                },
              ),
              const SizedBox(height: 16),
              // 人才发布卡片
              _buildOptionCard(
                title: '展示自己，寻找机会',
                description: '展示您的专业技能和经验，寻找合适的创业项目或合作机会',
                icon: Icons.person_outline,
                tags: ['找项目', '求合作'],
                gradientColors: _talentCardGradient,
                onTap: () {
                  // TODO: 导航到人才发布页面
                  // Navigator.push(context, MaterialPageRoute(
                  //   builder: (context) => const CreateTalentPostPage(),
                  // ));
                },
              ),
              const SizedBox(height: 32),
              // 底部提示文本
              Text(
                '我们鼓励发布真实、详细的信息，这将大大提高匹配成功率。所有发布内容将经过审核，请遵守社区规范。',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 