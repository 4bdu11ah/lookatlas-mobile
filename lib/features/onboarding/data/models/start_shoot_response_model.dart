import 'package:look_atlas/features/onboarding/domain/entities/free_shoot.dart';

class StartShootResponseModel {
  const StartShootResponseModel({required this.entity});

  factory StartShootResponseModel.fromJson(Map<String, dynamic> json) {
    final estimated = json['estimatedCompletion'];
    return StartShootResponseModel(
      entity: StartShootResponse(
        id: json['id'] as String? ?? '',
        status: json['status'] as String? ?? 'pending',
        message: json['message'] as String? ?? '',
        estimatedCompletion: estimated is String
            ? DateTime.tryParse(estimated)
            : null,
        shotCount: (json['shotCount'] as num?)?.toInt() ?? 5,
        variations: (json['variations'] as num?)?.toInt() ?? 3,
        totalImages: (json['totalImages'] as num?)?.toInt() ?? 15,
      ),
    );
  }

  final StartShootResponse entity;

  StartShootResponse toEntity() => entity;
}
