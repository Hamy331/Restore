import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/ui/responsive/responsive_content.dart';
import '../../../shared/widgets/listing_grid.dart';
import '../../listings/presentation/fixtures/figma_preview_listings.dart';

class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final _name = TextEditingController(text: 'Ngô Tường Phát');
  final _phone = TextEditingController(text: '090 123 4567');
  final _birthday = TextEditingController(text: '12/08/1996');
  String _gender = 'Nam';
  String _area = 'Quận 1, TP. Hồ Chí Minh';

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _birthday.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _DetailScaffold(
    title: 'Chỉnh sửa hồ sơ',
    footer: _PrimaryFooter(
      label: 'Lưu thay đổi',
      onPressed: () => _notice(context, 'Hồ sơ sẽ được lưu qua API.'),
    ),
    child: Column(
      children: [
        const SizedBox(height: 4),
        const CircleAvatar(
          radius: 32,
          backgroundColor: AppColors.infoBg,
          child: Text(
            'TP',
            style: TextStyle(
              color: Color(0xFF1E3A8A),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        TextButton(
          onPressed: () => _notice(context, 'Chọn ảnh đại diện'),
          child: const Text('Đổi ảnh đại diện'),
        ),
        _ProfileField(label: 'Họ và tên', controller: _name),
        _ProfileField(
          label: 'Số điện thoại',
          controller: _phone,
          keyboardType: TextInputType.phone,
        ),
        _ProfileField(label: 'Ngày sinh', controller: _birthday),
        _SelectField(
          label: 'Giới tính',
          value: _gender,
          values: const ['Nam', 'Nữ', 'Khác'],
          onChanged: (value) => setState(() => _gender = value),
        ),
        _SelectField(
          label: 'Khu vực',
          value: _area,
          values: const [
            'Quận 1, TP. Hồ Chí Minh',
            'Thủ Đức, TP. Hồ Chí Minh',
            'Quận 3, TP. Hồ Chí Minh',
          ],
          onChanged: (value) => setState(() => _area = value),
        ),
      ],
    ),
  );
}

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool _notifications = true;

  @override
  Widget build(BuildContext context) => _DetailScaffold(
    title: 'Cài đặt',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tùy chọn',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        _SettingsItem(
          icon: Icons.notifications_none,
          label: 'Nhận thông báo',
          trailing: Switch(
            value: _notifications,
            activeTrackColor: AppColors.primary,
            onChanged: (value) => setState(() => _notifications = value),
          ),
        ),
        _SettingsItem(
          icon: Icons.shield_outlined,
          label: 'Quyền riêng tư',
          onTap: () => _notice(context, 'Quyền riêng tư'),
        ),
        _SettingsItem(
          icon: Icons.lock_outline,
          label: 'Đổi mật khẩu',
          onTap: () => context.push('/forgot-password'),
        ),
        _SettingsItem(
          icon: Icons.help_outline,
          label: 'Trợ giúp / Hỗ trợ',
          onTap: () => _notice(context, 'Trợ giúp / Hỗ trợ'),
        ),
        _SettingsItem(
          icon: Icons.description_outlined,
          label: 'Điều khoản & chính sách',
          onTap: () => _notice(context, 'Điều khoản & chính sách'),
        ),
        _SettingsItem(
          icon: Icons.logout,
          label: 'Đăng xuất',
          onTap: () => context.go('/welcome'),
        ),
      ],
    ),
  );
}

class FavoritesView extends StatefulWidget {
  const FavoritesView({super.key});

  @override
  State<FavoritesView> createState() => _FavoritesViewState();
}

class _FavoritesViewState extends State<FavoritesView> {
  late final List _saved = [...figmaPreviewListings.take(4)];

  @override
  Widget build(BuildContext context) => _DetailScaffold(
    title: 'Tin đã lưu',
    child: _saved.isEmpty
        ? Padding(
            padding: const EdgeInsets.only(top: 120),
            child: Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.favorite_border,
                    size: 54,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Chưa có tin đã lưu',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  const Text('Lưu tin bạn quan tâm để xem lại nhanh hơn.'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('Khám phá sản phẩm'),
                  ),
                ],
              ),
            ),
          )
        : Column(
            children: [
              Row(
                children: [
                  Text(
                    '${_saved.length} tin đã lưu',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Chạm ♡ để bỏ lưu',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListingGrid(listings: _saved.cast()),
            ],
          ),
  );
}

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  static const _groups = <String, List<(IconData, String, String, String, bool)>>{
    'Hôm nay': [
      (Icons.chat_bubble_outline, 'Tin nhắn mới', 'Minh Anh vừa gửi thêm ảnh máy Canon AE-1.', '09:44', true),
      (Icons.sell_outlined, 'Đề nghị giá mới', 'Có đề nghị 2.200.000 đ cho tin Canon AE-1.', '09:47', true),
      (Icons.swap_horiz, 'Phản hồi đề nghị', 'Minh Anh đề nghị mức giá khác: 2.300.000 đ.', '09:52', false),
    ],
    'Hôm qua': [
      (Icons.verified_outlined, 'Tin đăng đã được duyệt', 'Tin Đèn bàn đồng vintage đang hiển thị.', '18:30', false),
      (Icons.edit_note, 'Tin cần chỉnh sửa', 'Vui lòng bổ sung ảnh cho tin Ghế gỗ sồi.', '15:10', false),
    ],
    'Trước đó': [
      (Icons.favorite_border, 'Tin của bạn được lưu', '3 người đã lưu tin Canon AE-1 của bạn.', '12/09', false),
    ],
  };

  @override
  Widget build(BuildContext context) => _DetailScaffold(
    title: 'Thông báo',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _groups.entries.expand((group) sync* {
        yield Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: Text(
            group.key,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        );
        for (final item in group.value) {
          yield _NotificationCard(item: item);
        }
      }).toList(),
    ),
  );
}

class _DetailScaffold extends StatelessWidget {
  const _DetailScaffold({
    required this.title,
    required this.child,
    this.footer,
  });

  final String title;
  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(title: Text(title)),
    body: SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ResponsiveContent(maxWidth: 720, child: child),
    ),
    bottomNavigationBar: footer,
  );
}

class _PrimaryFooter extends StatelessWidget {
  const _PrimaryFooter({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: ResponsiveContent(
        maxWidth: 720,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: SizedBox(
          height: 48,
          width: double.infinity,
          child: ElevatedButton(onPressed: onPressed, child: Text(label)),
        ),
      ),
    ),
  );
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.label,
    required this.controller,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        TextField(controller: controller, keyboardType: keyboardType),
      ],
    ),
  );
}

class _SelectField extends StatelessWidget {
  const _SelectField({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: value,
          items: values
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: (item) {
            if (item != null) onChanged(item);
          },
        ),
      ],
    ),
  );
}

class _SettingsItem extends StatelessWidget {
  const _SettingsItem({
    required this.icon,
    required this.label,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Ink(
        height: 55,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 21, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
            trailing ??
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
          ],
        ),
      ),
    ),
  );
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item});

  final (IconData, String, String, String, bool) item;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    constraints: const BoxConstraints(minHeight: 83),
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: item.$5 ? AppColors.primarySoft : AppColors.surface,
      borderRadius: BorderRadius.circular(9),
    ),
    child: Row(
      children: [
        CircleAvatar(
          radius: 19,
          backgroundColor: AppColors.surface,
          child: Icon(item.$1, size: 20, color: AppColors.primaryDark),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.$2,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    item.$4,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (item.$5) ...[
                    const SizedBox(width: 8),
                    const CircleAvatar(
                      radius: 3,
                      backgroundColor: AppColors.primary,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                item.$3,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

void _notice(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
