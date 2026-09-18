import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/layout/app_responsive.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/features/auth/presentation/controllers/auth_controller.dart';
import 'package:look_atlas/features/auth/presentation/controllers/sign_up_ui_controller.dart';
import 'package:look_atlas/features/auth/presentation/widgets/sign_up_before_after_header.dart';
import 'package:look_atlas/features/auth/presentation/widgets/sign_up_form_card.dart';
import 'package:look_atlas/features/auth/presentation/widgets/sign_up_testimonials.dart';
import 'package:look_atlas/shared/widgets/app_snack_bar.dart';

/// Sign Up Screen - Variant 8.
///
/// Features an interactive before/after split slider hero, thumbnail switcher,
/// pixel-perfect signup form card with Google & Apple authentication, and
/// horizontal customer testimonials.
///
/// Top status bar behavior:
/// - Initially at top: image starts below safe area top, with solid dark status bar.
/// - When scrolled: content scrolls under status bar with frosted glass blur,
///   transitioning smoothly to dark icons when the white card reaches top.
///
/// State management strictly powered by Riverpod without setState.
class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final captchaToken = ref.read(signUpTurnstileTokenProvider);
    if (captchaToken == null || captchaToken.isEmpty) {
      AppSnackBar.showError(
        context,
        'Complete the security check before continuing.',
      );
      return;
    }

    try {
      await ref
          .read(authControllerProvider.notifier)
          .signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            companyName: _nameController.text.trim(),
            captchaToken: captchaToken,
          );
    } finally {
      ref.read(signUpTurnstileTokenProvider.notifier).clear();
      ref.read(signUpCaptchaGenerationProvider.notifier).increment();
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

    final isScrolled = ref.watch(signUpIsScrolledProvider);
    final isScrolledUnder = ref.watch(signUpScrolledUnderProvider);
    final topPadding = MediaQuery.paddingOf(context).top;
    final isWide = AppResponsive.isWide(context);

    final overlayStyle = isScrolledUnder
        ? SystemUiOverlayStyle.dark.copyWith(
            statusBarColor: AppColors.transparent,
          )
        : SystemUiOverlayStyle.light.copyWith(
            statusBarColor: AppColors.transparent,
          );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: AppColors.darkSurface,
        body: isWide
            ? _buildWideLayout(context, topPadding)
            : _buildCompactLayout(
                context,
                topPadding,
                isScrolled,
                isScrolledUnder,
              ),
      ),
    );
  }

  Widget _buildWideLayout(BuildContext context, double topPadding) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: 24,
          vertical: topPadding > 0 ? topPadding + 16 : 32,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppResponsive.tabletLayoutMaxWidth,
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left Column: Before/After hero & Testimonials (Variant 5)
                const Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: SignUpBeforeAfterHeader(
                          height: null,
                          margin: EdgeInsets.zero,
                        ),
                      ),
                      SizedBox(height: 10),
                      SignUpTestimonials(
                        padding: EdgeInsets.zero,
                        isColumn: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Right Column: Form Card (Variant 5)
                Expanded(
                  flex: 5,
                  child: SignUpFormCard(
                    formKey: _formKey,
                    nameController: _nameController,
                    emailController: _emailController,
                    passwordController: _passwordController,
                    onSubmit: _submit,
                    margin: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactLayout(
    BuildContext context,
    double topPadding,
    bool isScrolled,
    bool isScrolledUnder,
  ) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // Only react to vertical scrolling of the main compact scroll view
        if (notification.metrics.axis != Axis.vertical ||
            notification.depth != 0) {
          return false;
        }

        final pixels = notification.metrics.pixels;
        final hasScrolled = pixels > 2.0;

        // Determine if the white form card is currently passing under the status bar
        var isUnder = false;
        final formBox =
            _formKey.currentContext?.findRenderObject() as RenderBox?;
        if (formBox != null && formBox.hasSize) {
          final formTop = formBox.localToGlobal(Offset.zero).dy;
          final formBottom = formTop + formBox.size.height;
          isUnder = formTop <= topPadding && formBottom > 0;
        } else {
          isUnder = pixels >= 330.0 && pixels < 1600.0;
        }

        ref
            .read(signUpIsScrolledProvider.notifier)
            .setScrolled(isScrolled: hasScrolled);
        ref
            .read(signUpScrolledUnderProvider.notifier)
            .setScrolled(isScrolled: isUnder);
        return false;
      },
      child: Stack(
        children: [
          // Scrollable content starting at topPadding
          SingleChildScrollView(
            padding: EdgeInsets.only(top: topPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SignUpBeforeAfterHeader(),
                const SizedBox(height: 10),
                SignUpFormCard(
                  formKey: _formKey,
                  nameController: _nameController,
                  emailController: _emailController,
                  passwordController: _passwordController,
                  onSubmit: _submit,
                ),
                const SizedBox(height: 10),
                const SignUpTestimonials(),
                const SizedBox(height: 24),
              ],
            ),
          ),
          // Status bar overlay: solid black at top, frosted blur on scroll
          if (topPadding > 0)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: topPadding,
              child: isScrolled
                  ? ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: ColoredBox(
                          color: isScrolledUnder
                              ? AppColors.surfaceOffWhite.withValues(
                                  alpha: 0.85,
                                )
                              : AppColors.darkSurface.withValues(
                                  alpha: 0.8,
                                ),
                        ),
                      ),
                    )
                  : const ColoredBox(
                      color: AppColors.darkSurface,
                    ),
            ),
        ],
      ),
    );
  }
}
