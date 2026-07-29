part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _JobsPage extends ConsumerWidget {
  const _JobsPage({required this.onOpenModal});

  final ValueChanged<_ModalKind> onOpenModal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_shootsControllerProvider);
    final controller = ref.read(_shootsControllerProvider.notifier);
    final isPremium = ref.watch(isPremiumProvider);
    final shoots = state.shoots;
    return _Stack(
      gap: 14,
      children: [
        const _PageHeader(
          title: 'Shoots',
          body: 'Monitor your photo shoots and generation progress.',
        ),
        PrimaryButton(
          key: const ValueKey('new-shoot-button'),
          label: 'New Shoot',
          icon: Icons.play_arrow_outlined,
          onPressed: isPremium
              ? () => _openCreateShoot(context)
              : () => onOpenModal(_ModalKind.contextPaywall),
        ),
        _ShootFilters(
          query: state.query,
          status: state.status,
          onQueryChanged: controller.setQuery,
          onStatusChanged: controller.setStatus,
        ),
        if (state.isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: BarSpinner()),
          )
        else if (state.failure != null && shoots.isEmpty)
          _Card(
            child: _Stack(
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
          _EmptyState(
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
                      : onOpenModal(_ModalKind.contextPaywall)
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
