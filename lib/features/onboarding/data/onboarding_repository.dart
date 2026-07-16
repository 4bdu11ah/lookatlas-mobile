import 'package:look_atlas/core/network/api_service.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/onboarding/domain/look_atlas_model.dart';

/// Backend calls used by the pre-login onboarding funnel.
class OnboardingRepository {
  const OnboardingRepository({required ApiService api}) : _api = api;

  final ApiService _api;

  /// Fetches the model library (`GET /lookatlas-models`), sorted by the
  /// backend's display order. The auth header is attached automatically by
  /// the Dio interceptor when a session exists.
  Future<Result<List<LookAtlasModel>>> fetchModels() {
    return _api.get(
      '/lookatlas-models',
      decoder: (data) {
        final json = data as Map<String, dynamic>? ?? const {};
        final models = [
          for (final model in json['models'] as List<dynamic>? ?? <dynamic>[])
            LookAtlasModel.fromJson(model as Map<String, dynamic>),
        ]..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
        return models;
      },
    );
  }
}
