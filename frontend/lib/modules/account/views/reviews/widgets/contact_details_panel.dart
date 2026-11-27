import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/data/models/shop_opening_hours.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/profile_models.dart';

/// Tab Liên hệ của cửa hàng: số điện thoại (che bớt, bấm để hiện), website,
/// email, địa chỉ, giờ mở cửa. Mỗi dòng có nút hành động (gọi / Zalo, mở
/// link, mở bản đồ) và nút sao chép.
class ContactDetailsPanel extends StatefulWidget {
  const ContactDetailsPanel({super.key, required this.profile});
  final ProfileData profile;

  @override
  State<ContactDetailsPanel> createState() => _ContactDetailsPanelState();
}

class _ContactDetailsPanelState extends State<ContactDetailsPanel> {
  bool _showPhone = false;

  static String _mask(String phone) =>
      phone.length <= 4 ? phone : '****${phone.substring(phone.length - 4)}';

  Future<void> _copy(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.revCopied)),
      );
  }

  Future<void> _open(Uri uri) async {
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Không có ứng dụng mở được: bỏ qua
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!, s = widget.profile.storefront;
    final phone = s.phone?.trim();
    final website = s.website?.trim(), email = s.businessEmail?.trim();
    final address = s.address?.trim();
    String? orNull(String? text) => text == null || text.isEmpty ? null : text;
    final rows = <Widget>[
      if (orNull(phone) != null)
        _ContactRow(
          key: const ValueKey('contact-phone'),
          icon: Icons.phone_outlined,
          title: _showPhone ? phone! : _mask(phone!),
          onTitleTap: _showPhone
              ? null
              : () => setState(() => _showPhone = true),
          titleHint: _showPhone ? null : l.revShowNumber,
          actions: [
            _Action(
              icon: Icons.call_outlined,
              tooltip: l.listingCall,
              onTap: () => _open(Uri(scheme: 'tel', path: phone)),
            ),
            _Action(
              icon: Icons.chat_bubble_outline,
              tooltip: l.revZalo,
              onTap: () => _open(Uri.parse('https://zalo.me/$phone')),
            ),
            _Action(
              icon: Icons.copy_rounded,
              tooltip: l.revCopy,
              onTap: () => _copy(phone),
            ),
          ],
        ),
      if (orNull(website) != null)
        _ContactRow(
          key: const ValueKey('contact-website'),
          icon: Icons.link_rounded,
          title: website!,
          actions: [
            _Action(
              icon: Icons.open_in_new_rounded,
              tooltip: l.revOpenWebsite,
              onTap: () => _open(Uri.parse(website)),
            ),
            _Action(
              icon: Icons.copy_rounded,
              tooltip: l.revCopy,
              onTap: () => _copy(website),
            ),
          ],
        ),
      if (orNull(email) != null)
        _ContactRow(
          key: const ValueKey('contact-email'),
          icon: Icons.mail_outline_rounded,
          title: email!,
          actions: [
            _Action(
              icon: Icons.send_outlined,
              tooltip: l.email,
              onTap: () => _open(Uri(scheme: 'mailto', path: email)),
            ),
            _Action(
              icon: Icons.copy_rounded,
              tooltip: l.revCopy,
              onTap: () => _copy(email),
            ),
          ],
        ),
      if (orNull(address) != null)
        _ContactRow(
          key: const ValueKey('contact-address'),
          icon: AppIcons.location,
          title: address!,
          actions: [
            _Action(
              icon: Icons.map_outlined,
              tooltip: l.revOpenMap,
              onTap: () => _open(
                Uri.https('www.google.com', '/maps/search/', {
                  'api': '1',
                  'query': address,
                }),
              ),
            ),
            _Action(
              icon: Icons.copy_rounded,
              tooltip: l.revCopy,
              onTap: () => _copy(address),
            ),
          ],
        ),
      if (s.openingHours.isNotEmpty)
        _ContactRow(
          key: const ValueKey('contact-hours'),
          icon: AppIcons.clock,
          title: _hoursTitle(l, s.openingHours),
          subtitle: _hoursSubtitle(l, s.openingHours),
          actions: const [],
        ),
    ];
    return ListView(
      key: const PageStorageKey('contact-details'),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      children: rows.isEmpty
          ? [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    l.revNoContact,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),
            ]
          : rows,
    );
  }

  /// Các ngày cùng một khung giờ thì gộp lại ("08:00 – 21:00"), khác nhau thì
  /// liệt kê từng thứ
  static bool _sameHours(List<ShopOpeningDay> hours) => hours.every(
    (day) => day.open == hours.first.open && day.close == hours.first.close,
  );

  static String _hoursTitle(AppLocalizations l, List<ShopOpeningDay> hours) =>
      _sameHours(hours)
      ? '${hours.first.open} – ${hours.first.close}'
      : [
          for (final day in hours)
            '${l.shopWeekday('${day.day}')}: ${day.open} – ${day.close}',
        ].join('\n');

  static String? _hoursSubtitle(
    AppLocalizations l,
    List<ShopOpeningDay> hours,
  ) {
    final open = {for (final day in hours) day.day};
    final closed = [
      for (var day = 1; day <= 7; day++)
        if (!open.contains(day)) l.shopWeekday('$day'),
    ];
    if (closed.isEmpty) return l.revOpenDaily;
    return l.revClosedOn(closed.join(', '));
  }
}

class _Action {
  const _Action({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    super.key,
    required this.icon,
    required this.title,
    required this.actions,
    this.subtitle,
    this.onTitleTap,
    this.titleHint,
  });
  final IconData icon;
  final String title;
  final String? subtitle, titleHint;
  final VoidCallback? onTitleTap;
  final List<_Action> actions;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 16),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0xffeeeeee))),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 24, color: AppColors.textSecondary),
        const SizedBox(width: 14),
        Expanded(
          child: InkWell(
            onTap: onTitleTap,
            borderRadius: BorderRadius.circular(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, height: 1.4)),
                if (titleHint != null)
                  Text(
                    titleHint!,
                    style: const TextStyle(
                      color: AppColors.actionPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle!,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
              ],
            ),
          ),
        ),
        for (final action in actions)
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              elevation: 1.5,
              shadowColor: const Color(0x33000000),
              child: IconButton(
                tooltip: action.tooltip,
                onPressed: action.onTap,
                icon: Icon(action.icon, size: 20, color: Colors.black87),
              ),
            ),
          ),
      ],
    ),
  );
}
