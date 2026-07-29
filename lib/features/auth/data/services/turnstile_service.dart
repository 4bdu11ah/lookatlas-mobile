import 'package:cloudflare_turnstile/cloudflare_turnstile.dart';
import 'package:look_atlas/core/config/app_config.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/result/result.dart';

/// Creates short-lived Cloudflare Turnstile tokens for auth requests.
///
/// Turnstile is intentionally created only when an auth action is submitted.
/// The API must validate the returned token with Cloudflare's secret key.
class TurnstileService {
  Future<Result<String?>> getToken() async {
    if (!AppConfig.hasTurnstile) return const Result.ok(null);

    final turnstile = CloudflareTurnstile.invisible(
      siteKey: AppConfig.turnstileSiteKey,
      baseUrl: AppConfig.turnstileBaseUrl,
      action: 'auth',
    );
    try {
      final token = await turnstile.getToken();
      if (token == null || token.isEmpty) {
        return const Result.err(
          AuthFailure('Security check failed. Please try again.'),
        );
      }
      return Result.ok(token);
    } on TurnstileException catch (error, stackTrace) {
      return Result.err(
        AuthFailure(
          'Security check failed. Please try again.',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    } on Exception catch (error, stackTrace) {
      return Result.err(
        AuthFailure(
          'Security check failed. Please try again.',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    } finally {
      await turnstile.dispose();
    }
  }
}
