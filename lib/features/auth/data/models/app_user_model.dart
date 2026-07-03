import 'package:look_atlas/features/auth/domain/entities/app_user.dart';

/// Data-layer representation of [AppUser]. Extends the domain entity and adds
/// JSON (de)serialization, keeping the entity free of transport concerns.
class AppUserModel extends AppUser {
  const AppUserModel({
    required super.id,
    required super.email,
    super.displayName,
    super.photoUrl,
    super.companyName,
  });

  factory AppUserModel.fromJson(Map<String, dynamic> json) => AppUserModel(
    id: json['id'] as String,
    email: json['email'] as String,
    displayName: json['display_name'] as String?,
    photoUrl: json['photo_url'] as String?,
    companyName: json['company_name'] as String?,
  );

  /// Wraps a domain [AppUser] so it can be persisted.
  factory AppUserModel.fromEntity(AppUser user) => AppUserModel(
    id: user.id,
    email: user.email,
    displayName: user.displayName,
    photoUrl: user.photoUrl,
    companyName: user.companyName,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'display_name': displayName,
    'photo_url': photoUrl,
    'company_name': companyName,
  };
}
