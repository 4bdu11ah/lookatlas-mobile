import 'dart:convert';

import 'package:look_atlas/features/shoots/domain/entities/shoot_draft.dart';

abstract final class ShootDraftCodec {
  static List<ShootDraftSummary> decodeList(dynamic data) {
    final body = _map(data);
    final raw = data is List ? data : body['drafts'] ?? body['data'];
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is Map) _summary(_map(item)),
    ];
  }

  static ShootDraft decodeDraft(dynamic data) {
    final body = _map(data);
    final rawDraft = body['draft'];
    final draft = rawDraft is Map ? _map(rawDraft) : body;
    final rawState = draft['state'];
    final state = rawState is String
        ? _map(jsonDecode(rawState))
        : _map(rawState);
    return ShootDraft(
      summary: _summary(draft),
      snapshot: ShootDraftSnapshot.fromJson(state),
    );
  }

  static Map<String, dynamic> savePayload(ShootDraftSnapshot snapshot) => {
    'state': snapshot.toJson(),
  };

  static ShootDraftSummary _summary(Map<String, dynamic> json) =>
      ShootDraftSummary(
        id: _string(json['id']),
        title: _string(json['title'], fallback: 'Untitled shoot'),
        currentStep: _string(
          json['currentStep'] ?? json['current_step'],
          fallback: 'product',
        ),
        thumbnailUrl: _string(
          json['thumbnailUrl'] ?? json['thumbnail_url'],
        ),
        updatedAt:
            DateTime.tryParse(
              _string(json['updatedAt'] ?? json['updated_at']),
            )?.toUtc() ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );
}

Map<String, dynamic> _map(Object? raw) => raw is Map
    ? raw.map((key, value) => MapEntry(key.toString(), value))
    : <String, dynamic>{};

String _string(Object? raw, {String fallback = ''}) =>
    raw is String && raw.isNotEmpty ? raw : fallback;
