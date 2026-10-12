import 'package:flutter/material.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_labeled_text_field.dart';

/// Ô số nhà, tên đường (không bắt buộc, không hiển thị công khai)
class AddressStreetField extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;

  static const int maxLength = 120;

  const AddressStreetField({
    super.key,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<AddressStreetField> createState() => _AddressStreetFieldState();
}

class _AddressStreetFieldState extends State<AddressStreetField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppLabeledTextField(
      label: l10n.streetAddressLabel,
      controller: _controller,
      hintText: l10n.streetAddressHint,
      helperText: l10n.streetAddressHelper,
      maxLength: AddressStreetField.maxLength,
      textInputAction: TextInputAction.done,
      onChanged: widget.onChanged,
    );
  }
}
