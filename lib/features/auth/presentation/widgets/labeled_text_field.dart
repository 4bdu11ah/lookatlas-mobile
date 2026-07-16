import 'package:flutter/material.dart';
import 'package:look_atlas/core/theme/app_typography.dart';

/// A labeled form field matching the mockup: a 14px medium label above the
/// input, an optional 12px muted helper line below, and a square-cornered,
/// white, bordered field with a 2px focus ring (from the input theme).
class LabeledTextField extends StatelessWidget {
  const LabeledTextField({
    required this.label,
    required this.controller,
    this.hintText,
    this.helperText,
    this.keyboardType,
    this.passwordVisibility,
    this.autofillHints,
    this.textInputAction,
    this.validator,
    this.onFieldSubmitted,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final String? hintText;
  final String? helperText;
  final TextInputType? keyboardType;
  final PasswordVisibilityConfig? passwordVisibility;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 14,
            fontWeight: AppTypography.medium,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText:
              passwordVisibility != null && !passwordVisibility!.isVisible,
          autofillHints: autofillHints,
          textInputAction: textInputAction,
          validator: validator,
          onFieldSubmitted: onFieldSubmitted,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            hintText: hintText,
            suffixIcon: switch (passwordVisibility) {
              final config? => IconButton(
                tooltip: config.isVisible ? 'Hide password' : 'Show password',
                onPressed: config.onToggle,
                icon: Icon(
                  config.isVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
              null => null,
            },
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 8),
          Text(
            helperText!,
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
          ),
        ],
      ],
    );
  }
}

class PasswordVisibilityConfig {
  const PasswordVisibilityConfig({
    required this.isVisible,
    required this.onToggle,
  });

  final bool isVisible;
  final VoidCallback onToggle;
}
