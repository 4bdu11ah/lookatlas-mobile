import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/features/subscription/presentation/controllers/subscription_controller.dart';

final isPremiumProvider = Provider<bool>(
  (ref) => ref.watch(subscriptionControllerProvider).value?.isPremium ?? false,
);
