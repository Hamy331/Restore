import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/location/models/address_info.dart';
import 'package:restore/modules/location/widgets/address_picker_sheet.dart';
import 'package:restore/shared/widgets/app_select_field.dart';
import 'package:restore/core/constants/app_icons.dart';
import '../../../bloc/create_listing/create_listing_bloc.dart';
import '../../../bloc/create_listing/create_listing_event.dart';

/// Ô địa chỉ: mở sheet chọn tỉnh/thành, phường/xã hoặc lấy vị trí hiện tại
class BasicInfoLocationField extends StatelessWidget {
  final AddressInfo? address;
  final bool hasError;

  const BasicInfoLocationField({
    super.key,
    required this.address,
    this.hasError = false,
  });

  Future<void> _onPick(BuildContext context) async {
    final bloc = context.read<CreateListingBloc>();
    final selected = await showAddressPickerSheet(context, initial: address);
    if (selected != null) bloc.add(AddressChanged(selected));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final address = this.address;

    return AppSelectField(
      label: l10n.addressLabel,
      isRequired: true,
      leadingIcon: AppIcons.location,
      value: address?.areaLabel,
      placeholder: l10n.selectAddressHint,
      helperText: address == null
          ? l10n.addressNearbyHint
          : address.streetAddress.isEmpty
          ? null
          : l10n.privateStreetAddress(address.streetAddress),
      errorText: hasError ? l10n.fieldSelectRequiredError : null,
      onTap: () => _onPick(context),
    );
  }
}
