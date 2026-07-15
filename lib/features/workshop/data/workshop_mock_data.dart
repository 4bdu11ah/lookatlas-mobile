import 'package:look_atlas/core/constants/app_assets.dart';
import 'package:look_atlas/features/workshop/domain/entities/workshop_models.dart';

const List<WorkshopHistoryItem> initialWorkshopHistory = [
  WorkshopHistoryItem(
    id: 'recent-1',
    image: AppAssets.showcaseShoesAfter,
    prompt: 'Recolor the product to bone white and keep the studio lighting.',
    createdAtLabel: '2h ago',
  ),
  WorkshopHistoryItem(
    id: 'recent-2',
    image: AppAssets.showcaseBagAfter,
    prompt: 'Place the product in a clean editorial set.',
    createdAtLabel: 'Yesterday',
  ),
  WorkshopHistoryItem(
    id: 'recent-3',
    image: AppAssets.showcaseSunglassesAfter,
    prompt: 'Make the image feel like a premium ecommerce hero photo.',
    createdAtLabel: '3d ago',
  ),
];
