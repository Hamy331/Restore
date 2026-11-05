import 'package:restore/core/ui/layouts/t_responsive_layout.dart';
import 'account_mobile_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/bloc/auth/auth_context.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../feeds/repositories/feeds_repository.dart';
import '../../bloc/account_listings/account_listings_cubit.dart';
import '../../bloc/account_listings/account_listings_state.dart';
import '../../bloc/user_profile/user_profile_cubit.dart';
import '../../repositories/account_listings_repository.dart';
import '../../models/profile_models.dart';
import '../../repositories/profile_repository.dart';

class AccountView extends StatelessWidget {
  const AccountView({
    super.key,
    this.profileRepository,
    this.listingsRepository,
    this.feedsRepository,
  });
  final ProfileRepository? profileRepository;
  final AccountListingsRepository? listingsRepository;
  final FeedsRepository? feedsRepository;

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (_) => AccountListingsCubit(
          listingsRepository ?? ApiAccountListingsRepository(),
        )..load(),
      ),
      BlocProvider(
        create: (context) {
          final user = context.currentUser;
          return UserProfileCubit(
            profileRepository ?? ApiProfileRepository(),
            initial: user == null
                ? null
                : ProfileData(
                    id: user.id,
                    fullName: user.fullName,
                    username: user.username,
                    avatarUrl: user.avatarUrl,
                    ratingAverage: user.ratingAverage,
                    ratingCount: user.ratingCount,
                    followerCount: 0,
                    followingCount: 0,
                  ),
          )..load();
        },
      ),
      RepositoryProvider<FeedsRepository>(
        create: (_) => feedsRepository ?? ApiFeedsRepository(),
      ),
    ],
    child: BlocListener<AccountListingsCubit, AccountListingsState>(
      listenWhen: (_, state) => state.error != null,
      listener: (context, state) {
        final l = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              state.error == AccountListingsError.update
                  ? l.accUpdateListingError
                  : l.accLoadListingsError,
            ),
          ),
        );
      },
      child: const TResponsiveLayout(mobile: AccountMobileView()),
    ),
  );
}
