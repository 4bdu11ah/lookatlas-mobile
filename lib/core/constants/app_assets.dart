/// Central catalog of every bundled image. Reference these instead of string
/// literals so a renamed file is a single edit and typos fail at compile
/// time, not at runtime.
abstract final class AppAssets {
  static const String _images = 'assets/images';
  static const String _onboarding = '$_images/onboarding';
  static const String _angles = '$_onboarding/angles';

  // --- Brand ---------------------------------------------------------------
  static const String logo = '$_images/logo.png';
  static const String googleLogo = '$_images/google_logo.svg';

  // --- Onboarding: step illustrations --------------------------------------
  static const String stepUpload = '$_onboarding/step-upload.jpg';
  static const String stepModel = '$_onboarding/step-model.jpg';
  static const String stepGenerate = '$_onboarding/step-generate.jpg';

  // --- Onboarding: intro before/after showcase ------------------------------
  /// [id] is the product segment of `showcase-<id>-{before,after}.jpg`
  /// (dress, tshirt, bag, necklace, sunglasses, shoes).
  static String showcaseBefore(String id) =>
      '$_onboarding/showcase-$id-before.jpg';
  static String showcaseAfter(String id) =>
      '$_onboarding/showcase-$id-after.jpg';

  // --- Onboarding: generic angle examples ----------------------------------
  static const String angleExampleFront =
      '$_onboarding/angle-example-front.png';
  static const String angleExampleBack = '$_onboarding/angle-example-back.png';
  static const String angleExampleSide = '$_onboarding/angle-example-side.png';
  static const String angleExampleDetail =
      '$_onboarding/angle-example-detail.png';

  // --- Onboarding: per-category angle guides --------------------------------
  static const String anglesTopsFront = '$_angles/tops-front.png';
  static const String anglesTopsBack = '$_angles/tops-back.png';
  static const String anglesDressesFront = '$_angles/dresses-front.png';
  static const String anglesDressesBack = '$_angles/dresses-back.png';
  static const String anglesDressesDetail = '$_angles/dresses-detail.png';
  static const String anglesOuterwearFront = '$_angles/outerwear-front.png';
  static const String anglesOuterwearBack = '$_angles/outerwear-back.png';
  static const String anglesOuterwearSide = '$_angles/outerwear-side.png';
  static const String anglesBottomsFront = '$_angles/bottoms-front.png';
  static const String anglesBottomsBack = '$_angles/bottoms-back.png';
  static const String anglesBagsFront = '$_angles/bags-front.png';
  static const String anglesBagsSide = '$_angles/bags-side.png';
  static const String anglesBagsDetail = '$_angles/bags-detail.png';
  static const String anglesShoesFront = '$_angles/shoes-front.png';
  static const String anglesShoesSide = '$_angles/shoes-side.png';
  static const String anglesShoesTop = '$_angles/shoes-top.png';
  static const String anglesJewelryCloseup1 = '$_angles/jewelry-closeup1.png';
  static const String anglesJewelryCloseup2 = '$_angles/jewelry-closeup2.png';
  static const String anglesEyewearFront = '$_angles/eyewear-front.png';
  static const String anglesEyewearSide = '$_angles/eyewear-side.png';
  static const String anglesWatchesFace = '$_angles/watches-face.png';
  static const String anglesWatchesSide = '$_angles/watches-side.png';
  static const String anglesAccessoriesFront = '$_angles/accessories-front.png';
  static const String anglesAccessoriesDetail =
      '$_angles/accessories-detail.png';
}
