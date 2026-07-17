part of '../../presentation/screens/dashboard_screen.dart';

enum _DashboardPage {
  dashboard('Dashboard', Icons.dashboard_outlined),
  workshop('Workshop', Icons.auto_fix_high_outlined),
  jobs('Shoots', Icons.play_arrow_outlined),
  products('Products', Icons.inventory_2_outlined),
  models('House Models', Icons.groups_outlined),
  billing('Billing', Icons.credit_card_outlined),
  settings('Settings', Icons.settings_outlined),
  support('Support', Icons.help_outline),
  guides('Guides', Icons.menu_book_outlined);

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
      _DashboardPage.guides => AppRoutes.dashboardGuides,
    };
  }
}

enum _ModalKind {
  contextPaywall,
  product,
  cropProduct,
  productSubtype,
  model,
  directorPortfolio,
  portfolioViewer,
  customShot,
  imagePreview,
  editAi,
  variation,
  versions,
  calibration,
  videoOptions,
  videoFrame,
  videoConfirm,
  delete,
}
