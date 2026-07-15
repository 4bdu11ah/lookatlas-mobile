import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// App-wide text input styled by [ThemeData.inputDecorationTheme].
class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.controller,
    this.fieldKey,
    this.hintText,
    this.onChanged,
    this.keyboardType,
    this.textInputAction,
    this.leading,
    this.trailing,
    this.height = singleLineHeight,
    this.minLines = 1,
    this.maxLines = 1,
    this.maxLength,
    this.showCounter = true,
    super.key,
  }) : assert(minLines > 0, 'minLines must be greater than zero.'),
       assert(maxLines >= minLines, 'maxLines cannot be less than minLines.'),
       assert(
         maxLength == null || maxLength > 0,
         'maxLength must be greater than zero.',
       ),
       assert(
         height > 0,
         'height must be greater than zero.',
       );

  static const double singleLineHeight = 55;

  final TextEditingController controller;
  final Key? fieldKey;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Widget? leading;
  final Widget? trailing;
  final double height;
  final int minLines;
  final int maxLines;
  final int? maxLength;
  final bool showCounter;

  @override
  Widget build(BuildContext context) {
    final isMultiline = maxLines > 1;
    final textField = TextField(
      key: fieldKey,
      controller: controller,
      onChanged: onChanged,
      textAlignVertical: isMultiline
          ? TextAlignVertical.top
          : TextAlignVertical.center,
      minLines: minLines,
      maxLines: maxLines,
      maxLength: maxLength,
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
      keyboardType:
          keyboardType ??
          (isMultiline ? TextInputType.multiline : TextInputType.text),
      textInputAction:
          textInputAction ??
          (isMultiline ? TextInputAction.newline : TextInputAction.done),
      style: const TextStyle(
        fontSize: 16,
        height: 1,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(fontSize: 14),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        prefixIcon: leading,
        prefixIconConstraints: leading == null
            ? null
            : const BoxConstraints(minWidth: 40),
        suffixIcon: trailing,
        suffixIconConstraints: trailing == null
            ? null
            : const BoxConstraints(minWidth: 40),
        counterText: maxLength == null ? null : '',
      ),
    );
    final field = isMultiline
        ? textField
        : SizedBox(height: height, child: textField);
    if (maxLength == null || !showCounter) return field;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        field,
        const SizedBox(height: 6),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (_, value, _) => Text(
            '${value.text.characters.length}/$maxLength',
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}
