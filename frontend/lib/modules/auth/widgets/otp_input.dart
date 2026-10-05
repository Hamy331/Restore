import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';

class OtpInput extends StatefulWidget {
  const OtpInput({this.onChanged, super.key});
  final ValueChanged<String>? onChanged;

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = ((constraints.maxWidth - 50) / 6).clamp(40.0, 48.0);
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) {
            return SizedBox(
              width: boxWidth,
              height: 52,
              child: TextField(
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                autofillHints: index == 0
                    ? const [AutofillHints.oneTimeCode]
                    : null,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    if (newValue.text.length > 1) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) _fillFrom(index, newValue.text);
                      });
                      return oldValue;
                    }
                    return newValue;
                  }),
                ],
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.zero,
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty && index < 5) {
                    _focusNodes[index + 1].requestFocus();
                  } else if (value.isEmpty && index > 0) {
                    _focusNodes[index - 1].requestFocus();
                  }
                  widget.onChanged?.call(
                    _controllers.map((item) => item.text).join(),
                  );
                },
              ),
            );
          }),
        );
      },
    );
  }

  void _fillFrom(int startIndex, String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return;
    for (
      var offset = 0;
      offset < digits.length && startIndex + offset < _controllers.length;
      offset++
    ) {
      _controllers[startIndex + offset].text = digits[offset];
    }
    final nextIndex = (startIndex + digits.length).clamp(0, 5);
    _focusNodes[nextIndex].requestFocus();
    widget.onChanged?.call(_controllers.map((item) => item.text).join());
  }
}
