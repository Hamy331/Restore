import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/ui/responsive/responsive_content.dart';

enum AiAssistantState { welcome, results, filtered, comparison, empty, error }

class AiAssistantView extends StatefulWidget {
  const AiAssistantView({super.key});

  @override
  State<AiAssistantView> createState() => _AiAssistantViewState();
}

class _AiAssistantViewState extends State<AiAssistantView> {
  final _input = TextEditingController();
  AiAssistantState _state = AiAssistantState.welcome;
  String _query = '';

  static const _quickPrompts = [
    'Tìm máy ảnh film dưới 4 triệu',
    'Tìm laptop gaming dưới 15 triệu',
    'Tìm iPhone cũ dưới 10 triệu',
    'Tìm laptop cho sinh viên',
  ];

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _submit([String? prompt]) {
    final value = (prompt ?? _input.text).trim();
    if (value.isEmpty) return;
    _input.clear();
    setState(() {
      _query = value;
      if (value.toLowerCase().contains('so sánh')) {
        _state = AiAssistantState.comparison;
      } else if (value.toLowerCase().contains('không có')) {
        _state = AiAssistantState.empty;
      } else {
        _state = _state == AiAssistantState.results
            ? AiAssistantState.filtered
            : AiAssistantState.results;
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.surface,
    appBar: AppBar(
      title: const Text('ReStore AI'),
      actions: [
        PopupMenuButton<AiAssistantState>(
          tooltip: 'Trạng thái mẫu',
          onSelected: (value) => setState(() => _state = value),
          itemBuilder: (_) => const [
            PopupMenuItem(value: AiAssistantState.welcome, child: Text('Bắt đầu lại')),
            PopupMenuItem(value: AiAssistantState.empty, child: Text('Xem empty state')),
            PopupMenuItem(value: AiAssistantState.error, child: Text('Xem error state')),
          ],
        ),
      ],
    ),
    body: SafeArea(
      top: false,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: ResponsiveContent(
                maxWidth: 720,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: _buildState(context),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Align(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 688),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _submit(),
                        decoration: const InputDecoration(
                          hintText: 'Hỏi về sản phẩm, giá, khu vực...',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 42,
                      height: 42,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(padding: EdgeInsets.zero),
                        child: const Icon(Icons.arrow_upward, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildState(BuildContext context) => switch (_state) {
    AiAssistantState.welcome => _WelcomeState(
      key: const ValueKey('welcome'),
      prompts: _quickPrompts,
      onPrompt: _submit,
    ),
    AiAssistantState.results || AiAssistantState.filtered => _ResultsState(
      key: const ValueKey('results'),
      query: _query,
      filtered: _state == AiAssistantState.filtered,
      onPrompt: _submit,
    ),
    AiAssistantState.comparison => const _ComparisonState(
      key: ValueKey('comparison'),
    ),
    AiAssistantState.empty => _MessageState(
      key: const ValueKey('empty'),
      icon: Icons.search_off,
      title: 'Không tìm thấy tin phù hợp',
      message: 'Thử mở rộng khu vực, tăng khoảng giá hoặc mô tả sản phẩm ngắn gọn hơn.',
      actionLabel: 'Điều chỉnh yêu cầu',
      onAction: () => setState(() => _state = AiAssistantState.welcome),
    ),
    AiAssistantState.error => _MessageState(
      key: const ValueKey('error'),
      icon: Icons.refresh,
      title: 'Chưa thể trả lời lúc này',
      message: 'Nội dung cuộc trò chuyện vẫn được giữ. Bạn có thể thử lại mà không cần nhập lại từ đầu.',
      actionLabel: 'Thử lại',
      onAction: () => setState(() => _state = AiAssistantState.results),
    ),
  };
}

class _WelcomeState extends StatelessWidget {
  const _WelcomeState({required this.prompts, required this.onPrompt, super.key});
  final List<String> prompts;
  final ValueChanged<String> onPrompt;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _AiCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: AppColors.primaryDark, size: 20),
                SizedBox(width: 8),
                Text('Hỏi ReStore AI', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Mô tả món đồ bạn cần. AI sẽ tìm và so sánh các tin đăng phù hợp trên ReStore.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      const Text('Thử hỏi nhanh', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      ...prompts.map(
        (prompt) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: OutlinedButton.icon(
            onPressed: () => onPrompt(prompt),
            icon: const Icon(Icons.search, size: 18),
            label: Align(alignment: Alignment.centerLeft, child: Text(prompt)),
            style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
          ),
        ),
      ),
      const _AiCard(
        color: AppColors.background,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tin đăng là của người bán', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            SizedBox(height: 5),
            Text('Xem chi tiết tin và trao đổi trực tiếp với người bán khi bạn quan tâm.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
      const SizedBox(height: 10),
      const _AiCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bạn có thể hỏi tiếp trong cùng hội thoại', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            SizedBox(height: 6),
            Text('• Giới hạn giá và khu vực\n• Chọn thương hiệu hoặc tình trạng\n• So sánh thông tin giữa các tin đăng', style: TextStyle(fontSize: 11, height: 1.55, color: AppColors.textSecondary)),
          ],
        ),
      ),
    ],
  );
}

class _ResultsState extends StatelessWidget {
  const _ResultsState({required this.query, required this.filtered, required this.onPrompt, super.key});
  final String query;
  final bool filtered;
  final ValueChanged<String> onPrompt;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 300),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
          child: Text(query.isEmpty ? 'Tìm máy ảnh film dưới 4 triệu ở TP.HCM' : query, style: const TextStyle(fontSize: 12)),
        ),
      ),
      const SizedBox(height: 12),
      _AiCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.auto_awesome, color: AppColors.primaryDark, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(filtered ? 'Mình đã cập nhật kết quả theo yêu cầu mới của bạn.' : 'Mình tìm thấy 2 tin máy ảnh film phù hợp. Bạn có thể mở từng tin để xem thêm.', style: const TextStyle(fontSize: 12))),
          ],
        ),
      ),
      const SizedBox(height: 10),
      const Text('TIN ĐĂNG PHÙ HỢP · DỮ LIỆU MINH HỌA', style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
      const Divider(height: 22),
      const _AiListing(title: 'Canon AE-1 + lens 50mm', price: '2.450.000 đ', location: 'Quận 1 · 2 giờ trước'),
      const Divider(height: 12),
      const _AiListing(title: 'Máy ảnh Nikon FM2', price: '3.800.000 đ', location: 'Quận 10 · Hôm qua'),
      const SizedBox(height: 12),
      const _AiCard(
        color: AppColors.background,
        child: Text('Giá và tình trạng theo nội dung người bán cung cấp.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ),
      const SizedBox(height: 12),
      const Text('Bạn có thể hỏi tiếp:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      const SizedBox(height: 8),
      OutlinedButton.icon(onPressed: () => onPrompt('Chỉ Canon thôi'), icon: const Icon(Icons.search, size: 18), label: const Text('Chỉ Canon thôi')),
      const SizedBox(height: 8),
      OutlinedButton.icon(onPressed: () => onPrompt('So sánh 2 máy này'), icon: const Icon(Icons.search, size: 18), label: const Text('So sánh 2 máy này')),
    ],
  );
}

class _ComparisonState extends StatelessWidget {
  const _ComparisonState({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Align(
        alignment: Alignment.centerRight,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
          child: const Text('So sánh 2 máy này', style: TextStyle(fontSize: 12)),
        ),
      ),
      const SizedBox(height: 12),
      const _AiCard(child: Row(children: [Icon(Icons.auto_awesome, color: AppColors.primaryDark, size: 18), SizedBox(width: 8), Expanded(child: Text('Mình so sánh theo thông tin có trong hai tin đăng ReStore.', style: TextStyle(fontSize: 12)))])),
      const SizedBox(height: 12),
      const Text('Canon AE-1 và Nikon FM2', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      Container(
        decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(9)),
        clipBehavior: Clip.antiAlias,
        child: const Column(
          children: [
            _CompareRow('Tin đăng', 'Canon AE-1', 'Nikon FM2', heading: true),
            _CompareRow('Giá', '2.450.000 đ', '3.800.000 đ'),
            _CompareRow('Tình trạng', 'Còn tốt', 'Chưa nêu'),
            _CompareRow('Khu vực', 'Quận 1', 'Quận 10'),
            _CompareRow('Đăng tin', '2 giờ trước', 'Hôm qua'),
          ],
        ),
      ),
      const SizedBox(height: 12),
      const _AiCard(color: AppColors.background, child: Text('Chỉ dựa trên thông tin người bán đã cung cấp.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary))),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(child: OutlinedButton(onPressed: () => context.push('/listings/camera'), child: const Text('Xem Canon →'))),
          const SizedBox(width: 8),
          Expanded(child: OutlinedButton(onPressed: () => context.push('/listings/camera'), child: const Text('Xem Nikon →'))),
        ],
      ),
    ],
  );
}

class _MessageState extends StatelessWidget {
  const _MessageState({required this.icon, required this.title, required this.message, required this.actionLabel, required this.onAction, super.key});
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 70),
    child: Center(
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppColors.primaryDark),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 18),
          ElevatedButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    ),
  );
}

class _AiCard extends StatelessWidget {
  const _AiCard({required this.child, this.color = AppColors.cream});
  final Widget child;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
    child: child,
  );
}

class _AiListing extends StatelessWidget {
  const _AiListing({required this.title, required this.price, required this.location});
  final String title;
  final String price;
  final String location;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => context.push('/listings/camera'),
    child: Row(
      children: [
        ClipRRect(borderRadius: BorderRadius.circular(7), child: Image.asset('assets/images/marketplace/listing-camera.png', width: 62, height: 62, fit: BoxFit.cover)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)), const SizedBox(height: 3), Text(price, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primaryDark)), const SizedBox(height: 3), Text(location, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary))])),
        const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      ],
    ),
  );
}

class _CompareRow extends StatelessWidget {
  const _CompareRow(this.label, this.first, this.second, {this.heading = false});
  final String label;
  final String first;
  final String second;
  final bool heading;
  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 55),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    color: heading ? AppColors.cream : AppColors.surface,
    child: Row(
      children: [
        SizedBox(width: 80, child: Text(label, style: TextStyle(fontSize: 10, color: heading ? AppColors.primaryDark : AppColors.textSecondary, fontWeight: heading ? FontWeight.w700 : null))),
        Expanded(child: Text(first, style: TextStyle(fontSize: 10, fontWeight: heading ? FontWeight.w700 : null))),
        Expanded(child: Text(second, style: TextStyle(fontSize: 10, fontWeight: heading ? FontWeight.w700 : null))),
      ],
    ),
  );
}
