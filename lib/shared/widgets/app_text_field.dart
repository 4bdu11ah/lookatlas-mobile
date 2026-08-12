import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// App-wide text input styled by [ThemeData.inputDecorationTheme].
class AppTextField extends StatefulWidget {
  const AppTextField({
    this.controller,
    this.fieldKey,
    this.labelText,
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

  final TextEditingController? controller;
  final Key? fieldKey;
  final String? labelText;
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
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  TextEditingController? _ownedController;

  TextEditingController get _controller =>
      widget.controller ?? _ownedController!;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _ownedController = TextEditingController();
    }
  }

  @override
  void didUpdateWidget(covariant AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    if (widget.controller == null) {
      _ownedController = TextEditingController(
        text: oldWidget.controller?.text,
      );
      return;
    }
    _ownedController?.dispose();
    _ownedController = null;
  }

  @override
  void dispose() {
    _ownedController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final field = _buildField(context);
    if (widget.labelText == null) return field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.labelText!,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        field,
      ],
    );
  }

  Widget _buildField(BuildContext context) {
    final textField = _buildTextField();
    final field = widget.maxLines > 1
        ? textField
        : SizedBox(height: widget.height, child: textField);
    if (widget.maxLength == null || !widget.showCounter) return field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        field,
        const SizedBox(height: 6),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _controller,
          builder: (_, value, _) => Text(
            '${value.text.characters.length}/${widget.maxLength}',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  TextField _buildTextField() {
    final isMultiline = widget.maxLines > 1;
    return TextField(
      key: widget.fieldKey,
      controller: _controller,
      onChanged: widget.onChanged,
      textAlignVertical: isMultiline
          ? TextAlignVertical.top
          : TextAlignVertical.center,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      maxLength: widget.maxLength,
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
      keyboardType:
          widget.keyboardType ??
          (isMultiline ? TextInputType.multiline : TextInputType.text),
      textInputAction:
          widget.textInputAction ??
          (isMultiline ? TextInputAction.newline : TextInputAction.done),
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        prefixIcon: widget.leading,
        prefixIconConstraints: widget.leading == null
            ? null
            : const BoxConstraints(minWidth: 40),
        suffixIcon: widget.trailing,
        suffixIconConstraints: widget.trailing == null
            ? null
            : const BoxConstraints(minWidth: 40),
        counterText: widget.maxLength == null ? null : '',
      ),
    );
  }
}
