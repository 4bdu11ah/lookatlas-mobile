import 'package:look_atlas/features/dashboard/domain/entities/dashboard_data.dart';
import 'package:look_atlas/features/dashboard/domain/entities/dashboard_overview.dart';

DashboardOverview dashboardGalleryFixture() => DashboardOverview(
  credits: const DashboardStats(
    credits: 240,
    creditsTotal: 400,
    creditsUsed: 160,
    totalRenders: 0,
    activeJobs: 1,
    completedJobs: 1,
  ),
  activation: const DashboardActivation(stage: DashboardActivationStage.active),
  activity: DashboardActivity(
    activeCount: 1,
    readyCount: 1,
    ready: [
      DashboardRecentJob(
        id: 'knitwear',
        name: 'Autumn Knitwear Campaign',
        status: 'completed',
        renders: 12,
        productThumbnail: 'assets/images/onboarding/showcase-tshirt-before.jpg',
        modelThumbnail: '',
        completedAt: DateTime.utc(2026, 9, 12),
      ),
    ],
    active: [
      DashboardRecentJob(
        id: 'blouse',
        name: 'Minimalist Silk Blouse',
        status: 'processing',
        renders: 0,
        productThumbnail: 'assets/images/onboarding/showcase-dress-before.jpg',
        modelThumbnail: '',
        progress: 65,
        currentStep: 'Step 2/4',
        updatedAt: DateTime.utc(2026, 9, 15, 11, 58),
      ),
    ],
    recentCompleted: [
      DashboardRecentJob(
        id: 'editorial',
        name: 'Studio Editorial 2026',
        status: 'completed',
        renders: 18,
        productThumbnail: '',
        modelThumbnail: '',
        heroImage: 'assets/images/onboarding/showcase-dress-after.jpg',
        completedAt: DateTime.utc(2026, 9, 10),
      ),
    ],
  ),
  products: const DashboardCollection(
    total: 14,
    title: 'Your product library',
    items: [
      DashboardCollectionItem(
        id: 'cardigan',
        name: 'Merino Cardigan',
        thumbnail: 'assets/images/onboarding/showcase-tshirt-before.jpg',
        description: 'KNT-804 • Knitwear',
      ),
      DashboardCollectionItem(
        id: 'bag',
        name: 'Leather Weekender',
        thumbnail: 'assets/images/onboarding/showcase-bag-before.jpg',
        description: 'BAG-201 • Bags',
      ),
    ],
  ),
  models: const DashboardCollection(
    total: 8,
    title: 'Your models',
    items: [
      DashboardCollectionItem(
        id: 'elena',
        name: 'Elena R.',
        thumbnail: 'assets/images/onboarding/showcase-dress-after.jpg',
        description: '178 cm • Editorial',
        featured: true,
      ),
      DashboardCollectionItem(
        id: 'marcus',
        name: 'Marcus T.',
        thumbnail: 'assets/images/onboarding/showcase-tshirt-after.jpg',
        description: '185 cm • Commercial',
        featured: true,
      ),
    ],
  ),
);
