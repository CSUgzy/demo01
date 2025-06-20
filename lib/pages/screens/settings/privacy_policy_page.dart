import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('隐私政策'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 主标题
              const Text(
                '良师益友 App 隐私政策',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // 引言
              Text(
                '欢迎您使用"良师益友"App（以下简称"我们"或"本App"）。我们深知个人信息对您的重要性，并会尽全力保护您的个人信息安全可靠。我们致力于维持您对我们的信任，恪守以下原则，保护您的个人信息：权责一致原则、目的明确原则、选择同意原则、最少够用原则、确保安全原则、主体参与原则、公开透明原则等。',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              
              Text(
                '本《隐私政策》旨在帮助您了解我们会如何收集、使用、存储、共享和保护您的个人信息，以及您如何管理您的个人信息。请在使用我们的产品（或服务）前，仔细阅读并充分理解本政策的全部内容。',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              
              const Text(
                '当您点击同意本政策，即表示您已充分理解并同意我们在本政策中所述的全部内容。',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              
              // 第一部分
              _buildSectionTitle('一、我们如何收集和使用您的个人信息'),
              const SizedBox(height: 12),
              
              Text(
                '在您使用"良师益友"服务的过程中，我们会按照如下方式收集和使用您在创建账户和使用服务时主动提供、以及因您使用服务而产生的信息，用以向您提供、优化我们的服务以及保障您的账户安全：',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              
              _buildSubsection('1. 账号注册与登录'),
              Text(
                '当您注册"良师益友"账号时，您需要向我们提供您的电子邮箱地址并创建密码。我们收集此信息是为了帮助您完成注册，并保障您的账号安全。如果您不提供此类信息，您将无法注册成为我们的用户。',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              
              _buildSubsection('2. 个人资料与身份信息'),
              Text(
                '为了更好地为您提供项目与人才的匹配服务，我们鼓励您完善您的个人资料。您可以选择性地向我们提供以下信息：',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('基本信息：头像、昵称、性别、所在城市、个性签名/简介。'),
              _buildBulletPoint('专业能力信息：我的技能、感兴趣的领域/行业、期望合作方式。'),
              _buildBulletPoint('联系方式（可选）：手机号码、微信号、邮箱。'),
              const SizedBox(height: 12),
              
              _buildSubsection('3. 发布内容信息'),
              _buildBulletPoint('当您作为"项目方"发布项目需求时，我们会收集您填写的项目名称、简介、项目阶段、项目标签/领域、以及具体的人才需求信息。'),
              _buildBulletPoint('当您作为"人才方"发布合作意愿时，我们会收集您填写的个人定位/标题、核心技能、详细经验介绍、期望合作的行业、城市等信息。 我们收集这些信息是为了在平台上公开展示，以实现项目与人才的连接与匹配这一核心功能。'),
              const SizedBox(height: 12),
              
              _buildSubsection('4. 互动与关系信息'),
              Text(
                '当您使用平台上的收藏、感兴趣、评论（如果未来提供）等功能时，我们会收集您的这些操作记录，以便为您建立收藏列表，并向相关方发送互动提醒。',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              
              _buildSubsection('5. 设备信息与日志信息'),
              Text(
                '为保障您正常使用我们的服务，维护我们服务的正常运行，以及优化我们的服务体验，我们可能会收集您的设备信息（如设备型号、操作系统版本、唯一设备标识符）和日志信息（如IP地址、服务访问日期和时间、浏览和搜索记录）。这些信息是为提供服务所收集的基础信息。',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              
              // 第二部分
              _buildSectionTitle('二、我们如何存储和保护您的个人信息'),
              const SizedBox(height: 12),
              
              _buildNumberedPoint(
                '1',
                '信息存储：我们在中华人民共和国境内收集和产生的个人信息，将存储在中华人民共和国境内。我们承诺您的个人信息存储期限将是实现您授权使用的目的所必需的最短时间。'
              ),
              const SizedBox(height: 8),
              _buildNumberedPoint(
                '2',
                '信息保护：我们已使用符合业界标准的安全防护措施保护您提供的个人信息，防止数据遭到未经授权的访问、公开披露、使用、修改、损坏或丢失。我们会采取一切合理可行的措施，保护您的个人信息。'
              ),
              const SizedBox(height: 24),
              
              // 第三部分
              _buildSectionTitle('三、我们如何共享、转让、公开披露您的个人信息'),
              const SizedBox(height: 12),
              
              _buildNumberedPoint(
                '1',
                '共享：我们不会与任何公司、组织和个人共享您的个人信息，但以下情况除外：'
              ),
              Padding(
                padding: const EdgeInsets.only(left: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBulletPoint('在获取您明确同意的情况下共享。'),
                    _buildBulletPoint('在法定情形下的共享：我们可能会根据法律法规规定、诉讼争议解决需要，或按行政、司法机关依法提出的要求，对外共享您的个人信息。'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              
              _buildNumberedPoint(
                '2',
                '转让：我们不会将您的个人信息转让给任何公司、组织和个人，但以下情况除外：'
              ),
              Padding(
                padding: const EdgeInsets.only(left: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBulletPoint('在获取您明确同意的情况下转让。'),
                    _buildBulletPoint('在涉及合并、收购或破产清算情形时，如涉及到个人信息转让，我们会要求新的持有您个人信息的公司、组织继续受本政策的约束，否则我们将要求该公司、组织和个人重新向您征求授权同意。'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              
              _buildNumberedPoint(
                '3',
                '公开披露：我们仅会在以下情况下，公开披露您的个人信息：'
              ),
              Padding(
                padding: const EdgeInsets.only(left: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBulletPoint('获得您明确同意后。'),
                    _buildBulletPoint('您在平台上主动公开发布的信息，例如您的项目需求或合作意愿。'),
                    _buildBulletPoint('基于法律的披露：在法律、法律程序、诉讼或政府主管部门强制性要求的情况下，我们可能会公开披露您的个人信息。'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // 第四部分
              _buildSectionTitle('四、您如何管理您的个人信息'),
              const SizedBox(height: 12),
              
              Text(
                '您对自己的个人信息享有以下权利：',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              
              _buildNumberedPoint(
                '1',
                '访问和更正：您有权访问和更正您的个人资料信息。您可以通过"我的"页面中的"编辑资料"功能随时进行操作。'
              ),
              const SizedBox(height: 8),
              _buildNumberedPoint(
                '2',
                '删除：您可以通过"我的发布"功能删除您发布的项目或合作意愿。在符合相关法律法规规定的情形下，您也可以向我们提出删除您个人信息的请求。'
              ),
              const SizedBox(height: 24),
              
              // 第五部分
              _buildSectionTitle('五、未成年人保护'),
              const SizedBox(height: 12),
              
              Text(
                '我们的产品、网站和服务主要面向成年人。若您是18周岁以下的未成年人，在使用我们的产品（或服务）前，应事先取得您家长或法定监护人的书面同意。',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              
              // 第六部分
              _buildSectionTitle('六、本政策如何更新'),
              const SizedBox(height: 12),
              
              Text(
                '我们的隐私政策可能变更。未经您明确同意，我们不会削减您按照本隐私政策所应享有的权利。我们会在本页面上发布对本政策所做的任何变更。对于重大变更，我们还会提供更为显著的通知。',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              
              // 第七部分
              _buildSectionTitle('七、如何联系我们'),
              const SizedBox(height: 12),
              
              Text(
                '如果您对本隐私政策有任何疑问、意见或建议，可以通过应用内的"帮助与反馈"功能与我们联系，或发送邮件至',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              
              // 可选择的邮箱
              const SelectableText(
                'contact@liangsyiyou.com',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              
              const SizedBox(height: 4),
              Text(
                '我们将尽快审核所涉问题，并在验证您的用户身份后及时回复。',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                  height: 1.5,
                ),
              ),
              
              // 底部留白
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
  
  // 构建章节标题
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }
  
  // 构建小节标题
  Widget _buildSubsection(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  // 构建项目符号点
  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
              height: 1.5,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // 构建编号点
  Widget _buildNumberedPoint(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 20,
          child: Text(
            '$number. ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
              height: 1.5,
            ),
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
} 