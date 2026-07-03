import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// The app-wide page transition: a quick fade with a subtle upward drift.
///
/// One understated motion for every navigation keeps the app feeling calm and
/// consistent with the monochrome design system — no full-width slides or
/// zooms. The reverse (pop) plays the same motion backwards, slightly faster.
CustomTransitionPage<T> buildAppTransitionPage<T>({
  required GoRouterState state,
  required Widget child,
}) => CustomTransitionPage<T>(
  key: state.pageKey,
  // Mirrors go_router's default page settings so the analytics route
  // observer keeps reporting screen views.
  name: state.name ?? state.uri.toString(),
  child: child,
  transitionDuration: const Duration(milliseconds: 280),
  reverseTransitionDuration: const Duration(milliseconds: 220),
  transitionsBuilder: (context, animation, secondaryAnimation, child) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.02),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  },
);
