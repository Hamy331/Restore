import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/utils/formatters/time_ago_formatter.dart';
import 'package:restore/data/models/user_model.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/account/bloc/public_profile/public_profile_cubit.dart';
import 'package:restore/modules/account/bloc/public_profile/public_profile_state.dart';
import 'package:restore/modules/account/repositories/profile_repository.dart';
import 'package:restore/shared/widgets/app_local_image.dart';
import '../../../models/product_detail.dart';
import 'product_chat_sheet.dart';
import 'product_detail_section.dart';

class ProductDetailSellerCard extends StatefulWidget {
  final ProductDetail detail;
  final bool Function() signedIn;
  const ProductDetailSellerCard({
    super.key,
    required this.detail,
    required this.signedIn,
  });
  @override
  State<ProductDetailSellerCard> createState() => _SellerState();
}

class _SellerState extends State<ProductDetailSellerCard> {
  final _message = TextEditingController();
  final _sender = ListingMessageSender();
  bool _sending = false;
  late PublicProfileCubit _profile = _loadSeller();
  PublicProfileCubit _loadSeller() =>
      PublicProfileCubit(ApiProfileRepository(), widget.detail.seller.id)
        ..load();

  @override
  void didUpdateWidget(ProductDetailSellerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.detail.seller.id != widget.detail.seller.id) {
      _profile.close();
      _profile = _loadSeller();
    }
  }

  @override
  void dispose() {
    _profile.close();
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_sending || _message.text.trim().isEmpty || !widget.signedIn()) return;
    setState(() => _sending = true);
    try {
      final id = await _sender.send(widget.detail, _message.text.trim());
      if (!mounted) return;
      _message.clear();
      openListingConversation(context, id);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.productActionFailed),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _partner(AppLocalizations l) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.verified_user_rounded,
                color: Colors.deepOrange,
                size: 68,
              ),
              const SizedBox(height: 12),
              Text(
                l.sellerPartnerTitle,
                textAlign: TextAlign.center,
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Text(l.sellerPartnerInfo),
              const SizedBox(height: 20),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.actionPrimary,
                  foregroundColor: AppColors.onAction,
                ),
                onPressed: () => Navigator.pop(ctx),
                child: Text(l.sellerGotIt),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.detail, s = d.seller, l = AppLocalizations.of(context)!;
    final active = d.sellerLastActive;
    final shop = d.listing.isPartner;
    final pro = d.sellerPlanTier == 'BASIC';
    Future<void> open({bool reviews = false}) async {
      await context.push('/users/${s.id}${reviews ? '?tab=reviews' : ''}');
      if (mounted && _profile.userId == s.id) await _profile.load();
    }

    return ProductDetailSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  GestureDetector(
                    onTap: open,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4, bottom: 4),
                      child: _Avatar(seller: s, size: 48),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: BlocProvider.value(
                      value: _profile,
                      child:
                          BlocConsumer<PublicProfileCubit, PublicProfileState>(
                            listenWhen: (a, b) => b.actionFailed,
                            listener: (context, _) =>
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(l.productActionFailed),
                                  ),
                                ),
                            builder: (context, state) => Material(
                              color: AppColors.actionPrimary,
                              shape: const CircleBorder(),
                              child: IconButton(
                                color: AppColors.onAction,
                                constraints: const BoxConstraints.tightFor(
                                  width: 25,
                                  height: 25,
                                ),
                                padding: EdgeInsets.zero,
                                tooltip: state.profile?.followsSeller == true
                                    ? l.feedUnfollow
                                    : l.feedFollow,
                                onPressed: state.following
                                    ? null
                                    : () async {
                                        if (!widget.signedIn()) return;
                                        final c = context
                                            .read<PublicProfileCubit>();
                                        if (c.state.profile == null) {
                                          await c.load();
                                        }
                                        if (!c.isClosed) await c.toggleFollow();
                                      },
                                icon: Icon(
                                  state.profile?.followsSeller == true
                                      ? Icons.check
                                      : Icons.add,
                                  size: 17,
                                ),
                              ),
                            ),
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: open,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              s.fullName.isEmpty ? s.username : s.fullName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          if (shop || pro)
                            Tooltip(
                              message: shop ? l.planShop : l.planBasic,
                              child: Icon(
                                shop
                                    ? Icons.storefront
                                    : Icons.workspace_premium_outlined,
                                color: AppColors.primary,
                                size: 17,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        d.sellerSoldCount == null
                            ? l.productSellerListings(d.sellerActiveListings)
                            : '${d.sellerSoldCount} ${l.sellerSold}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      if (active != null)
                        Text(
                          '${l.sellerActivity} ${TimeAgoFormatter.format(active, l)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              InkWell(
                onTap: () => open(reviews: true),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (s.ratingCount > 0)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            s.ratingAverage.toStringAsFixed(1),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Icon(
                            Icons.star,
                            color: AppColors.primary,
                            size: 16,
                          ),
                        ],
                      ),
                    Text(
                      l.reviewCount(s.ratingCount),
                      style: const TextStyle(
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (d.isAvailable) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xfff6f6f6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _message,
                      enabled: !_sending,
                      maxLength: 2000,
                      decoration: InputDecoration(
                        hintText: l.listingMessageHint,
                        counterText: '',
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                      ),
                    ),
                  ),
                  FilledButton(
                    onPressed: _sending ? null : _send,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.actionPrimary,
                      foregroundColor: AppColors.onAction,
                    ),
                    child: Text(l.listingSend),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  l.sellerQuickChat,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final q in productQuestions(d, l))
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ActionChip(
                              label: Text(q),
                              onPressed: _sending
                                  ? null
                                  : () {
                                      _message.value = TextEditingValue(
                                        text: q,
                                        selection: TextSelection.collapsed(
                                          offset: q.length,
                                        ),
                                      );
                                    },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (shop) ...[
            const Divider(),
            Material(
              type: MaterialType.transparency,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: const Icon(
                  Icons.verified_user,
                  color: Colors.deepOrange,
                ),
                title: Text(l.sellerPartnerTitle),
                trailing: const Icon(Icons.expand_more),
                onTap: () => _partner(l),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final UserModel seller;
  final double size;

  const _Avatar({required this.seller, required this.size});

  /// Chữ cái đầu của tên gọi (chữ cuối trong họ tên tiếng Việt)
  String get _initial {
    final parts = seller.fullName.trim().split(RegExp(r'\s+'));
    final word = parts.last.isEmpty ? seller.username : parts.last;
    return word.isEmpty ? '?' : word.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = seller.avatarUrl;
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.fill,
        border: Border.all(color: AppColors.surface, width: 2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: avatarUrl != null
          ? AppLocalImage(path: avatarUrl, cacheWidth: 160)
          : Text(
              _initial,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
              ),
            ),
    );
  }
}
