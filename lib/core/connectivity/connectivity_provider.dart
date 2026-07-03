import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

bool _isOnline(List<ConnectivityResult> results) =>
    results.any((result) => result != ConnectivityResult.none);

/// Emits `true` when the device has a network path, `false` when offline.
///
/// The stream is seeded with a one-shot [Connectivity.checkConnectivity] so an
/// app launched offline shows the banner immediately instead of waiting for
/// connectivity to *change*. While that first reading resolves, callers should
/// assume online to avoid a false "offline" flash (see
/// `connectionStatusProvider`).
final connectivityProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  yield _isOnline(await connectivity.checkConnectivity());
  yield* connectivity.onConnectivityChanged.map(_isOnline);
});

/// Online/offline as a plain bool, defaulting to online until the first event.
final connectionStatusProvider = Provider<bool>((ref) {
  return ref.watch(connectivityProvider).value ?? true;
});
