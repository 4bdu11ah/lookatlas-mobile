import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/core/storage/auth_token_cache.dart';
import 'package:look_atlas/core/storage/secure_storage.dart';
import 'package:mocktail/mocktail.dart';

class _MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

class _MockSecureStorage extends Mock implements SecureStorage {}

void main() {
  test('secure_storage_writes_all_auth_tokens', () async {
    final backend = _MockFlutterSecureStorage();
    final storage = SecureStorage(backend);
    when(
      () => backend.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});

    await storage.setAccessToken('access-token');
    await storage.setRefreshToken('refresh-token');
    await storage.setSupabaseRefreshToken('supabase-refresh-token');

    verify(
      () => backend.write(
        key: 'auth_access_token',
        value: 'access-token',
      ),
    ).called(1);
    verify(
      () => backend.write(
        key: 'auth_refresh_token',
        value: 'refresh-token',
      ),
    ).called(1);
    verify(
      () => backend.write(
        key: 'auth_supabase_refresh_token',
        value: 'supabase-refresh-token',
      ),
    ).called(1);
  });

  test('secure_storage_clear_tokens_deletes_all_auth_tokens', () async {
    final backend = _MockFlutterSecureStorage();
    final storage = SecureStorage(backend);
    when(
      () => backend.delete(key: any(named: 'key')),
    ).thenAnswer((_) async {});

    await storage.clearTokens();

    verify(() => backend.delete(key: 'auth_access_token')).called(1);
    verify(() => backend.delete(key: 'auth_refresh_token')).called(1);
    verify(
      () => backend.delete(key: 'auth_supabase_refresh_token'),
    ).called(1);
  });

  test('auth_token_cache_reads_secure_storage_once', () async {
    final storage = _MockSecureStorage();
    final cache = AuthTokenCache(storage);
    when(() => storage.accessToken).thenAnswer((_) async => 'stored-token');

    expect(await cache.get(), 'stored-token');
    expect(await cache.get(), 'stored-token');

    verify(() => storage.accessToken).called(1);
  });

  test('auth_token_cache_writes_fresh_token_through', () async {
    final storage = _MockSecureStorage();
    final cache = AuthTokenCache(storage);
    when(() => storage.setAccessToken(any())).thenAnswer((_) async {});

    await cache.set('fresh-token');

    expect(await cache.get(), 'fresh-token');
    verify(() => storage.setAccessToken('fresh-token')).called(1);
    verifyNever(() => storage.accessToken);
  });

  test('auth_token_cache_deletes_access_token_on_sign_out', () async {
    final storage = _MockSecureStorage();
    final cache = AuthTokenCache(storage);
    when(storage.deleteAccessToken).thenAnswer((_) async {});

    await cache.set(null);

    expect(await cache.get(), isNull);
    verify(storage.deleteAccessToken).called(1);
  });
}
