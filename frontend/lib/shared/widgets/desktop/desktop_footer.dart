import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_dimesions.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/constants/app_images.dart' show AppImages;
import 'package:restore/core/theme/app_header_palette.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/policies/views/policies_view.dart';

/// Chân trang web desktop: nền trắng trải hết màn hình, nội dung 1200px
/// ở giữa (liên kết hỗ trợ, thanh toán, mạng xã hội, tải ứng dụng).
class DesktopFooter extends StatelessWidget {
  const DesktopFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final vi = Localizations.localeOf(context).languageCode == 'vi';
    String t(String vn, String en) => vi ? vn : en;

    Widget column(String title, List<Widget> children) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              letterSpacing: .4,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );

    Widget link(String label, {String? path, IconData? icon}) => Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: InkWell(
        onTap: path == null ? null : () => context.push(path),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15, color: AppColors.textSecondary),
              const SizedBox(width: 7),
            ],
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    Widget chip(Widget child) => Container(
      width: 72,
      height: 36,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );

    const chipText = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w800,
      color: AppColors.textPrimary,
    );

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppHeaderPalette.desktopBar, width: 3),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppDimesions.desktopContentWidth,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 36),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    column(t('Chăm sóc khách hàng', 'Customer service'), [
                      link(
                        t('Trung tâm trợ giúp', 'Help centre'),
                        path: '/support',
                      ),
                      link(
                        t('Mua bán an toàn', 'Trading safely'),
                        path: PoliciesView.sectionPath('safety'),
                      ),
                    ]),
                    column(t('Chính sách', 'Policies'), [
                      link(
                        t('Chính sách Restore', 'Restore policies'),
                        path: PoliciesView.path,
                      ),
                      link(
                        t('Quy định trả giá', 'Offer rules'),
                        path: PoliciesView.sectionPath('offers'),
                      ),
                      link(
                        t('Chính sách đánh giá', 'Review policy'),
                        path: PoliciesView.sectionPath('reviews'),
                      ),
                      link(
                        t('Báo cáo và kiểm duyệt', 'Reporting'),
                        path: PoliciesView.sectionPath('reports'),
                      ),
                    ]),
                    column(t('Về Restore', 'About Restore'), [
                      link(t('Gói thành viên', 'Membership'), path: '/plans'),
                      link(l10n.homeQuickTrustedShops, path: '/trusted-shops'),
                      link(l10n.hotSaleTitle, path: '/hot-sale'),
                      link(l10n.homeQuickWanted, path: '/wanted-alerts'),
                    ]),
                    column(t('Thanh toán', 'Payment'), [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          chip(Image.asset(AppImages.appLogos.vietQr)),
                          chip(Image.asset(AppImages.appLogos.zaloPay)),
                          chip(const Text('COD', style: chipText)),
                          chip(Text(t('Xu', 'Coins'), style: chipText)),
                        ],
                      ),
                    ]),
                    column(t('Theo dõi', 'Follow us'), [
                      link('Facebook', icon: AppIcons.globe),
                      link('Instagram', icon: AppIcons.camera),
                      link('Zalo OA', icon: AppIcons.chat),
                    ]),
                    column(t('Tải ứng dụng Restore', 'Get the app'), [
                      // Wrap: màn hẹp (1024px) thì nút tải xuống dòng
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Image.asset(AppImages.appLogos.appLogo),
                          ),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _StoreBadge('App Store'),
                              SizedBox(height: 6),
                              _StoreBadge('Google Play'),
                            ],
                          ),
                        ],
                      ),
                    ]),
                  ],
                ),
                const SizedBox(height: 28),
                const Divider(height: 1, color: AppColors.border),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Row(
                    children: [
                      // Expanded: khung hẹp thì dòng bản quyền xuống dòng thay vì tràn
                      Expanded(
                        child: Text(
                          t(
                            '© 2026 Restore. Mua bán, trao đổi đồ cũ.',
                            '© 2026 Restore. Buy, sell and swap pre-loved items.',
                          ),
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Tiếng Việt · English',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StoreBadge extends StatelessWidget {
  const _StoreBadge(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Text(
      label,
      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
    ),
  );
}
