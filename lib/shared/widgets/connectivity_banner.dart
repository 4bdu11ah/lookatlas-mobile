import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/core/connectivity/connectivity_provider.dart';

/// Wraps the app and shows a dismissable-free bar at the bottom whenever the
/// device is offline. Mounted once via `MaterialApp.builder`.
///
/// The banner only appears after the device has been offline for a short
/// grace period: connectivity plugins commonly report a transient "none"
/// right at cold start (before the network path is evaluated), which would
/// otherwise flash "No internet" over the splash screen.
class ConnectivityBanner extends ConsumerStatefulWidget {
  const ConnectivityBanner({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends ConsumerState<ConnectivityBanner> {
  static const _offlineGrace = Duration(milliseconds: 1500);

  Timer? _grace;
  bool _showBanner = false;

  @override
  void dispose() {
    _grace?.cancel();
    super.dispose();
  }

  void _onStatusChanged(bool isOnline) {
    if (isOnline) {
      // Back online: hide immediately.
      _grace?.cancel();
      _grace = null;
      if (_showBanner) setState(() => _showBanner = false);
      return;
    }
    // Offline: only surface it once it has persisted past the grace window.
    _grace ??= Timer(_offlineGrace, () {
      _grace = null;
      if (mounted && !ref.read(connectionStatusProvider)) {
        setState(() => _showBanner = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(connectionStatusProvider, (_, isOnline) {
      _onStatusChanged(isOnline);
    });
    final theme = Theme.of(context);

    return Stack(
      children: [
        widget.child,
        if (_showBanner)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Material(
              color: theme.colorScheme.errorContainer,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.wifi_off_rounded,
                        size: 18,
                        color: theme.colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'No internet connection',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
