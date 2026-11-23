import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/services/media_picker_service.dart';
import 'package:restore/shared/widgets/app_labeled_text_field.dart';

import 'my_shop_section.dart';

/// Hồ sơ xin xác minh: tên trên giấy phép, mã số thuế, 1-3 ảnh giấy phép.
/// [onSubmit] trả về true khi gửi xong
class MyShopVerificationForm extends StatefulWidget {
  const MyShopVerificationForm({
    super.key,
    required this.saving,
    required this.onSubmit,
    this.picker,
  });

  final bool saving;
  final Future<bool> Function(
    String businessName,
    String taxCode,
    List<Uint8List> documents,
  )
  onSubmit;
  final MediaPickerService? picker;

  static const maxDocuments = 3;

  /// Mã số doanh nghiệp / mã số thuế: 10 số, chi nhánh thêm -001
  static final taxCodePattern = RegExp(r'^\d{10}(-\d{3})?$');

  @override
  State<MyShopVerificationForm> createState() => _MyShopVerificationFormState();
}

class _MyShopVerificationFormState extends State<MyShopVerificationForm> {
  final _name = TextEditingController();
  final _taxCode = TextEditingController();
  final _documents = <Uint8List>[];
  bool _showErrors = false;

  @override
  void dispose() {
    _name.dispose();
    _taxCode.dispose();
    super.dispose();
  }

  bool get _nameValid {
    final length = _name.text.trim().length;
    return length >= 2 && length <= 120;
  }

  bool get _taxCodeValid =>
      MyShopVerificationForm.taxCodePattern.hasMatch(_taxCode.text.trim());

  Future<void> _addDocuments() async {
    try {
      final paths = await (widget.picker ?? MediaPickerService()).pickImages(
        source: MediaSource.gallery,
        limit: MyShopVerificationForm.maxDocuments - _documents.length,
      );
      for (final path in paths) {
        final bytes = await XFile(path).readAsBytes();
        if (!mounted ||
            _documents.length >= MyShopVerificationForm.maxDocuments) {
          break;
        }
        setState(() => _documents.add(bytes));
      }
    } on PlatformException {
      // người dùng từ chối quyền truy cập ảnh: giữ nguyên
    }
  }

  Future<void> _submit() async {
    setState(() => _showErrors = true);
    if (!_nameValid || !_taxCodeValid || _documents.isEmpty) return;
    final sent = await widget.onSubmit(
      _name.text.trim(),
      _taxCode.text.trim(),
      List.of(_documents),
    );
    if (sent && mounted) {
      setState(() {
        _documents.clear();
        _showErrors = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return MyShopSection(
      key: const ValueKey('my-shop-verify'),
      title: l.msVerifySection,
      subtitle: l.msVerifyBody,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppLabeledTextField(
            key: const ValueKey('my-shop-verify-name'),
            label: l.msVerifyBusinessName,
            isRequired: true,
            controller: _name,
            maxLength: 120,
            hintText: l.msVerifyBusinessNameHint,
            errorText: _showErrors && !_nameValid
                ? l.msVerifyBusinessNameInvalid
                : null,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          AppLabeledTextField(
            key: const ValueKey('my-shop-verify-tax'),
            label: l.msVerifyTaxCode,
            isRequired: true,
            controller: _taxCode,
            maxLength: 14,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d-]')),
            ],
            hintText: l.msVerifyTaxCodeHint,
            errorText: _showErrors && !_taxCodeValid
                ? l.msVerifyTaxCodeInvalid
                : null,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          Text(
            l.msVerifyDocs,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l.msVerifyDocsHint,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (index, bytes) in _documents.indexed)
                _DocumentThumb(
                  bytes: bytes,
                  onRemove: () => setState(() => _documents.removeAt(index)),
                ),
              if (_documents.length < MyShopVerificationForm.maxDocuments)
                _AddDocument(
                  label: l.msVerifyAddDoc,
                  onTap: widget.saving ? null : _addDocuments,
                ),
            ],
          ),
          if (_showErrors && _documents.isEmpty) ...[
            const SizedBox(height: 6),
            Text(
              l.msVerifyDocsRequired,
              style: const TextStyle(fontSize: 12.5, color: AppColors.error),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const ValueKey('my-shop-verify-submit'),
            onPressed: widget.saving ? null : _submit,
            icon: const Icon(AppIcons.shield, size: 18),
            label: Text(l.msVerifySubmit),
          ),
        ],
      ),
    );
  }
}

class _DocumentThumb extends StatelessWidget {
  const _DocumentThumb({required this.bytes, required this.onRemove});

  final Uint8List bytes;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 84,
    height: 84,
    child: Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(bytes, fit: BoxFit.cover, cacheWidth: 240),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: IconButton.filledTonal(
            tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
            visualDensity: VisualDensity.compact,
            iconSize: 14,
            onPressed: onRemove,
            icon: const Icon(AppIcons.close),
          ),
        ),
      ],
    ),
  );
}

class _AddDocument extends StatelessWidget {
  const _AddDocument({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      key: const ValueKey('my-shop-verify-add'),
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              AppIcons.addPhoto,
              size: 22,
              color: AppColors.primaryDark,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
