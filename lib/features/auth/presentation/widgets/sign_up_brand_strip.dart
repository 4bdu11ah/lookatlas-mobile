import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/core/theme/app_typography.dart';

/// Social proof statistics, client brand logos, and sign-in footer.
class SignUpBrandStrip extends StatelessWidget {
  const SignUpBrandStrip({
    super.key,
    this.promptText = 'Already have an account? ',
    this.actionText = 'Sign In',
    this.onActionTap,
  });

  final String promptText;
  final String actionText;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Stats
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '2000+ brands',
                style: AppTypography.sfPro(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '·',
                  style: AppTypography.sfPro(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Text(
                '1M photos generated',
                style: AppTypography.sfPro(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Brand logos
        const _BrandsRow(),
        const SizedBox(height: 32),
        // Action / Redirect link
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                promptText,
                style: AppTypography.sfPro(
                  fontSize: 14,
                  color: AppColors.textMuted,
                ),
              ),
              GestureDetector(
                onTap:
                    onActionTap ??
                    () => context.canPop()
                        ? context.pop()
                        : context.go(AppRoutes.signIn),
                child: Text(
                  actionText,
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
        const SizedBox(height: 12),
        // Terms line
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            Text(
              'By signing up, you agree to our ',
              style: AppTypography.sfPro(
                fontSize: 13,
                color: AppColors.textTertiary,
              ),
            ),
            GestureDetector(
              onTap: () {},
              child: Text(
                'Terms of Services',
                style: AppTypography.sfPro(
                  fontSize: 13,
                  decoration: TextDecoration.underline,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
            Text(
              ' and ',
              style: AppTypography.sfPro(
                fontSize: 13,
                color: AppColors.textTertiary,
              ),
            ),
            GestureDetector(
              onTap: () {},
              child: Text(
                'Privacy Policy',
                style: AppTypography.sfPro(
                  fontSize: 13,
                  decoration: TextDecoration.underline,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BrandsRow extends StatelessWidget {
  const _BrandsRow();

  @override
  Widget build(BuildContext context) {
    return const FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'BURGA',
            style: TextStyle(
              fontFamily: AppTypography.sekuyaFontFamily,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(width: 24),
          Text(
            'NOOKLA',
            style: TextStyle(
              fontFamily: AppTypography.rethinkSansFontFamily,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: AppColors.darkSurface,
            ),
          ),
          SizedBox(width: 24),
          Text(
            'GOODFAIR',
            style: TextStyle(
              fontFamily: AppTypography.qahiriFontFamily,
              fontSize: 20,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(width: 24),
          Text(
            'APOLLO',
            style: TextStyle(
              fontFamily: AppTypography.redRoseFontFamily,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: AppColors.darkSurface,
            ),
          ),
        ],
      ),
    );
  }
}
