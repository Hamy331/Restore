import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_choice_chips.dart';
import 'package:restore/shared/widgets/app_labeled_choice_row.dart';
import '../../../bloc/create_listing/create_listing_bloc.dart';
import '../../../bloc/create_listing/create_listing_event.dart';
import '../../../models/listing_enums.dart';

/// Dòng "Bạn là": Cá nhân / Bán chuyên
class BasicInfoSellerTypeRow extends StatelessWidget {
  final SellerType sellerType;

  const BasicInfoSellerTypeRow({super.key, required this.sellerType});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppLabeledChoiceRow<SellerType>(
      label: l10n.youAreLabel,
      selected: sellerType,
      items: [
        AppChoiceItem(SellerType.personal, l10n.sellerPersonal),
        AppChoiceItem(SellerType.business, l10n.sellerBusiness),
      ],
      onSelected: (value) =>
          context.read<CreateListingBloc>().add(SellerTypeChanged(value)),
    );
  }
}
