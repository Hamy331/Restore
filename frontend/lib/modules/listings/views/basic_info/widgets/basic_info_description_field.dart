import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_labeled_text_field.dart';
import '../../../bloc/create_listing/create_listing_bloc.dart';
import '../../../bloc/create_listing/create_listing_event.dart';
import '../../../models/listing_draft.dart';

/// Ô "Mô tả chi tiết", tự điền lại nội dung đã nhập khi quay lại bước này
class BasicInfoDescriptionField extends StatefulWidget {
  final bool hasError;

  const BasicInfoDescriptionField({super.key, this.hasError = false});

  @override
  State<BasicInfoDescriptionField> createState() =>
      _BasicInfoDescriptionFieldState();
}

class _BasicInfoDescriptionFieldState extends State<BasicInfoDescriptionField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    // Điền lại nội dung đã nhập khi quay lại bước này
    _controller = TextEditingController(
      text: context.read<CreateListingBloc>().state.draft.description,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _controller,
      builder: (context, value, _) => AppLabeledTextField(
        label: l10n.detailedDescriptionLabel,
        isRequired: true,
        controller: _controller,
        hintText: l10n.listingDescriptionHint,
        minLines: 5,
        maxLines: 10,
        maxLength: ListingDraft.maxDescriptionLength,
        keyboardType: TextInputType.multiline,
        helperText: l10n.characterCount(
          value.text.length,
          ListingDraft.maxDescriptionLength,
        ),
        errorText: widget.hasError
            ? l10n.descriptionMinLengthError(ListingDraft.minDescriptionLength)
            : null,
        onChanged: (text) =>
            context.read<CreateListingBloc>().add(DescriptionChanged(text)),
      ),
    );
  }
}
