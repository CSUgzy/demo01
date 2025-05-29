import 'package:flutter/material.dart';

class SelectPostTypePage extends StatelessWidget {
  const SelectPostTypePage({super.key});

  // 构建标签组件
  Widget _buildChip(String label, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
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
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(icon, color: Colors.white, size: 28),
                ],
              ),
              const SizedBox(height: 16),
              // 描述文本
              Text(
                description,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              // 底部标签和箭头
              Row(
                children: [
                  ...tags.map((tag) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildChip(tag, Colors.white.withOpacity(0.2)),
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
    // 定义卡片渐变色
    final List<Color> projectCardGradient = const [
      Color(0xFF4A80FF),
      Color(0xFF6A95FF),
    ];

    final List<Color> talentCardGradient = const [
      Color(0xFF8B5CF6),
      Color(0xFFA78BFA),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('发布'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // 主标题
              const Text(
                '您想要发布什么？',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              // 项目发布卡片
              _buildOptionCard(
                title: '发布项目，寻找伙伴',
                description: '发布您的创业项目或创意，寻找合适的技术、产品或运营合作伙伴',
                icon: Icons.group,
                tags: ['找人才', '项目合作'],
                gradientColors: projectCardGradient,
                onTap: () {
                  // TODO: 导航到项目发布页面
                  // Navigator.push(context, MaterialPageRoute(
                  //   builder: (context) => const CreateProjectPostPage(),
                  // ));
                },
              ),
              const SizedBox(height: 20),
              // 人才发布卡片
              _buildOptionCard(
                title: '展示自己，寻找机会',
                description: '展示您的专业技能和经验，寻找合适的创业项目或合作机会',
                icon: Icons.person,
                tags: ['找项目', '求合作'],
                gradientColors: talentCardGradient,
                onTap: () {
                  // TODO: 导航到人才发布页面
                  // Navigator.push(context, MaterialPageRoute(
                  //   builder: (context) => const CreateTalentPostPage(),
                  // ));
                },
              ),
              const SizedBox(height: 40),
              // 底部提示文本
              Text(
                '我们鼓励发布真实、详细的信息，这将大大提高匹配成功率。所有发布内容将经过审核，请遵守社区规范。',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
} 