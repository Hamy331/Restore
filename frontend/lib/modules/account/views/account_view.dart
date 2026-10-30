import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/ui/responsive/responsive_content.dart';
import '../../../core/utils/formatters/currency_formatter.dart';
import '../../../shared/widgets/app_local_image.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../bloc/account_profile_cubit.dart';
import '../bloc/user_profile_cubit.dart';
import '../repositories/profile_repository.dart';
import '../../listings/repositories/listings_repository.dart';

const _ink = Color(0xFF171717);
const _muted = Color(0xFF737985);
const _line = Color(0xFFE6E8EB);
const _accent = Color(0xFFFFB21A);

class AccountView extends StatelessWidget {
  const AccountView({super.key});

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider(create: (_) => AccountProfileCubit(
        repository: AppEnvironment.useMockData ? null : ApiListingsRepository(),
      )),
      BlocProvider(
        create: (_) => UserProfileCubit(
          AppEnvironment.useMockData
              ? MockProfileRepository()
              : ApiProfileRepository(),
        )..load(),
      ),
    ],
    child: BlocListener<AccountProfileCubit, AccountProfileState>(
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!)));
        }
      },
      child: const _AccountPage(),
    ),
  );
}

class _AccountPage extends StatelessWidget {
  const _AccountPage();

  void _soon(BuildContext context) =>
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tính năng này đang được phát triển')),
      );

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: ColoredBox(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 125),
        child: ResponsiveContent(
          maxWidth: 480,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Row(
                children: [
                  IconButton(
                    tooltip: 'Chỉnh sửa trang',
                    onPressed: () => _editProfile(context),
                    icon: const Icon(AppIcons.edit, color: _ink, size: 25),
                  ),
                  const SizedBox(width: 14),
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: _accent,
                      shape: BoxShape.circle,
                    ),
                    child: const Text(
                      'R',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 19,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Hoạt động',
                    onPressed: () => _soon(context),
                    icon: const Icon(AppIcons.activity, color: _ink, size: 25),
                  ),
                  IconButton(
                    tooltip: 'Theo dõi bạn bè',
                    onPressed: () => _soon(context),
                    icon: const Icon(
                      AppIcons.followUser,
                      color: _ink,
                      size: 25,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Menu và cài đặt',
                    onPressed: () => _showMenu(context),
                    icon: const Icon(AppIcons.menu, color: _ink, size: 26),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              BlocBuilder<UserProfileCubit, UserProfileState>(
                builder: (context, userState) {
                  final profile = userState.profile;
                  if (profile == null && !userState.loading) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: TextButton(
                        onPressed: () =>
                            context.read<UserProfileCubit>().load(),
                        child: const Text('Không tải được hồ sơ. Thử lại'),
                      ),
                    );
                  }
                  final name = profile?.fullName ?? 'Đang tải...';
                  final initials = name
                      .trim()
                      .split(RegExp(r'\s+'))
                      .where((part) => part.isNotEmpty)
                      .map((part) => part[0].toUpperCase())
                      .take(2)
                      .join();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 29,
                                    fontWeight: FontWeight.w800,
                                    color: _ink,
                                    height: 1.05,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '@${profile?.username ?? ''}',
                                  style: const TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 15,
                                    color: _muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () => _editProfile(context),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                CircleAvatar(
                                  radius: 45,
                                  backgroundColor: const Color(0xFFF0F1F3),
                                  backgroundImage: profile?.avatarUrl != null
                                      ? NetworkImage(profile!.avatarUrl!)
                                      : null,
                                  child: profile?.avatarUrl == null
                                      ? Text(
                                          initials,
                                          style: const TextStyle(
                                            fontFamily: 'DM Sans',
                                            fontSize: 27,
                                            color: _muted,
                                          ),
                                        )
                                      : null,
                                ),
                                Positioned(
                                  right: -3,
                                  bottom: -2,
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: _accent,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      AppIcons.add,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 23),
                      BlocBuilder<AccountProfileCubit, AccountProfileState>(
                        builder: (context, listingState) => Row(
                          children: [
                            Expanded(
                              child: _Stat(
                                value: '${profile?.followingCount ?? 0}',
                                label: 'Đang theo dõi',
                              ),
                            ),
                            Expanded(
                              child: _Stat(
                                value: '${profile?.followerCount ?? 0}',
                                label: 'Follower',
                              ),
                            ),
                            Expanded(
                              child: _Stat(
                                value:
                                    '${listingState.count(AccountListingStatus.visible)}',
                                label: 'Tin đăng',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 23),
                      InkWell(
                        onTap: () => _editProfile(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F3F3),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            profile?.bio?.isNotEmpty == true
                                ? profile!.bio!
                                : '＋  Thêm giới thiệu',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 14,
                              color: _muted,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _TopAction(
                      icon: AppIcons.pro,
                      label: 'Gói Pro',
                      onTap: () => _soon(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TopAction(
                      icon: AppIcons.store,
                      label: 'Tạo cửa hàng',
                      onTap: () => _soon(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              const _ListingTabs(),
              const SizedBox(height: 10),
              BlocBuilder<AccountProfileCubit, AccountProfileState>(
                builder: (context, state) => state.displayed.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 52),
                        child: Center(
                          child: Text(
                            state.selected == AccountListingStatus.pending
                                ? 'Chưa có tin chờ duyệt'
                                : 'Chưa có tin đã ẩn',
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              color: _muted,
                            ),
                          ),
                        ),
                      )
                    : Column(
                        children: state.displayed
                            .map((item) => _ListingRow(item: item))
                            .toList(),
                      ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Future<void> _editProfile(BuildContext context) async {
    final profile = context.read<UserProfileCubit>().state.profile;
    if (profile == null) return;
    final cubit = context.read<UserProfileCubit>();
    await showDialog<void>(
      context: context,
      builder: (_) => _EditProfileDialog(profile: profile, cubit: cubit),
    );
  }

  void _showMenu(BuildContext context) {
    showGeneralDialog<void>(
      context: context,
      barrierLabel: 'Đóng menu',
      barrierDismissible: true,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, _, _) => Align(
        alignment: Alignment.centerRight,
        child: Material(
          color: const Color(0xFFF7F8FA),
          child: SizedBox(
            width: MediaQuery.sizeOf(context).width * .75 > 360
                ? 360
                : MediaQuery.sizeOf(context).width * .75,
            height: double.infinity,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 28, 14, 28),
                child: Column(
                  children: [
                    _MenuGroup(
                      items: [
                        _MenuItem(
                          AppIcons.wallet,
                          'Xu ReStore',
                          trailing: '0',
                          onTap: () => _soon(dialogContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _MenuGroup(
                      items: [
                        _MenuItem(
                          AppIcons.favorite,
                          'Đã lưu',
                          trailing: '4',
                          onTap: () => _soon(dialogContext),
                        ),
                        _MenuItem(
                          AppIcons.search,
                          'Tìm kiếm đã lưu',
                          onTap: () => _soon(dialogContext),
                        ),
                        _MenuItem(
                          AppIcons.clock,
                          'Xem gần đây',
                          onTap: () => _soon(dialogContext),
                        ),
                        _MenuItem(
                          AppIcons.star,
                          'Đánh giá từ tôi',
                          onTap: () => _soon(dialogContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _MenuGroup(
                      items: [
                        _MenuItem(
                          AppIcons.pro,
                          'Gói Pro',
                          onTap: () => _soon(dialogContext),
                        ),
                        _MenuItem(
                          AppIcons.listings,
                          'Lịch sử giao dịch',
                          onTap: () => _soon(dialogContext),
                        ),
                        _MenuItem(
                          AppIcons.store,
                          'Cửa hàng / chuyên trang',
                          onTap: () => _soon(dialogContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _MenuGroup(
                      items: [
                        _MenuItem(
                          AppIcons.settings,
                          'Cài đặt tài khoản',
                          onTap: () => _soon(dialogContext),
                        ),
                        _MenuItem(
                          AppIcons.help,
                          'Trợ giúp',
                          onTap: () => _soon(dialogContext),
                        ),
                        _MenuItem(
                          AppIcons.chat,
                          'Đóng góp ý kiến',
                          onTap: () => _soon(dialogContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _MenuGroup(
                      items: [
                        _MenuItem(
                          AppIcons.logout,
                          'Đăng xuất',
                          danger: true,
                          onTap: () {
                            Navigator.of(dialogContext).pop();
                            context.read<AuthBloc>().add(LoggedOut());
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      transitionBuilder: (_, animation, __, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
        child: child,
      ),
    );
  }
}

class _EditProfileDialog extends StatefulWidget {
  const _EditProfileDialog({required this.profile, required this.cubit});
  final ProfileData profile;
  final UserProfileCubit cubit;

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late final TextEditingController name;
  late final TextEditingController username;
  late final TextEditingController bio;
  late final TextEditingController avatar;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.profile.fullName);
    username = TextEditingController(text: widget.profile.username);
    bio = TextEditingController(text: widget.profile.bio ?? '');
    avatar = TextEditingController(text: widget.profile.avatarUrl ?? '');
  }

  @override
  void dispose() {
    name.dispose();
    username.dispose();
    bio.dispose();
    avatar.dispose();
    super.dispose();
  }

  Future<void> save() async {
    setState(() => saving = true);
    final saved = await widget.cubit.update({
      'fullName': name.text.trim(),
      'username': username.text.trim(),
      'bio': bio.text.trim(),
      'avatarUrl': avatar.text.trim().isEmpty ? null : avatar.text.trim(),
    });
    if (!mounted) return;
    if (saved) {
      Navigator.pop(context);
      return;
    }
    setState(() => saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Không lưu được hồ sơ. Vui lòng kiểm tra thông tin.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Chỉnh sửa hồ sơ'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: name,
            maxLength: 80,
            decoration: const InputDecoration(labelText: 'Tên hiển thị'),
          ),
          TextField(
            controller: username,
            maxLength: 30,
            decoration: const InputDecoration(labelText: 'Username'),
          ),
          TextField(
            controller: bio,
            maxLength: 300,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Giới thiệu'),
          ),
          TextField(
            controller: avatar,
            decoration: const InputDecoration(
              labelText: 'URL ảnh đại diện (HTTPS)',
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: saving ? null : () => Navigator.pop(context),
        child: const Text('Hủy'),
      ),
      TextButton(onPressed: saving ? null : save, child: const Text('Lưu')),
    ],
  );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value,
        style: const TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 21,
          fontWeight: FontWeight.w700,
          color: _ink,
        ),
      ),
      Text(
        label,
        style: const TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 13,
          color: _muted,
        ),
      ),
    ],
  );
}

class _TopAction extends StatelessWidget {
  const _TopAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      side: const BorderSide(color: _line),
      borderRadius: BorderRadius.circular(28),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: SizedBox(
        height: 48,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 19, color: _ink),
            const SizedBox(width: 9),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _ink,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ListingTabs extends StatelessWidget {
  const _ListingTabs();

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AccountProfileCubit, AccountProfileState>(
        builder: (context, state) => Row(
          children: [
            _Tab(AccountListingStatus.visible, 'ĐANG HIỂN THỊ', state),
            _Tab(AccountListingStatus.pending, 'CHỜ DUYỆT', state),
            _Tab(AccountListingStatus.hidden, 'ĐÃ ẨN', state),
          ],
        ),
      );
}

class _Tab extends StatelessWidget {
  const _Tab(this.status, this.label, this.state);
  final AccountListingStatus status;
  final String label;
  final AccountProfileState state;

  @override
  Widget build(BuildContext context) {
    final active = state.selected == status;
    return Expanded(
      child: InkWell(
        onTap: () => context.read<AccountProfileCubit>().select(status),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 13),
              child: FittedBox(
                child: Text(
                  '$label (${state.count(status)})',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: active ? _ink : _muted,
                  ),
                ),
              ),
            ),
            Container(height: 3, color: active ? _accent : Colors.transparent),
          ],
        ),
      ),
    );
  }
}

class _ListingRow extends StatelessWidget {
  const _ListingRow({required this.item});
  final AccountListing item;

  @override
  Widget build(BuildContext context) {
    final isHidden = item.status == AccountListingStatus.hidden;
    void soon() => ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tính năng này đang được phát triển')),
    );
    return Column(
      children: [
        const Divider(height: 1, color: _line),
        const SizedBox(height: 14),
        InkWell(
          onTap: () => context.push('/listings/${item.id}'),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: AppLocalImage(
                  path: item.image,
                  width: 78,
                  height: 79,
                  cacheWidth: 160,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      CurrencyFormatter.formatVnd(item.price),
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.category} · Đăng ${item.posted} · ${item.views} lượt xem',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 9,
                        color: _muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            const SizedBox(width: 90),
            Expanded(child: _RowAction('Chỉnh sửa', onTap: soon)),
            const SizedBox(width: 4),
            Expanded(
              child: _RowAction(
                isHidden ? 'Hiện tin' : 'Ẩn tin',
                onTap: () => context.read<AccountProfileCubit>().setStatus(
                  item.id,
                  isHidden
                      ? AccountListingStatus.visible
                      : AccountListingStatus.hidden,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _RowAction(
                'Đẩy tin',
                filled: true,
                onTap: () => context.push('/boost/${item.id}'),
              ),
            ),
            SizedBox(
              width: 30,
              child: IconButton(
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                tooltip: 'Thêm tùy chọn',
                onPressed: soon,
                icon: const Icon(AppIcons.more, size: 19, color: _ink),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _RowAction extends StatelessWidget {
  const _RowAction(this.label, {required this.onTap, this.filled = false});
  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) => Material(
    color: filled ? _accent : const Color(0xFFF0F1F3),
    borderRadius: BorderRadius.circular(5),
    child: InkWell(
      borderRadius: BorderRadius.circular(5),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
        child: Center(
          child: FittedBox(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _ink,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _MenuItem {
  const _MenuItem(
    this.icon,
    this.label, {
    required this.onTap,
    this.trailing,
    this.danger = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? trailing;
  final bool danger;
}

class _MenuGroup extends StatelessWidget {
  const _MenuGroup({required this.items});
  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(18),
    child: ColoredBox(
      color: Colors.white,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: _line),
            InkWell(
              onTap: items[i].onTap,
              child: SizedBox(
                height: 57,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 17),
                  child: Row(
                    children: [
                      Icon(
                        items[i].icon,
                        size: 22,
                        color: items[i].danger ? const Color(0xFFEF3434) : _ink,
                      ),
                      const SizedBox(width: 17),
                      Expanded(
                        child: Text(
                          items[i].label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 14,
                            color: items[i].danger
                                ? const Color(0xFFEF3434)
                                : _ink,
                          ),
                        ),
                      ),
                      if (items[i].trailing != null)
                        Text(
                          items[i].trailing!,
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 14,
                            color: _accent,
                          ),
                        ),
                      const SizedBox(width: 8),
                      const Icon(
                        AppIcons.chevronRight,
                        size: 17,
                        color: _muted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
