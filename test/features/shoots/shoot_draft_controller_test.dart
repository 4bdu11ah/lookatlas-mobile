import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/providers/core_providers.dart';
import 'package:look_atlas/features/auth/di/auth_providers.dart';
import 'package:look_atlas/features/auth/domain/entities/app_user.dart';
import 'package:look_atlas/features/shoots/di/shoots_providers.dart';
import 'package:look_atlas/features/shoots/domain/entities/shoot_draft.dart';
import 'package:look_atlas/features/shoots/presentation/controllers/create_shoot_controller.dart';
import 'package:look_atlas/features/shoots/presentation/controllers/shoot_draft_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_repositories.dart';
import '../../helpers/fake_shoots_repository.dart';

void main() {
  test('local_only_mirror_is_listed_and_restored_after_restart', () async {
    const userId = 'user-1';
    const snapshot = ShootDraftSnapshot(
      currentStep: 'model',
      selectedProductIds: ['product-1'],
    );
    final mirror = ShootDraftMirror(
      snapshot: snapshot,
      title: 'Tan Leather Bag',
      thumbnailUrl: '/bag.jpg',
      updatedAt: DateTime.utc(2026, 9, 16),
    );
    SharedPreferences.setMockInitialValues({
      ShootDraftMirror.storageKey(userId): jsonEncode(mirror.toJson()),
    });
    final preferences = await SharedPreferences.getInstance();
    final repository = FakeShootsRepository();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(
            user: const AppUser(id: userId, email: 'creator@example.com'),
          ),
        ),
        shootsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(shootDraftProvider.notifier).load();
    expect(container.read(shootDraftProvider).drafts.single.id, 'local');

    await container.read(shootDraftProvider.notifier).initializeEditor('local');

    final restored = container.read(createShootControllerProvider);
    expect(restored.step.name, 'model');
    expect(restored.selectedProductIds, ['product-1']);
    expect(repository.getShootDraftCalls, 0);
  });
}
