import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/features/subscription/di/subscription_access_providers.dart';
import 'package:look_atlas/features/subscription/presentation/controllers/subscription_controller.dart';

bool requestProductsManageAccess(BuildContext context, WidgetRef ref) {
  final hasAccess =
      ref.read(isPremiumProvider) ||
      (ref
              .read(subscriptionControllerProvider)
              .value
              ?.activeEntitlements
              .contains('products_manage') ??
          false);
  if (hasAccess) return true;
  unawaited(context.push(AppRoutes.paywall));
  return false;
}
