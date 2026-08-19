part of '../../presentation/screens/dashboard_screen.dart';

enum _DashboardPage {
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

  const _DashboardPage(this.label, this.icon);

  final String label;
  final IconData icon;

  String get routePath {
    return switch (this) {
      _DashboardPage.dashboard => AppRoutes.home,
      _DashboardPage.workshop => AppRoutes.workshop,
      _DashboardPage.jobs => AppRoutes.dashboardShoots,
      _DashboardPage.products => AppRoutes.dashboardProducts,
      _DashboardPage.models => AppRoutes.dashboardModels,
      _DashboardPage.billing => AppRoutes.dashboardBilling,
      _DashboardPage.settings => AppRoutes.dashboardAccount,
      _DashboardPage.support => AppRoutes.dashboardSupport,
      _DashboardPage.assistant => AppRoutes.assistant,
      _DashboardPage.school => AppRoutes.studioSchool,
      _DashboardPage.guides => AppRoutes.dashboardGuides,
    };
  }
}

enum _ModalKind {
  contextPaywall,
  product,
  model,
  directorPortfolio,
  portfolioViewer,
  customShot,
  imagePreview,
  editAi,
  variation,
  versions,
  videoOptions,
  videoFrame,
  videoConfirm,
  delete,
}
