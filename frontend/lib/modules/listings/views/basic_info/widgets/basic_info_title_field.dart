import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_labeled_text_field.dart';
import '../../../bloc/create_listing/create_listing_bloc.dart';
import '../../../bloc/create_listing/create_listing_event.dart';
import '../../../models/listing_draft.dart';

/// Ô "Tiêu đề tin đăng", tự điền lại nội dung đã nhập khi quay lại bước này
class BasicInfoTitleField extends StatefulWidget {
  final bool hasError;

  const BasicInfoTitleField({super.key, this.hasError = false});

  @override
  State<BasicInfoTitleField> createState() => _BasicInfoTitleFieldState();
}

class _BasicInfoTitleFieldState extends State<BasicInfoTitleField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    // Điền lại nội dung đã nhập khi quay lại bước này
    _controller = TextEditingController(
      text: context.read<CreateListingBloc>().state.draft.title,
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

    return AppLabeledTextField(
      label: l10n.listingTitleLabel,
      isRequired: true,
      controller: _controller,
      hintText: l10n.listingTitleHint,
      maxLength: ListingDraft.maxTitleLength,
      textInputAction: TextInputAction.next,
      errorText: widget.hasError
          ? l10n.listingTitleMinLengthError(ListingDraft.minTitleLength)
          : null,
      onChanged: (text) =>
          context.read<CreateListingBloc>().add(TitleChanged(text)),
    );
  }
}
