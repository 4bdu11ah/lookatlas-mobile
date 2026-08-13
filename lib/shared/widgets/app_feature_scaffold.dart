import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:look_atlas/core/layout/app_responsive.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/shared/widgets/custom_app_bar.dart';

class AppFeatureScaffold extends StatelessWidget {
  const AppFeatureScaffold({
    required this.title,
    required this.child,
    this.backgroundColor = AppColors.white,
    this.contentBackgroundColor,
    this.maxContentWidth,
    this.useResponsiveContent = true,
    this.onBack,
    this.actions = const [],
    this.floatingActionButton,
    super.key,
  });

  final String title;
  final Widget child;
  final Color backgroundColor;
  final Color? contentBackgroundColor;
  final double? maxContentWidth;
  final bool useResponsiveContent;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final content = contentBackgroundColor == null
        ? child
        : ColoredBox(color: contentBackgroundColor!, child: child);
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: CustomAppBar(
        title: title,
        showBackButton: true,
        onBack: onBack ?? () => _goBack(context),
        actions: actions,
      ),
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        bottom: false,
        child: useResponsiveContent
            ? ResponsiveContent(maxWidth: maxContentWidth, child: content)
            : content,
      ),
    );
  }

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(AppRoutes.home);
  }
}
