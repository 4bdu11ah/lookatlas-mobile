part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

enum _GuideTab {
  gettingStarted('Getting Started', Icons.rocket_launch_outlined),
  productPhotos('Product Photos', Icons.camera_alt_outlined),
  models('Models', Icons.groups_outlined),
  shoots('Shoots', Icons.play_arrow_outlined);

  const _GuideTab(this.label, this.icon);

  final String label;
  final IconData icon;
}

_GuideTab? _guideTabFromId(String? id) => switch (id) {
  'getting-started' => _GuideTab.gettingStarted,
  'product-photos' => _GuideTab.productPhotos,
  'models' => _GuideTab.models,
  'jobs' => _GuideTab.shoots,
  _ => null,
};

class _GuidesScreenState {
  const _GuidesScreenState({required this.selectedTab});

  final _GuideTab selectedTab;
}
