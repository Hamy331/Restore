import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/ui/responsive/responsive_content.dart';

class AccountView extends StatelessWidget {
  const AccountView({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          ResponsiveContent(
            maxWidth: 720,
            child: SizedBox(
              height: 56,
              child: Row(
                children: [
                  const Text(
                    'Tài khoản',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Cài đặt',
                    onPressed: () => context.push('/settings'),
                    icon: const Icon(Icons.settings_outlined),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ColoredBox(
              color: AppColors.background,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: ResponsiveContent(
                  maxWidth: 720,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _IdentityCard(
                        onEdit: () => context.push('/account/edit'),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _MetricCard(
                              value: '3',
                              label: 'Tin đang đăng',
                              onTap: () => context.go('/manage-listings'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _MetricCard(
                              value: '12',
                              label: 'Tin đã bán',
                              onTap: () => context.go('/manage-listings'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Tài khoản của tôi',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 7),
                      _AccountItem(
                        icon: Icons.favorite_border,
                        label: 'Tin đã lưu',
                        trailing: '4',
                        onTap: () => context.push('/favorites'),
                      ),
                      _AccountItem(
                        icon: Icons.star_border,
                        label: 'Đánh giá',
                        trailing: '48',
                        onTap: () => context.push('/seller/minh-anh/reviews'),
                      ),
                      _AccountItem(
                        icon: Icons.notifications_none,
                        label: 'Thông báo',
                        trailing: '2 mới',
                        onTap: () => context.push('/notifications'),
                      ),
                      _AccountItem(
                        icon: Icons.location_on_outlined,
                        label: 'Địa chỉ / Khu vực',
                        onTap: () => _foundationNotice(context),
                      ),
                      _AccountItem(
                        icon: Icons.auto_awesome_outlined,
                        label: 'ReStore AI',
                        onTap: () => context.push('/ai-assistant'),
                      ),
                      _AccountItem(
                        icon: Icons.settings_outlined,
                        label: 'Cài đặt',
                        onTap: () => context.push('/settings'),
                      ),
                      _AccountItem(
                        icon: Icons.help_outline,
                        label: 'Trợ giúp',
                        onTap: () => _foundationNotice(context),
                      ),
                      _AccountItem(
                        icon: Icons.logout,
                        label: 'Đăng xuất',
                        onTap: () => context.go('/welcome'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static void _foundationNotice(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tính năng sẽ được kết nối ở bước API.')),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.onEdit});

  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
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
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ngô Tường Phát',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 3),
              const Text(
                'Thành viên từ 2022',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 3),
              const Text(
                '090 ••• 1234 · Quận 1, TP.HCM',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              InkWell(
                onTap: onEdit,
                child: const Padding(
                  padding: EdgeInsets.only(top: 5),
                  child: Text(
                    'Chỉnh sửa hồ sơ  ›',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.value,
    required this.label,
    required this.onTap,
  });

  final String value;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(9),
    child: Ink(
      height: 68,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    ),
  );
}

class _AccountItem extends StatelessWidget {
  const _AccountItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Ink(
        height: 44,
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
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (trailing != null)
              Text(
                trailing!,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.primaryDark,
                ),
              ),
            const SizedBox(width: 10),
            const Icon(
              Icons.chevron_right,
              size: 19,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    ),
  );
}
