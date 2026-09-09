import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:look_atlas/core/network/request_cancellation.dart';
import 'package:look_atlas/core/providers/core_providers.dart';
import 'package:look_atlas/features/auth/di/auth_providers.dart';
import 'package:look_atlas/features/create_content/data/repositories/content_archive_repository_impl.dart';
import 'package:look_atlas/features/create_content/data/repositories/content_repository_impl.dart';
import 'package:look_atlas/features/create_content/domain/entities/content_models.dart';
import 'package:look_atlas/features/create_content/domain/repositories/content_archive_repository.dart';
import 'package:look_atlas/features/create_content/domain/repositories/content_repository.dart';
import 'package:look_atlas/features/create_content/domain/use_cases/save_content_draft_use_case.dart';
import 'package:look_atlas/features/create_content/presentation/controllers/content_session.dart';
import 'package:look_atlas/features/dashboard/di/dashboard_providers.dart';

final contentRepositoryProvider = Provider<ContentRepository>(
  (ref) => ContentRepositoryImpl(ref.watch(apiServiceProvider)),
);

final saveContentDraftUseCaseProvider = Provider<SaveContentDraftUseCase>(
  (ref) => SaveContentDraftUseCase(ref.watch(contentRepositoryProvider)),
);

final contentArchiveDownloadProvider = Provider<ContentArchiveDownload>(
  (ref) => ContentArchiveRepositoryImpl(
    ref.watch(contentRepositoryProvider),
  ).download,
);

final FutureProvider<(List<ContentDraft>, List<ContentGeneration>)>
contentHistoryProvider =
    FutureProvider.autoDispose<(List<ContentDraft>, List<ContentGeneration>)>((
      ref,
    ) async {
      final token = RequestCancellation();
      ref.onDispose(token.cancel);
      final repo = ref.watch(contentRepositoryProvider);
      final results = await Future.wait<Object>([
        repo.drafts(cancellation: token),
        repo.history(cancellation: token),
      ]);
      return (
        results[0] as List<ContentDraft>,
        results[1] as List<ContentGeneration>,
      );
    });

// Read the backend plan identifier, not the unrelated RevenueCat product ID.
final FutureProvider<bool> contentVideoEligibleProvider =
    FutureProvider.autoDispose<bool>((
      ref,
    ) async {
      return ref.watch(contentRepositoryProvider).isVideoEligible();
    });

typedef ContentSessionFactory = ContentSession Function(
  ContentFormat format, {
  String? generationId,
});

final contentSessionFactoryProvider = Provider<ContentSessionFactory>((ref) {
  final repo = ref.watch(contentRepositoryProvider);
  final saveDraft = ref.watch(saveContentDraftUseCaseProvider);
  final preferences = ref.watch(sharedPreferencesProvider);
  final userId = ref.watch(authRepositoryProvider).currentUser?.id;
  return (format, {generationId}) {
    final key =
        'content-recovery-v1:$userId:${generationId == null ? format.name : 'item:$generationId'}';
    return ContentSession(
      repo,
      format,
      saveDraft: saveDraft,
      refreshCredits: () {
        ref
          ..invalidate(dashboardStatsProvider)
          ..invalidate(contentHistoryProvider);
      },
      restoreRecovery: () => preferences.getString(key),
      persistRecovery: (value) async {
        if (userId == null) return;
        if (value == null) {
          await preferences.remove(key);
        } else {
          await preferences.setString(key, value);
        }
      },
    );
  };
});

typedef ContentSessionArgs = ({ContentFormat format, String? generationId});

final ChangeNotifierProviderFamily<ContentSession, ContentSessionArgs>
contentSessionProvider = ChangeNotifierProvider.autoDispose
    .family<ContentSession, ContentSessionArgs>((ref, args) {
      final factory = ref.watch(contentSessionFactoryProvider);
      final session = factory(args.format, generationId: args.generationId);
      return session;
    });
