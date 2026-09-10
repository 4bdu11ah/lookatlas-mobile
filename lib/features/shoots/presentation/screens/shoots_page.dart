library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/features/shoots/presentation/controllers/shoots_controller.dart';
import 'package:look_atlas/features/shoots/presentation/dialogs/shoot_modal.dart';
import 'package:look_atlas/features/shoots/presentation/models/shoot_modal_kind.dart';
import 'package:look_atlas/features/shoots/presentation/models/shoot_view_model.dart';
import 'package:look_atlas/features/subscription/di/subscription_access_providers.dart';
import 'package:look_atlas/shared/widgets/app_asset_image.dart';
import 'package:look_atlas/shared/widgets/app_bottom_sheet.dart';
import 'package:look_atlas/shared/widgets/app_card.dart';
import 'package:look_atlas/shared/widgets/app_feature_scaffold.dart';
import 'package:look_atlas/shared/widgets/app_feedback.dart';
import 'package:look_atlas/shared/widgets/app_floating_action_button.dart';
import 'package:look_atlas/shared/widgets/app_media_widgets.dart';
import 'package:look_atlas/shared/widgets/app_outlined_button.dart';
import 'package:look_atlas/shared/widgets/app_sheet_frame.dart';
import 'package:look_atlas/shared/widgets/app_spaced_column.dart';
import 'package:look_atlas/shared/widgets/app_text.dart';
import 'package:look_atlas/shared/widgets/app_text_field.dart';
import 'package:look_atlas/shared/widgets/primary_button.dart';
import 'package:look_atlas/shared/widgets/shimmer_box.dart';

part '../widgets/shoot_cards.dart';
part '../widgets/shoot_loading.dart';

typedef _ShootModalKind = ShootModalKind;

class ShootsScreen extends ConsumerWidget {
  const ShootsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);
    return AppFeatureScaffold(
      title: 'Shoots',
      backgroundColor: AppColors.neutral50,
      useResponsiveContent: false,
      floatingActionButton: AppFloatingActionButton(
        key: const ValueKey('new-shoot-button'),
        label: 'New Shoot',
        icon: Icons.play_arrow_outlined,
        onPressed: !isPremium
            ? () => _openCreateShoot(context)
            : () => openShootModal(
                context,
                ref,
                _ShootModalKind.contextPaywall,
              ),
      ),
      child: RefreshIndicator(
        onRefresh: () => ref.read(shootsControllerProvider.notifier).load(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          child: _JobsPage(
            onOpenModal: (kind) => openShootModal(context, ref, kind),
          ),
        ),
      ),
    );
  }
}

class _JobsPage extends ConsumerWidget {
  const _JobsPage({required this.onOpenModal});

  final ValueChanged<_ShootModalKind> onOpenModal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(shootsControllerProvider);
    final controller = ref.read(shootsControllerProvider.notifier);
    final isPremium = ref.watch(isPremiumProvider);
    final shoots = state.shoots;
    if (state.isLoading) {
      return const _ShootsLoading();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppBodyText(
          'Monitor your photo shoots and generation progress.',
        ),
        const SizedBox(height: 16),
        _ShootFilters(
          query: state.query,
          status: state.status,
          shootCount: shoots.length,
          onQueryChanged: controller.setQuery,
          onStatusChanged: controller.setStatus,
        ),
        if (state.failure != null && shoots.isEmpty)
          AppCard(
            child: AppSpacedColumn(
              gap: 12,
              children: [
                Text(state.failure!.message),
                AppOutlinedButton(
                  label: 'Try again',
                  icon: Icons.refresh,
                  onPressed: () => unawaited(controller.load()),
                ),
              ],
            ),
          )
        else if (shoots.isEmpty)
          AppEmptyState(
            title: state.query.isEmpty && state.status == 'all'
                ? 'No shoots yet'
                : 'No shoots found',
            body: state.query.isEmpty && state.status == 'all'
                ? 'Create your first shoot to start generating on-model images.'
                : 'Try a different search or status filter.',
            buttonLabel: state.query.isEmpty && state.status == 'all'
                ? 'Create Shoot'
                : 'Clear filters',
            onTap: state.query.isEmpty && state.status == 'all'
                ? () => isPremium
                      ? _openCreateShoot(context)
                      : onOpenModal(_ShootModalKind.contextPaywall)
                : () {
                    controller
                      ..setQuery('')
                      ..setStatus('all');
                  },
          )
        else ...[
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: shoots.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final shoot = shoots[index];
              return _ShootCard(
                shoot: shoot,
                onTap: () {
                  unawaited(
                    context.push<void>(AppRoutes.shootDetail(shoot.id)),
                  );
                },
              );
            },
          ),
          if (state.totalPages > 1)
            Row(
              children: [
                Expanded(
                  child: AppOutlinedButton(
                    label: 'Previous',
                    icon: Icons.chevron_left,
                    onPressed: state.page > 1
                        ? () => controller.setPage(state.page - 1)
                        : null,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('${state.page} of ${state.totalPages}'),
                ),
                Expanded(
                  child: AppOutlinedButton(
                    label: 'Next',
                    icon: Icons.chevron_right,
                    iconAlignment: IconAlignment.end,
                    onPressed: state.page < state.totalPages
                        ? () => controller.setPage(state.page + 1)
                        : null,
                  ),
                ),
              ],
            ),
        ],
      ],
    );
  }
}

void _openCreateShoot(BuildContext context) {
  unawaited(context.push<void>(AppRoutes.createShoot));
}
