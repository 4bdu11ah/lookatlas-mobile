part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _JobsPage extends ConsumerWidget {
  const _JobsPage({required this.onOpenModal});

  final ValueChanged<_ModalKind> onOpenModal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_shootsControllerProvider);
    final controller = ref.read(_shootsControllerProvider.notifier);
    final isPremium = ref.watch(isPremiumProvider);
    final shoots = state.visibleShoots;
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
          onPressed: !isPremium
              ? () => _openCreateShoot(context)
              : () => onOpenModal(_ModalKind.contextPaywall),
        ),
        _ShootFilters(
          query: state.query,
          status: state.status,
          onQueryChanged: controller.setQuery,
          onStatusChanged: controller.setStatus,
        ),
        if (shoots.isEmpty)
          _EmptyState(
            title: state.shoots.isEmpty ? 'No shoots yet' : 'No shoots found',
            body: state.shoots.isEmpty
                ? 'Create your first shoot to start generating on-model images.'
                : 'Try a different search or status filter.',
            buttonLabel: state.shoots.isEmpty
                ? 'Create Shoot'
                : 'Clear filters',
            onTap: state.shoots.isEmpty
                ? () => isPremium
                      ? _openCreateShoot(context)
                      : onOpenModal(_ModalKind.contextPaywall)
                : () {
                    controller
                      ..setQuery('')
                      ..setStatus('all');
                  },
          )
        else
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
                  controller.selectShoot(shoot);
                  unawaited(context.push<void>(AppRoutes.shootDetail));
                },
              );
            },
          ),
      ],
    );
  }
}

void _openCreateShoot(BuildContext context) {
  unawaited(context.push<void>(AppRoutes.createShoot));
}
