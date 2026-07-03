import 'package:flutter/material.dart';

/// User-facing replacement for Flutter's red error box in release builds.
/// The underlying error is still reported to Sentry via the framework handler.
class AppErrorWidget extends StatelessWidget {
  const AppErrorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Material(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 48),
              SizedBox(height: 12),
              Text(
                'Something went wrong',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
