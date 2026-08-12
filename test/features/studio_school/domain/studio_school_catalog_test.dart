import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/features/studio_school/domain/studio_school_catalog.dart';
import 'package:look_atlas/features/studio_school/domain/welcome_lesson.dart';

void main() {
  test('catalog_sixLessons_preservesCanonicalOrderAndCardCounts', () {
    expect(
      studioSchoolLessons.map((lesson) => lesson.id),
      WelcomeLessonId.values,
    );
    expect(
      studioSchoolLessons.map((lesson) => lesson.cards.length),
      [4, 3, 3, 3, 3, 3],
    );
  });

  test('catalog_contextualLinks_matchMobileDestinations', () {
    expect(
      studioSchoolLessons.map((lesson) => lesson.tryLink?.location),
      [
        AppRoutes.dashboardBilling,
        AppRoutes.workshop,
        AppRoutes.dashboardShoots,
        AppRoutes.dashboardSupport,
        null,
        AppRoutes.dashboardBilling,
      ],
    );
  });

  test('catalog_fourDeepGuides_preservesTabIds', () {
    expect(
      studioSchoolGuides.map((guide) => guide.tabId),
      ['getting-started', 'product-photos', 'models', 'jobs'],
    );
  });
}
