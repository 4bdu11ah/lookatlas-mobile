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

class _GuidesScreenState {
  const _GuidesScreenState({required this.selectedTab});

  final _GuideTab selectedTab;
}
