import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:look_atlas/core/constants/app_assets.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/layout/app_responsive.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/core/theme/app_typography.dart';
import 'package:look_atlas/features/auth/domain/validators/auth_validators.dart';
import 'package:look_atlas/features/auth/presentation/controllers/auth_controller.dart';
import 'package:look_atlas/shared/widgets/app_image.dart';
import 'package:look_atlas/shared/widgets/app_snack_bar.dart';
import 'package:look_atlas/shared/widgets/custom_app_bar.dart';

/// Forgot-password screen: collects the account email and submits a reset
/// request through [AuthController.resetPassword].
/// Matches LookAtlas design system with dark background and centered off-white card,
/// without the hero header or testimonials footer.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final succeeded = await ref
        .read(authControllerProvider.notifier)
        .resetPassword(_emailController.text.trim());
    if (!mounted || !succeeded) return;

    AppSnackBar.showSuccess(
      context,
      'Check your email for a link to reset your password.',
    );
    _navigateBack();
  }

  void _navigateBack() {
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      if (router.canPop()) {
        router.pop();
      } else {
        router.go(AppRoutes.signIn);
      }
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (_, next) {
      if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;
      if (next case AsyncError(:final error)) {
        final message = error is Failure
            ? error.message
            : 'Something went wrong.';
        AppSnackBar.showError(context, message);
      }
    });

    final isLoading = ref.watch(
      authControllerProvider.select((s) => s.isLoading),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: AppColors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.surfaceOffWhite,
        appBar: CustomAppBar(
          showBackButton: true,
          onBack: _navigateBack,
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppResponsive.formMaxWidth,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderLight),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // App Logo
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: 55,
                            height: 55,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: const AppImage(
                              AppAssets.logo,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Title
                        Text(
                          'Reset your password',
                          style: AppTypography.sfPro(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                            color: AppColors.darkSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Subtitle
                        Text(
                          "Enter your email and we'll send you a reset link",
                          style: AppTypography.sfPro(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 28),
                        // Email Field
                        Text(
                          'Email address',
                          style: AppTypography.sfPro(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _emailController,
                          style: AppTypography.sfPro(
                            fontSize: 15,
                            color: AppColors.darkSurface,
                          ),
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          validator: AuthValidators.validateEmail,
                          decoration: _inputDecoration('you@company.com'),
                        ),
                        const SizedBox(height: 24),
                        // Primary Action Button
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            backgroundColor: AppColors.black,
                            foregroundColor: AppColors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            elevation: 0,
                          ),
                          onPressed: isLoading ? null : _submit,
                          child: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Send reset link',
                                        style: TextStyle(
                                          fontFamily: 'SF Pro Display',
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.white,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(
                                        Icons.arrow_forward,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                        const SizedBox(height: 28),
                        // Back to sign in link
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Remember your password? ',
                                style: AppTypography.sfPro(
                                  fontSize: 14,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              GestureDetector(
                                onTap: _navigateBack,
                                child: Text(
                                  'Sign in',
                                  style: AppTypography.sfPro(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.darkSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTypography.sfPro(
        fontSize: 15,
        color: AppColors.textPlaceholder,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: AppColors.surfaceOffWhite,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: AppColors.darkSurface, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }
}
