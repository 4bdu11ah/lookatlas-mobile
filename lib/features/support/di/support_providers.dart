import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/core/providers/core_providers.dart';
import 'package:look_atlas/features/support/data/repositories/support_repository_impl.dart';
import 'package:look_atlas/features/support/domain/repositories/support_repository.dart';

final Provider<SupportRepository> supportRepositoryProvider =
    Provider.autoDispose<SupportRepository>(
      (ref) {
        final cancellation = CancelToken();
        ref.onDispose(cancellation.cancel);
        return SupportRepositoryImpl(
          ref.watch(apiServiceProvider),
          cancellation: cancellation,
        );
      },
    );
final supportClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);
