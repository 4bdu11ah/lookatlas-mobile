import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/features/auth/presentation/password_visibility_controller.dart';
import 'package:look_atlas/features/auth/presentation/widgets/labeled_text_field.dart';

class AuthPasswordField extends ConsumerWidget {
  const AuthPasswordField({
    required this.controller,
    required this.hintText,
    required this.autofillHints,
    required this.visibilityProvider,
    required this.validator,
    this.helperText,
    this.onFieldSubmitted,
    super.key,
  });

  final TextEditingController controller;
  final String hintText;
  final Iterable<String> autofillHints;
  final NotifierProvider<PasswordVisibilityController, bool> visibilityProvider;
  final String? Function(String?) validator;
  final String? helperText;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVisible = ref.watch(visibilityProvider);

    return LabeledTextField(
      label: 'Password',
      controller: controller,
      hintText: hintText,
      helperText: helperText,
      passwordVisibility: PasswordVisibilityConfig(
        isVisible: isVisible,
        onToggle: ref.read(visibilityProvider.notifier).toggle,
      ),
      autofillHints: autofillHints,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
    );
  }
}
