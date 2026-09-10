import 'package:flutter/material.dart';

enum GuideTab {
  gettingStarted('Getting Started', Icons.rocket_launch_outlined),
  productPhotos('Product Photos', Icons.camera_alt_outlined),
  models('Models', Icons.groups_outlined),
  shoots('Shoots', Icons.play_arrow_outlined);

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
