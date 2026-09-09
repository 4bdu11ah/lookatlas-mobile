import 'package:look_atlas/features/shoots/domain/entities/shoot_create.dart';
import 'package:look_atlas/features/shoots/domain/repositories/shoots_repository.dart';

class DemoShootDirector {
  const DemoShootDirector({required this.name, required this.config});

  final String name;
  final DemoDirectorConfig config;
}

class DemoShootOutcome {
  const DemoShootOutcome({
    required this.firstJobId,
    required this.createdCount,
    required this.failedDirectors,
  });

  final String? firstJobId;
  final int createdCount;
  final List<String> failedDirectors;
}

class CreateDemoShootsUseCase {
  const CreateDemoShootsUseCase(this._repository);

  final ShootsRepository _repository;

  Future<DemoShootOutcome> call({
    required List<DemoShootDirector> directors,
    required List<ShootCatalogItem> products,
    required List<ShootCatalogItem> models,
    required ProductMode productMode,
    required ShootSettings settings,
    required String demoGroupId,
  }) async {
    final failed = <String>[];
    String? firstJobId;
    var createdCount = 0;
    for (final director in directors) {
      final config = director.config;
      final selection = ShootSelection(
        products: products,
        models: models,
        productMode: productMode,
        settings: settings.copyWith(
          directorId: config.directorId,
          numberOfShots: config.numberOfShots,
          variations: config.variations,
          imageSize: '2K',
          lane: ShootLane.fast,
          stylingNotes: const {},
        ),
      );
      final planned = await _repository.planShots(selection);
      if (planned.isErr) {
        failed.add(director.name);
        continue;
      }
      final created = await _repository.createShoot(
        CreateShootRequest(
          selection: selection,
          shots: planned.valueOrNull!.take(config.numberOfShots).toList(),
          demoGroupId: demoGroupId,
        ),
      );
      if (created.isErr) {
        failed.add(director.name);
        continue;
      }
      firstJobId ??= created.valueOrNull!;
      createdCount++;
    }
    return DemoShootOutcome(
      firstJobId: firstJobId,
      createdCount: createdCount,
      failedDirectors: List.unmodifiable(failed),
    );
  }
}
