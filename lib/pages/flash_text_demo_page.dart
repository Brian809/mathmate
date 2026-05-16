import 'package:flutter/material.dart';
import 'package:mathmate/widgets/flash_text.dart';

class FlashTextDemoPage extends StatefulWidget {
  const FlashTextDemoPage({super.key});

  @override
  State<FlashTextDemoPage> createState() => _FlashTextDemoPageState();
}

class _FlashTextDemoPageState extends State<FlashTextDemoPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('快闪文字效果演示'),
        backgroundColor: const Color(0xFF4C6FFF),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('1. 打字机效果', FlashText(
              text: '拍一下，难题秒解决',
              flashStyle: FlashTextStyle.typewriter,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            )),
            const SizedBox(height: 24),
            _buildSection('2. 淡入效果', FlashText(
              text: '欢迎使用MathMate',
              flashStyle: FlashTextStyle.fadeIn,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            )),
            const SizedBox(height: 24),
            _buildSection('3. 上滑效果', FlashText(
              text: '智能数学助手',
              flashStyle: FlashTextStyle.slideUp,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            )),
            const SizedBox(height: 24),
            _buildSection('4. 左滑效果', FlashText(
              text: '拍照识别题目',
              flashStyle: FlashTextStyle.slideLeft,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            )),
            const SizedBox(height: 24),
            _buildSection('5. 弹跳效果', FlashText(
              text: '秒出答案',
              flashStyle: FlashTextStyle.bounce,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            )),
            const SizedBox(height: 24),
            _buildSection('6. 缩放效果', FlashText(
              text: '详细解题步骤',
              flashStyle: FlashTextStyle.scale,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            )),
            const SizedBox(height: 24),
            _buildSection('7. 故障效果', FlashText(
              text: 'AI智能分析',
              flashStyle: FlashTextStyle.glitch,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            )),
            const SizedBox(height: 24),
            _buildSection('8. 波浪效果', FlashText(
              text: '学习更高效',
              flashStyle: FlashTextStyle.wave,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            )),
            const SizedBox(height: 24),
            _buildSection('9. 脉冲闪烁', PulseText(
              text: 'NEW',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            )),
            const SizedBox(height: 24),
            _buildSection('10. 旋转文字', RotatingText(
              texts: const ['拍照', '识别', '解答', '学习'],
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            )),
            const SizedBox(height: 24),
            _buildSection('11. Logo动画', AnimatedLogoText(
              text: 'MathMate',
              baseStyle: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            )),
            const SizedBox(height: 24),
            _buildSection('12. 文字序列', FlashTextSequence(
              texts: const ['开始', '识别', '分析', '解答'],
              animations: const [
                FlashTextStyle.scale,
                FlashTextStyle.fadeIn,
                FlashTextStyle.bounce,
                FlashTextStyle.wave,
              ],
              styles: const [
                TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.blue),
                TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.green),
                TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.orange),
                TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.purple),
              ],
            )),
            const SizedBox(height: 32),
            _buildUsageExamples(),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Center(child: child),
        ],
      ),
    );
  }

  Widget _buildUsageExamples() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4C6FFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb, color: Color(0xFF4C6FFF)),
              SizedBox(width: 8),
              Text(
                '使用示例',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4C6FFF)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '在MathMate应用中的典型使用场景：',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _buildExample('欢迎页标题', 'AnimatedLogoText - 品牌Logo动画'),
          _buildExample('功能提示', 'FlashText - 配合不同动画效果'),
          _buildExample('新功能标签', 'PulseText - 脉冲闪烁吸引注意'),
          _buildExample('滚动标语', 'RotatingText - 自动轮换显示'),
          _buildExample('教程引导', 'FlashTextSequence - 序列动画展示'),
          _buildExample('打字效果', 'FlashText.typewriter - 打字机效果'),
        ],
      ),
    );
  }

  Widget _buildExample(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13, color: Colors.black87),
                children: [
                  TextSpan(text: '$title: ', style: const TextStyle(fontWeight: FontWeight.w600)),
                  TextSpan(text: desc),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
