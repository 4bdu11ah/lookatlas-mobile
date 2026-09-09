import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/features/workshop/domain/entities/workshop_models.dart';
import 'package:look_atlas/features/workshop/presentation/controllers/workshop_controller.dart';

final NotifierProvider<WorkshopController, WorkshopState>
workshopControllerProvider =
    NotifierProvider.autoDispose<WorkshopController, WorkshopState>(
      WorkshopController.new,
    );
