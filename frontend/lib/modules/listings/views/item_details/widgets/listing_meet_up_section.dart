import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/location/models/address_info.dart';
import 'package:restore/modules/location/widgets/address_picker_sheet.dart';
import 'package:restore/shared/widgets/app_field_message.dart';
import '../../../bloc/create_listing/create_listing_bloc.dart';
import '../../../bloc/create_listing/create_listing_event.dart';
import 'listing_form_widgets.dart';

/// "Gặp mặt trực tiếp": công tắc và thẻ khu vực giao dịch. Khu vực luôn cần
/// (để tin hiện ở Gần tôi / lọc khu vực); tắt gặp mặt thì người mua biết sẽ
/// thỏa thuận cách giao qua chat.
class ListingMeetUpSection extends StatelessWidget {
  const ListingMeetUpSection({
    super.key,
    required this.meetUp,
    required this.address,
    this.errorText,
  });

  final bool meetUp;
  final AddressInfo? address;
  final String? errorText;

  Future<void> _pick(BuildContext context) async {
    final bloc = context.read<CreateListingBloc>();
    final selected = await showAddressPickerSheet(context, initial: address);
    if (selected != null) bloc.add(AddressChanged(selected));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final address = this.address;
    final radius = BorderRadius.circular(12);
    final hasError = errorText != null;
    final String heading;
    if (address == null) {
      heading = l10n.meetUpChooseArea;
    } else {
      heading = meetUp ? l10n.meetUpLocationCount : l10n.meetUpYourArea;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListingSwitchRow(
          title: l10n.meetUpTitle,
          titleStyle: ListingFormStyle.label.copyWith(fontSize: 17),
          value: meetUp,
          onChanged: (value) =>
              context.read<CreateListingBloc>().add(MeetUpChanged(value)),
        ),
        const SizedBox(height: 12),
        Material(
          color: AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(
              color: hasError ? AppColors.error : AppColors.border,
              width: 1.2,
            ),
          ),
          child: InkWell(
            borderRadius: radius,
            onTap: () => _pick(context),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    AppIcons.location,
                    size: 26,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          heading,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (address != null) ...[
                          Text(
                            address.areaLabel,
                            style: const TextStyle(
                              fontSize: 15,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (address.streetAddress.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              l10n.privateStreetAddress(address.streetAddress),
                              style: ListingFormStyle.subtitle.copyWith(
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ] else
                          Text(
                            l10n.addressNearbyHint,
                            style: ListingFormStyle.subtitle,
                          ),
                        if (!meetUp) ...[
                          const SizedBox(height: 6),
                          Text(
                            l10n.meetUpOffNote,
                            style: ListingFormStyle.subtitle,
                          ),
                        ],
                        const SizedBox(height: 10),
                        Text(
                          address == null
                              ? l10n.selectAddressHint
                              : l10n.meetUpEdit,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.actionPrimary,
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
        AppFieldMessage(errorText: errorText),
      ],
    );
  }
}
