/// Centralized route paths and names. Reference these instead of string
/// literals so renames are a single edit.
abstract final class AppRoutes {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  // Pre-login onboarding funnel, in flow order: wizard -> starting loader ->
  // swipe -> results -> paywall -> one-time success.
  static const onboardingStarting = '/onboarding/starting';
  static const onboardingSwipe = '/onboarding/swipe';
  static const onboardingResults = '/onboarding/results';
  static const onboardingActivate = '/onboarding/activate';
  static const onboardingSuccess = '/onboarding/success';
  static const billingSuccess = '/billing/success';
  static const signIn = '/sign-in';
  static const signUp = '/sign-up';
  static const resetPassword = '/reset-password';
  static const home = '/';
  static const workshop = '/workshop';
  static const workshopGuide = '/workshop/guide';
  static const createShoot = '/create';
  static const dashboardShoots = '/shoots';
  static const shootDetailPath = '/shoots/:jobId';
  static const dashboardProducts = '/products';
  static const dashboardModels = '/models';
  static const dashboardBilling = '/billing';
  static const dashboardAccount = '/account';
  static const dashboardSupport = '/support';
  static const studioSchool = '/school';
  static const welcome = '/welcome';
  static const dashboardGuides = '/guides';
  static const assistant = '/assistant';
  static const chat = '/chat';
  static const paywall = '/paywall';
  static const selectPlan = '/select-plan';
  static const settings = '/settings';

  static String shootDetail(String jobId, {bool fromDashboard = false}) {
    final path = '/shoots/${Uri.encodeComponent(jobId)}';
    return fromDashboard ? '$path?from=dashboard' : path;
  }
}
