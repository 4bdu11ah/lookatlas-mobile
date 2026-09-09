part of '../shoots_feature.dart';

Future<void> _openShootModal(
  BuildContext context,
  WidgetRef ref,
  _ShootModalKind kind,
) {
  if (kind == _ShootModalKind.editAi) {
    return _showAiEditDialog(
      context,
      onToast: (text) => AppSnackBar.show(context, text),
    );
  }
  if (kind == _ShootModalKind.directorPortfolio) {
    final createState = ref.read(_createShootControllerProvider);
    final shootDirector = _selectedShootDirector(ref);
    final director = _onboardingDirectorFor(shootDirector);
    if (director != null) {
      final selected = createState.demoMode
          ? createState.demoDirectors.any(
              (config) => config.directorId == shootDirector?.id,
            )
          : createState.selectedDirector == createState.previewDirector;
      return showDirectorPortfolio(
        context,
        director: director,
        isSelected: selected,
        onSelect: () {
          final controller = ref.read(_createShootControllerProvider.notifier);
          if (createState.demoMode) {
            controller.toggleDemoDirector(createState.previewDirector);
          } else {
            controller.selectDirector(createState.previewDirector);
          }
        },
      );
    }
  }
  return showAppDialog<void>(
    context: context,
    builder: (_) => _ShootDialog(
      kind: kind,
      onOpenBilling: () => unawaited(
        context.push<void>(AppRoutes.dashboardBilling),
      ),
      onOpenModal: (nextKind) => _openShootModal(context, ref, nextKind),
      onToast: (text) => AppSnackBar.show(context, text),
    ),
  );
}

Director? _onboardingDirectorFor(ShootLook? shootDirector) {
  if (shootDirector == null) return null;
  for (final director in directors) {
    if (director.apiId == shootDirector.id ||
        director.id == shootDirector.id ||
        director.name == shootDirector.name) {
      return director;
    }
  }
  return null;
}
