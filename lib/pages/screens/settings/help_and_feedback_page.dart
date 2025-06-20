import 'package:flutter/material.dart';
import '../../../services/help_and_feedback_service.dart';
import '../../../utils/feedback_service.dart';
import '../../../utils/toast_util.dart';

class HelpAndFeedbackPage extends StatefulWidget {
  const HelpAndFeedbackPage({super.key});

  @override
  State<HelpAndFeedbackPage> createState() => _HelpAndFeedbackPageState();
}

class _HelpAndFeedbackPageState extends State<HelpAndFeedbackPage> {
  final _formKey = GlobalKey<FormState>();
  final _feedbackController = TextEditingController();
  final _contactController = TextEditingController();

  @override
  void dispose() {
    _feedbackController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  // 提交反馈
  Future<void> _submitFeedback() async {
    if (_formKey.currentState!.validate()) {
      // 显示加载指示器
      FeedbackService.showLoadingDialog(context, message: "提交中...");
      
      try {
        // 调用服务提交反馈
        await HelpAndFeedbackService().submitFeedback(
          content: _feedbackController.text,
          contactInfo: _contactController.text,
        );
        
        // 隐藏加载对话框
        if (mounted) Navigator.pop(context);
        
        // 显示成功提示
        if (mounted) {
          ToastUtil.showSuccess(context, "感谢您的反馈，我们已收到！");
          // 清空输入框
          _feedbackController.clear();
          _contactController.clear();
        }
      } catch (e) {
        // 隐藏加载对话框
        if (mounted) Navigator.pop(context);
        
        // 显示错误提示
        if (mounted) {
          FeedbackService.showErrorSnackBar(context, e.toString());
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("帮助与反馈"),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 常见问题区块
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "常见问题",
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            
            // FAQ列表
            ExpansionTile(
              title: const Text("Q1: 如何发布我的项目或合作意愿？"),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(
                    "A: 您可以点击底部导航栏中间的'+'按钮，然后选择'发布项目'或'展示自己'来创建您的帖子。",
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
            ExpansionTile(
              title: const Text("Q2: 我发布的帖子会立刻被所有人看到吗？"),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(
                    "A: 为了维护社区质量，所有发布的内容都会经过我们的审核，审核通过后即可在首页展示。",
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
            ExpansionTile(
              title: const Text("Q3: 如何修改我的个人资料？"),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(
                    "A: 在'我的'页面点击头像或'编辑资料'按钮，即可进入个人资料编辑页面。",
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
            ExpansionTile(
              title: const Text("Q4: 如何收藏感兴趣的项目？"),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(
                    "A: 在项目详情页面点击右上角的收藏图标即可将项目加入收藏，您可以在'我的-我收藏的'中查看所有收藏项目。",
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
            ExpansionTile(
              title: const Text("Q5: 如何联系项目发布者？"),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(
                    "A: 在项目详情页面底部有'联系发布者'按钮，点击后可以查看对方提供的联系方式。",
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
            
            // 提交反馈区块
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "提交您的反馈",
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            
            // 反馈表单
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 反馈内容输入框
                    TextFormField(
                      controller: _feedbackController,
                      maxLines: 8,
                      decoration: const InputDecoration(
                        hintText: "请在此处详细描述您遇到的问题或建议...",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "请输入反馈内容";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // 联系方式输入框
                    TextFormField(
                      controller: _contactController,
                      decoration: const InputDecoration(
                        hintText: "您的联系方式 (选填，方便我们与您沟通)",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // 提交按钮
                    ElevatedButton(
                      onPressed: _submitFeedback,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("提交", style: TextStyle(fontSize: 16)),
                    ),
                    
                    // 添加版本和设备信息提示
                    const SizedBox(height: 16),
                    Text(
                      "注意：系统会自动收集应用版本号和设备型号以便更好地解决问题。",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 