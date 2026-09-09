import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/shoots/domain/entities/shoot_create.dart';
import 'package:look_atlas/features/shoots/domain/repositories/shoots_repository.dart';
import 'package:look_atlas/features/shoots/domain/use_cases/create_demo_shoots_use_case.dart';
import 'package:mocktail/mocktail.dart';

class _MockShootsRepository extends Mock implements ShootsRepository {}

void main() {
  test('call_partialFailure_preservesSuccessfulJobAndFailedDirector', () async {
    final repository = _MockShootsRepository();
    when(() => repository.planShots(any())).thenAnswer(
      (_) async => const Ok([PlannedShootShot(title: 'Shot', description: 'Description', payload: {})]),
    );
    var calls = 0;
    when(() => repository.createShoot(any())).thenAnswer((_) async {
      calls++;
      return calls == 1
          ? const Ok('job-1')
          : const Err(UnknownFailure('Failed'));
    });
    const product = ShootCatalogItem(id: 'product', name: 'Product', imageUrl: '');
    const model = ShootCatalogItem(id: 'model', name: 'Model', imageUrl: '');

    final outcome = await CreateDemoShootsUseCase(repository)(
      directors: const [
        DemoShootDirector(name: 'First', config: DemoDirectorConfig(directorId: 'one')),
        DemoShootDirector(name: 'Second', config: DemoDirectorConfig(directorId: 'two')),
      ],
      products: const [product],
      models: const [model],
      productMode: ProductMode.pairing,
      settings: const ShootSettings(),
      demoGroupId: 'demo-1',
    );

    expect(outcome.firstJobId, 'job-1');
    expect(outcome.createdCount, 1);
    expect(outcome.failedDirectors, ['Second']);
  });
}
