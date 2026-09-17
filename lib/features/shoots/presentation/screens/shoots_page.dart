library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/features/shoots/domain/entities/shoot_draft.dart';
import 'package:look_atlas/features/shoots/presentation/controllers/shoot_draft_controller.dart';
import 'package:look_atlas/features/shoots/presentation/controllers/shoots_controller.dart';
import 'package:look_atlas/features/shoots/presentation/dialogs/shoot_modal.dart';
import 'package:look_atlas/features/shoots/presentation/models/shoot_modal_kind.dart';
import 'package:look_atlas/features/shoots/presentation/models/shoot_view_model.dart';
import 'package:look_atlas/features/subscription/di/subscription_access_providers.dart';
import 'package:look_atlas/shared/widgets/app_card.dart';
import 'package:look_atlas/shared/widgets/app_dialog.dart';
import 'package:look_atlas/shared/widgets/app_feature_scaffold.dart';
import 'package:look_atlas/shared/widgets/app_feedback.dart';
import 'package:look_atlas/shared/widgets/app_image.dart';
import 'package:look_atlas/shared/widgets/app_outlined_button.dart';
import 'package:look_atlas/shared/widgets/app_snack_bar.dart';
import 'package:look_atlas/shared/widgets/app_spaced_column.dart';
import 'package:look_atlas/shared/widgets/app_text_field.dart';
import 'package:look_atlas/shared/widgets/primary_button.dart';
import 'package:look_atlas/shared/widgets/shimmer_box.dart';

part '../widgets/shoot_cards.dart';
part '../widgets/shoot_search_widgets.dart';
part '../widgets/shoot_loading.dart';

typedef _ShootModalKind = ShootModalKind;

class ShootsScreen extends ConsumerStatefulWidget {
  const ShootsScreen({super.key});

  @override
  ConsumerState<ShootsScreen> createState() => _ShootsScreenState();
}

class _ShootsScreenState extends ConsumerState<ShootsScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ref
        .read(shootsControllerProvider.notifier)
        .setVisible(isVisible: state == AppLifecycleState.resumed);
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(isPremiumProvider);
    return AppFeatureScaffold(
      title: 'Shoots',
      backgroundColor: const Color(0xFFFFFEFA),
      useResponsiveContent: false,
      child: RefreshIndicator(
        onRefresh: () => Future.wait([
          ref.read(shootsControllerProvider.notifier).load(),
          ref.read(shootDraftProvider.notifier).load(),
        ]),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 40),
          child: _JobsPage(
            isPremium: isPremium,
            onOpenModal: (kind) => openShootModal(context, ref, kind),
          ),
        ),
      ),
    );
  }
}

class _JobsPage extends ConsumerWidget {
  const _JobsPage({required this.isPremium, required this.onOpenModal});

  final bool isPremium;
  final ValueChanged<_ShootModalKind> onOpenModal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(shootsControllerProvider);
    final controller = ref.read(shootsControllerProvider.notifier);
    final drafts = ref.watch(
      shootDraftProvider.select((state) => state.drafts),
    );
    final shoots = state.shoots;
    if (state.isLoading) {
      return const _ShootsLoading();
    }
    final ready = shoots.where((shoot) => shoot.isReady).toList();
    final active = shoots.where((shoot) => shoot.isActive).toList();
    final archive = shoots.where((shoot) {
      if (!shoot.isArchived) return false;
      return switch (state.status) {
        'completed' => !shoot.needsAttention,
        'attention' => shoot.needsAttention,
        _ => true,
      };
    }).toList();
    void openShoot(ShootViewModel shoot) {
      unawaited(context.push<void>(AppRoutes.shootDetail(shoot.id)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _OverviewHeader(),
        const SizedBox(height: 14),
        PrimaryButton(
          key: const ValueKey('new-shoot-button'),
          label: 'Create a shoot',
          icon: Icons.add,
          foregroundColor: AppColors.white,
          onPressed: isPremium
              ? () => _openCreateShoot(context)
              : () => onOpenModal(_ShootModalKind.contextPaywall),
        ),
        const SizedBox(height: 28),
        if (drafts.isNotEmpty) ...[
          _ShootDraftSection(
            drafts: drafts,
            onOpen: (draft) => _openCreateShoot(context, draftId: draft.id),
            onDelete: (draft) => _deleteDraft(context, ref, draft.id),
          ),
          const SizedBox(height: 28),
        ],
        _ShootSearchField(
          query: state.query,
          onChanged: controller.setQuery,
        ),
        const SizedBox(height: 28),
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
          if (ready.isNotEmpty) ...[
            _OverviewSectionHeader(
              index: '01',
              eyebrow: 'Ready for you',
              title: 'Finished and waiting for review.',
              count: '${ready.length.toString().padLeft(2, '0')} unread',
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: ready.length,
              separatorBuilder: (_, _) => const SizedBox(height: 16),
              itemBuilder: (_, index) => _ReadyShootCard(
                shoot: ready[index],
                onTap: () => openShoot(ready[index]),
              ),
            ),
            const SizedBox(height: 28),
          ],
          if (active.isNotEmpty) ...[
            _OverviewSectionHeader(
              index: '02',
              eyebrow: 'On the studio floor',
              title: 'In production now.',
              count: '${active.length.toString().padLeft(2, '0')} active',
            ),
            _ActiveShootList(shoots: active, onTap: openShoot),
            const SizedBox(height: 28),
          ],
          _OverviewSectionHeader(
            index: '03',
            eyebrow: 'Your archive',
            title: 'Every finished collection.',
            count: '${archive.length.toString().padLeft(2, '0')} total',
          ),
          _ArchiveFilterTabs(
            selected: state.status,
            onSelected: controller.setStatus,
          ),
          const SizedBox(height: 14),
          if (archive.isEmpty)
            const _ArchiveEmptyState()
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: archive.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 16,
                childAspectRatio: 0.58,
              ),
              itemBuilder: (_, index) => _ArchiveShootCard(
                index: index,
                shoot: archive[index],
                onTap: () => openShoot(archive[index]),
              ),
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

void _openCreateShoot(BuildContext context, {String? draftId}) {
  unawaited(
    context.push<void>(
      draftId == null
          ? AppRoutes.createShoot
          : AppRoutes.createShootDraft(draftId),
    ),
  );
}

Future<void> _deleteDraft(
  BuildContext context,
  WidgetRef ref,
  String draftId,
) async {
  final confirmed = await showAppDialog<bool>(
    context: context,
    title: 'Delete this draft?',
    subtitle: 'This cannot be undone.',
    builder: (_) => const Text(
      'Your saved shoot setup and selections will be permanently removed.',
    ),
    footer: Builder(
      builder: (dialogContext) => Row(
        children: [
          Expanded(
            child: AppOutlinedButton(
              label: 'Keep draft',
              onPressed: () => Navigator.pop(dialogContext, false),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: PrimaryButton(
              label: 'Delete draft',
              foregroundColor: AppColors.white,
              onPressed: () => Navigator.pop(dialogContext, true),
            ),
          ),
        ],
      ),
    ),
  );
  if (confirmed != true) return;
  final deleted = await ref.read(shootDraftProvider.notifier).delete(draftId);
  if (!deleted && context.mounted) {
    AppSnackBar.showError(context, 'Could not delete this draft.');
  }
}
