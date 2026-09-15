import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum GuideTab {
  gettingStarted('Getting Started', LucideIcons.rocket),
  productPhotos('Product Photos', LucideIcons.camera),
  models('Models', LucideIcons.users),
  shoots('Shoots', LucideIcons.play);

  const GuideTab(this.label, this.icon);

  final String label;
  final IconData icon;
}

GuideTab? guideTabFromId(String? id) => switch (id) {
  'getting-started' => GuideTab.gettingStarted,
  'product-photos' => GuideTab.productPhotos,
  'models' => GuideTab.models,
  'jobs' => GuideTab.shoots,
  _ => null,
};

class GuidesScreenState {
  const GuidesScreenState({required this.selectedTab});

  final GuideTab selectedTab;
}

const guidesInitialState = GuidesScreenState(
  selectedTab: GuideTab.gettingStarted,
);
