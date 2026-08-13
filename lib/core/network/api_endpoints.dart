/// Central registry of every API endpoint path the app calls.
///
/// Data sources reference these constants instead of inlining path literals,
/// so the full API surface is visible in one place and a backend route change
/// is a one-line edit. Paths are relative — the base URL comes from
/// `AppConfig` (`apiBaseUrl` for the Look Atlas backend, `aiBaseUrl` for the
/// AI proxy).
abstract final class ApiEndpoints {
  // --- Auth (Look Atlas backend, see the Postman collection) --------------
  static const String authRegister = '/auth/register';
  static const String authLogin = '/auth/login';
  static const String authLogout = '/auth/logout';
  static const String authRefresh = '/auth/refresh';
  static const String authForgotPassword = '/auth/forgot-password';
  static const String authVerify = '/auth/verify';

  /// Sets a new password with a recovery token from the reset email. Unused
  /// by the app today: the email's link targets the web app.
  static const String authResetPassword = '/auth/reset-password';

  // --- Onboarding ---------------------------------------------------------
  static const String appConfig = '/public/app-config';
  static const String deviceTokenBootstrap = '/device/token/bootstrap';
  static const String analyticsSync = '/u/sync';
  static const String onboardingStatus = '/onboarding/status';
  static const String onboardingUpdateStatus = '/onboarding/update-status';
  static const String onboardingStartShoot = '/onboarding/start-shoot';
  static const String onboardingComplete = '/onboarding/complete';
  static const String products = '/products';
  static const String lookAtlasModels = '/lookatlas-models';
  static const String userModels = '/models';
  static const String generateModel = '/models/generate';
  static const String calibrationOutlines = '/calibration/outlines';
  static const String calibratedProducts = '/calibration/calibrated-products';

  // --- Billing ------------------------------------------------------------
  static const String billingPlans = '/billing/plans';
  static const String billingCheckoutSession = '/billing/checkout-session';
  static const String billingOnetimeSession = '/billing/onetime-session';
  static const String billingOnetimeVerify = '/billing/onetime-verify';
  static const String billingSubscription = '/billing/subscription';
  static const String billingHistory = '/billing/history';

  // --- Dashboard ----------------------------------------------------------
  static const String dashboardStats = '/dashboard/stats';
  static const String dashboardRecentJobs = '/dashboard/recent-jobs';

  // --- Assistant ----------------------------------------------------------
  static const String assistantConversations = '/assistant/conversations';
  static const String assistantSend = '/assistant/messages';

  static String assistantConversation(String conversationId) =>
      '/assistant/conversations/$conversationId';

  static String assistantMessages(String conversationId) =>
      '${assistantConversation(conversationId)}/messages';

  // --- Studio School ------------------------------------------------------
  static const String welcomeState = '/welcome/state';
  static const String welcomeClaimLessons = '/welcome/claim-lessons';

  static String welcomeLessonStart(String lessonId) =>
      '/welcome/lessons/$lessonId/start';

  static String welcomeLessonComplete(String lessonId) =>
      '/welcome/lessons/$lessonId/complete';

  // --- Shoots -------------------------------------------------------------
  static const String jobs = '/jobs';
  static const String planShots = '/jobs/v2/plan-shots';
  static const String customShot = '/jobs/v2/custom-shot';
  static const String createShoot = '/jobs/v2/create';
  static const String looks = '/looks';
  static const String lookFilters = '/looks/filters';
  static const String userPresets = '/user-presets';

  // --- Workshop -----------------------------------------------------------
  static const String workshopActive = '/workshop/active';
  static const String workshopGenerations = '/workshop/generations';
  static const String workshopGenerate = '/workshop/generate';

  static String product(String productId) => '/products/$productId';

  static String productPhotoAngles(String productId) =>
      '/products/$productId/photo-angles';

  static String productPhoto(String productId, int photoIndex) =>
      '/products/$productId/photos/$photoIndex';

  static String replaceProductPhoto(String productId, String photoId) =>
      '/products/$productId/photos/$photoId/replace';

  static String productCalibration(String productId) =>
      '/products/$productId/calibration';

  static String productCalibrationWornPhoto(String productId) =>
      '/products/$productId/calibration/worn-photo';

  static String productCalibrationCutout(String productId) =>
      '/products/$productId/calibration/cutout';

  static String copyProductCalibration(String productId) =>
      '/products/$productId/calibration/copy-from';

  static String userModel(String modelId) => '/models/$modelId';

  static String userModelPhoto(String modelId, int photoIndex) =>
      '/models/$modelId/photos/$photoIndex';

  static String modelGeneration(String generationId) =>
      '/model-generations/$generationId';

  static String job(String jobId) => '/jobs/$jobId';

  static String jobStatus(String jobId) => '/jobs/$jobId/status';

  static String rerunJob(String jobId) => '/jobs/$jobId/rerun';

  static String jobImage(String jobId, String imageId) =>
      '/jobs/$jobId/images/$imageId';

  static String downloadJobImage(String jobId, String imageId) =>
      '/jobs/$jobId/images/$imageId/download';

  static String jobVideo(String jobId) => '/jobs/$jobId/video';

  static String editJobImage(String jobId, String imageId) =>
      '/jobs/$jobId/images/$imageId/edit';

  static String jobImageEditStatus(String jobId, String imageId) =>
      '/jobs/$jobId/images/$imageId/edit-status';

  static String reportJobImage(String jobId, String imageId) =>
      '/jobs/$jobId/images/$imageId/report';

  static String addJobVariation(String jobId, int shotIndex) =>
      '/jobs/$jobId/shots/$shotIndex/add-variation';

  static String redoJobHandShots(String jobId) =>
      '/jobs/$jobId/redo-hand-shots';

  static String jobImageVersions(String jobId, String imageId) =>
      '/jobs/$jobId/images/$imageId/versions';

  static String setActiveJobImageVersion(String jobId, String imageId) =>
      '/jobs/$jobId/images/$imageId/set-active';

  static String userPreset(String presetId) => '/user-presets/$presetId';

  static String workshopGeneration(String generationId) =>
      '/workshop/generations/$generationId';

  // --- AI (Anthropic-compatible API or backend proxy) ---------------------
  static const String aiMessages = '/v1/messages';
}
