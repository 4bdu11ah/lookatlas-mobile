import 'package:flutter/foundation.dart';

/// Domain entity for an authenticated user. Pure: no serialization concerns
/// (that lives in the data-layer `AppUserModel`). Hand-written `copyWith` per
/// AGENTS.md §8 (no codegen).
@immutable
class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.companyName,
  });

  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;

  /// Company entered at sign-up; null for social sign-ins and legacy sessions.
  final String? companyName;

  AppUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    String? companyName,
  }) => AppUser(
    id: id ?? this.id,
    email: email ?? this.email,
    displayName: displayName ?? this.displayName,
    photoUrl: photoUrl ?? this.photoUrl,
    companyName: companyName ?? this.companyName,
  );

  @override
  bool operator ==(Object other) =>
      other is AppUser &&
      other.id == id &&
      other.email == email &&
      other.displayName == displayName &&
      other.photoUrl == photoUrl &&
      other.companyName == companyName;

  @override
  int get hashCode =>
      Object.hash(id, email, displayName, photoUrl, companyName);
}
