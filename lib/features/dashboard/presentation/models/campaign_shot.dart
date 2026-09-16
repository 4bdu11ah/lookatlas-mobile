import 'package:flutter/foundation.dart';
import 'package:look_atlas/core/error/failure.dart';

@immutable
class CampaignShot {
  const CampaignShot({
    required this.id,
    required this.url,
    required this.approved,
  });

  final String id;
  final String? url;
  final bool approved;
}

typedef ToggleCampaignShot = Future<Failure?> Function(
  CampaignShot shot, {
  required bool approved,
});
