import 'package:flutter/material.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum DashboardPage {
  dashboard('Dashboard', LucideIcons.layoutDashboard),
  workshop('Workshop', LucideIcons.wand2),
  jobs('Shoots', LucideIcons.play),
  products('Products', LucideIcons.package),
  models('House Models', LucideIcons.users),
  billing('Billing', LucideIcons.creditCard),
  settings('Settings', LucideIcons.settings),
  support('Support', LucideIcons.messageCircle),
  assistant('Assistant', LucideIcons.wand2),
  school('Studio School', LucideIcons.graduationCap),
  guides('Guides', LucideIcons.bookOpen);

  const DashboardPage(this.label, this.icon);

  final String label;
  final IconData icon;

  String get routePath {
    return switch (this) {
      DashboardPage.dashboard => AppRoutes.home,
      DashboardPage.workshop => AppRoutes.workshop,
      DashboardPage.jobs => AppRoutes.dashboardShoots,
      DashboardPage.products => AppRoutes.dashboardProducts,
      DashboardPage.models => AppRoutes.dashboardModels,
      DashboardPage.billing => AppRoutes.dashboardBilling,
      DashboardPage.settings => AppRoutes.dashboardAccount,
      DashboardPage.support => AppRoutes.dashboardSupport,
      DashboardPage.assistant => AppRoutes.assistant,
      DashboardPage.school => AppRoutes.studioSchool,
      DashboardPage.guides => AppRoutes.dashboardGuides,
    };
  }
}
