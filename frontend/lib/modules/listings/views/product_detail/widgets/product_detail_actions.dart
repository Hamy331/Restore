import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/content/views/community_content_view.dart'
    show reportListing;
import 'product_detail_circle_button.dart';

/// Các thao tác dùng chung trên ảnh chi tiết tin ở mọi kích thước màn hình.
class ProductDetailActions extends StatelessWidget {
  const ProductDetailActions({super.key, required this.listingId});
  final String listingId;

  @override
  Widget build(BuildContext context) {
    final vi = Localizations.localeOf(context).languageCode == 'vi';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ProductDetailCircleButton(
          icon: Icons.share_outlined,
          tooltip: vi ? 'Chia sẻ tin đăng' : 'Share listing',
          onPressed: () async {
            final url = Uri.base
                .replace(fragment: '/listings/$listingId')
                .toString();
            await Clipboard.setData(ClipboardData(text: url));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    vi
                        ? 'Đã sao chép liên kết tin đăng'
                        : 'Listing link copied',
                  ),
                ),
              );
            }
          },
        ),
        const SizedBox(width: 8),
        ProductDetailCircleButton(
          icon: Icons.flag_outlined,
          tooltip: AppLocalizations.of(context)!.productReport,
          onPressed: () => reportListing(context, listingId),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
