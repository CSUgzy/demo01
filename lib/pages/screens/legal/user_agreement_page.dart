import 'package:flutter/material.dart';

class UserAgreementPage extends StatelessWidget {
  const UserAgreementPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('用户协议'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '良师益友 App 用户协议',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '发布日期：2025年6月20日\n生效日期：2025年6月20日',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '欢迎您使用"良师益友"App（以下简称"本平台"或"我们"）。为使用本平台的服务，您应当阅读并遵守本《用户协议》。请您务必审慎阅读、充分理解各条款内容，特别是免除或者限制责任的条款。',
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '当您完成注册程序或以任何方式使用本平台服务，即表示您已充分阅读、理解并接受本协议的全部内容，本协议即在您与本平台之间产生法律效力。',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              '一、服务内容',
              '本平台是一个旨在连接项目需求方与专业技能供给方的信息发布与交流平台。我们为用户提供信息发布、浏览、搜索、初步沟通等服务，以促进双方的合作机会。我们本身不参与用户之间的任何实际合作项目，也不对其合作内容、过程及结果承担任何责任。',
            ),
            _buildSection(
              '二、用户行为规范',
              '您在使用本平台服务时，必须遵守中华人民共和国相关法律法规，并同意将不会利用本服务进行任何违法或不正当的活动，包括但不限于：\n\n'
              '发布任何虚假、骚扰性、侮辱性、恐吓性、淫秽色情或任何其他非法信息。\n\n'
              '侵害他人名誉权、肖像权、知识产权、商业秘密等合法权利。\n\n'
              '发布不真实的创业项目或个人履历信息，进行欺诈行为。\n\n'
              '未经允许，收集、存储其他用户的个人信息。\n\n'
              '任何危害计算机网络安全的行为。\n\n'
              '若您的行为不符合本协议，我们有权在不通知您的情况下，删除您发布的内容，并视情节严重程度对您的账号进行警告、限制功能、直至永久封禁。',
            ),
            _buildSection(
              '三、内容所有权',
              '用户在本平台发布的原创内容（包括但不限于项目介绍、个人简介、评论等）的知识产权归用户本人所有。\n\n'
              '用户授权本平台在全球范围内拥有免费的、永久的、不可撤销的、非独家的许可以及再许可的权利，以使用、复制、修改、出版、翻译、据以创作衍生作品、传播、表演和展示此等内容。',
            ),
            _buildSection(
              '四、免责声明',
              '本平台作为信息中介平台，我们不对任何用户发布信息的真实性、准确性、完整性、合法性或时效性做出任何明示或默示的保证。您应自行判断信息的真伪，并对自己的判断和行为负责。\n\n'
              '用户之间因使用本平台而产生的任何合作、纠纷、争议或损害，均由用户双方自行解决，本平台不承担任何法律责任。\n\n'
              '因不可抗力、网络故障、系统维护等非我们可控原因导致的服务中断或其它缺陷，我们不承担任何责任，但将尽力减少因此而给您造成的损失和影响。',
            ),
            _buildSection(
              '五、协议的变更与终止',
              '我们有权根据业务发展的需要在不事先通知的情况下，随时对本协议内容进行修改。修改后的协议一旦在本平台公布，即有效代替原来的协议。您应随时关注本平台公告、提示信息及协议、规则等内容。如您不同意更新后的协议，应立即停止使用本平台的服务。如您继续使用，即视为您已接受经修订的协议。',
            ),
            _buildSection(
              '六、联系我们',
              '如果您对本协议有任何疑问，请通过应用内的"帮助与反馈"功能与我们联系。',
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
} 