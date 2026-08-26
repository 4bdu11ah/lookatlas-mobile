import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// App-wide text input styled by [ThemeData.inputDecorationTheme].
class AppTextField extends StatefulWidget {
  const AppTextField({
    this.controller,
    this.focusNode,
    this.fieldKey,
    this.labelText,
    this.hintText,
    this.helperText,
    this.onChanged,
    this.onFieldSubmitted,
    this.validator,
    this.autovalidateMode,
    this.autofillHints,
    this.keyboardType,
    this.textCapitalization,
    this.textInputAction,
    this.autofocus = false,
    this.obscureText = false,
    this.expands = false,
    this.textStyle,
    this.hintStyle,
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: 14,
      vertical: 14,
    ),
    this.leading,
    this.trailing,
    this.height = singleLineHeight,
    this.minLines = 1,
    this.maxLines = 1,
    this.maxLength,
    this.maxLengthEnforcement = MaxLengthEnforcement.enforced,
    this.showCounter = true,
    super.key,
  }) : assert(
         minLines == null || minLines > 0,
         'minLines must be greater than zero.',
       ),
       assert(
         minLines == null || maxLines == null || maxLines >= minLines,
         'maxLines cannot be less than minLines.',
       ),
       assert(
         !expands || (minLines == null && maxLines == null),
         'Expanding fields require null minLines and maxLines.',
       ),
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
  final FocusNode? focusNode;
  final Key? fieldKey;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final FormFieldValidator<String>? validator;
  final AutovalidateMode? autovalidateMode;
  final Iterable<String>? autofillHints;
  final TextInputType? keyboardType;
  final TextCapitalization? textCapitalization;
  final TextInputAction? textInputAction;
  final bool autofocus;
  final bool obscureText;
  final bool expands;
  final TextStyle? textStyle;
  final TextStyle? hintStyle;
  final EdgeInsetsGeometry contentPadding;
  final Widget? leading;
  final Widget? trailing;
  final double height;
  final int? minLines;
  final int? maxLines;
  final int? maxLength;
  final MaxLengthEnforcement maxLengthEnforcement;
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
    final field =
        widget.maxLines != 1 || widget.validator != null || widget.expands
        ? textField
        : SizedBox(height: widget.height, child: textField);
    if (widget.helperText == null &&
        (widget.maxLength == null || !widget.showCounter)) {
      return field;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        field,
        if (widget.helperText != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.helperText!,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (widget.maxLength != null && widget.showCounter) ...[
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
      ],
    );
  }

  TextFormField _buildTextField() {
    final isMultiline = widget.maxLines != 1;
    return TextFormField(
      key: widget.fieldKey,
      controller: _controller,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onFieldSubmitted,
      validator: widget.validator,
      autovalidateMode: widget.autovalidateMode,
      autofillHints: widget.autofillHints,
      obscureText: widget.obscureText,
      expands: widget.expands,
      textAlignVertical: isMultiline
          ? TextAlignVertical.top
          : TextAlignVertical.center,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      maxLength: widget.maxLength,
      maxLengthEnforcement: widget.maxLengthEnforcement,
      keyboardType:
          widget.keyboardType ??
          (isMultiline ? TextInputType.multiline : TextInputType.text),
      textCapitalization:
          widget.textCapitalization ??
          (widget.keyboardType == TextInputType.emailAddress ||
                  widget.obscureText
              ? TextCapitalization.none
              : TextCapitalization.sentences),
      textInputAction:
          widget.textInputAction ??
          (isMultiline ? TextInputAction.newline : TextInputAction.done),
      style:
          widget.textStyle ??
          Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle:
            widget.hintStyle ??
            Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
        isDense: true,
        contentPadding: widget.contentPadding,
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
