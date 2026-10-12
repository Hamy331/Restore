import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/theme/app_glass.dart';
import 'package:restore/core/utils/helpers/t_snackbar_helper.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/services/device_location_service.dart';
import 'package:restore/shared/widgets/animations/app_collapsible.dart';
import 'package:restore/shared/widgets/app_option_sheet.dart';
import 'package:restore/shared/widgets/app_select_field.dart';
import 'package:restore/shared/widgets/glass/app_glass_sheet.dart';
import 'package:restore/core/constants/app_icons.dart';
import '../bloc/address_picker/address_picker_cubit.dart';
import '../bloc/address_picker/address_picker_state.dart';
import '../models/address_info.dart';
import 'package:restore/data/models/administrative_unit_model.dart';
import '../repositories/location_repository.dart';
import 'address_street_field.dart';
import 'current_location_button.dart';
import 'location_notice_card.dart';

/// Mở sheet chọn địa chỉ (tỉnh/thành → phường/xã → số nhà) hoặc lấy từ GPS.
/// Cần [LocationRepository] và [DeviceLocationService] trong cây widget.
Future<AddressInfo?> showAddressPickerSheet(
  BuildContext context, {
  AddressInfo? initial,
}) {
  final l10n = AppLocalizations.of(context)!;
  final cubit = AddressPickerCubit(
    repository: context.read<LocationRepository>(),
    locationService: context.read<DeviceLocationService>(),
    initial: initial,
  )..loadProvinces();

  return showAppGlassSheet<AddressInfo>(
    context,
    title: l10n.addressSheetTitle,
    subtitle: l10n.addressNearbyHint,
    icon: AppIcons.locationArea,
    builder: (_) =>
        BlocProvider.value(value: cubit, child: const _AddressPickerBody()),
  ).whenComplete(cubit.close);
}

class _AddressPickerBody extends StatelessWidget {
  const _AddressPickerBody();

  String _locateErrorMessage(AppLocalizations l10n, DeviceLocationError e) =>
      switch (e) {
        DeviceLocationError.serviceDisabled => l10n.locationServiceDisabled,
        DeviceLocationError.permissionDenied => l10n.locationPermissionDenied,
        DeviceLocationError.permissionDeniedForever =>
          l10n.locationPermissionDeniedForever,
        DeviceLocationError.unavailable => l10n.locationUnavailable,
      };

  Future<void> _pickProvince(
    BuildContext context,
    AddressPickerState state,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<AddressPickerCubit>();
    if (state.provincesStatus == LoadStatus.failure) {
      await cubit.loadProvinces();
      return;
    }
    final selected = await _pickUnit(
      context,
      title: l10n.provinceLabel,
      units: state.provinces,
      selected: state.province,
    );
    if (selected != null) await cubit.selectProvince(selected);
  }

  Future<void> _pickWard(BuildContext context, AddressPickerState state) async {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<AddressPickerCubit>();
    if (state.wardsStatus == LoadStatus.failure) {
      await cubit.retryWards();
      return;
    }
    final selected = await _pickUnit(
      context,
      title: l10n.wardLabel,
      units: state.wards,
      selected: state.ward,
    );
    if (selected != null) cubit.selectWard(selected);
  }

  Future<AdministrativeUnitModel?> _pickUnit(
    BuildContext context, {
    required String title,
    required List<AdministrativeUnitModel> units,
    required AdministrativeUnitModel? selected,
  }) async {
    final code = await showAppOptionSheet<String>(
      context,
      title: title,
      selected: selected?.code,
      searchable: true,
      options: [for (final unit in units) AppSheetOption(unit.code, unit.name)],
    );
    if (code == null) return null;
    return units.firstWhere((unit) => unit.code == code);
  }

  String? _statusHint(AppLocalizations l10n, LoadStatus status) =>
      switch (status) {
        LoadStatus.loading => l10n.loadingLocations,
        LoadStatus.failure => l10n.loadLocationsFailed,
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return MultiBlocListener(
      listeners: [
        BlocListener<AddressPickerCubit, AddressPickerState>(
          listenWhen: (previous, current) =>
              previous.locateErrorCount != current.locateErrorCount,
          listener: (context, state) => TSnackBarHelper.showWarning(
            context,
            message: _locateErrorMessage(l10n, state.locateError!),
          ),
        ),
      ],
      child: BlocBuilder<AddressPickerCubit, AddressPickerState>(
        builder: (context, state) {
          final cubit = context.read<AddressPickerCubit>();
          final provinceStatus = state.provincesStatus;
          final wardStatus = state.wardsStatus;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  children: [
                    CurrentLocationButton(
                      isLocating: state.isLocating,
                      isDetected: state.deviceGeoPoint != null,
                      onTap: cubit.useCurrentLocation,
                    ),
                    AppCollapsible(
                      visible: state.notice != null,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: state.notice == null
                            ? const SizedBox.shrink()
                            : LocationNoticeCard(
                                notice: state.notice!,
                                onDismiss: cubit.dismissNotice,
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _OrDivider(label: l10n.orChooseManually),
                    const SizedBox(height: 16),
                    AppSelectField(
                      label: l10n.provinceLabel,
                      isRequired: true,
                      leadingIcon: AppIcons.province,
                      value: state.province?.name,
                      placeholder: l10n.selectProvinceHint,
                      helperText: _statusHint(l10n, provinceStatus),
                      enabled: provinceStatus != LoadStatus.loading,
                      onTap: () => _pickProvince(context, state),
                    ),
                    const SizedBox(height: 12),
                    AppSelectField(
                      label: l10n.wardLabel,
                      isRequired: true,
                      leadingIcon: AppIcons.ward,
                      value: state.ward?.name,
                      placeholder: state.province == null
                          ? l10n.selectProvinceFirst
                          : l10n.selectWardHint,
                      helperText: state.province == null
                          ? null
                          : _statusHint(l10n, wardStatus),
                      enabled:
                          state.province != null &&
                          wardStatus != LoadStatus.loading,
                      onTap: () => _pickWard(context, state),
                    ),
                    const SizedBox(height: 12),
                    AddressStreetField(
                      initialValue: state.streetAddress,
                      onChanged: cubit.changeStreetAddress,
                    ),
                    const SizedBox(height: 16),
                    _PrivacyNote(text: l10n.addressPrivacyNote),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: ElevatedButton(
                  onPressed: state.canConfirm
                      ? () => Navigator.of(context).pop(state.result)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textPrimary,
                    disabledBackgroundColor: AppGlass.fillSoft,
                    minimumSize: const Size.fromHeight(52),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    l10n.confirmAddress,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  final String label;
  const _OrDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    final line = Expanded(
      child: Divider(color: AppColors.textSecondary.withValues(alpha: 0.2)),
    );
    return Row(
      children: [
        line,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        line,
      ],
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  final String text;
  const _PrivacyNote({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primarySoft.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(AppIcons.shield, size: 18, color: AppColors.primaryDark),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
