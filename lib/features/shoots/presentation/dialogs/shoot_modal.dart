library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/core/theme/app_typography.dart';
import 'package:look_atlas/features/house_model/di/house_model_providers.dart';
import 'package:look_atlas/features/house_model/domain/entities/house_model_profile.dart';
import 'package:look_atlas/features/onboarding/di/onboarding_providers.dart';
import 'package:look_atlas/features/onboarding/domain/entities/onboarding_models.dart';
import 'package:look_atlas/features/onboarding/domain/entities/onboarding_product.dart';
import 'package:look_atlas/features/onboarding/presentation/widgets/director_portfolio_modal.dart';
import 'package:look_atlas/features/shoots/domain/entities/shoot_create.dart';
import 'package:look_atlas/features/shoots/domain/entities/shoot_job.dart';
import 'package:look_atlas/features/shoots/presentation/controllers/create_shoot_controller.dart';
import 'package:look_atlas/features/shoots/presentation/controllers/shoot_detail_controller.dart';
import 'package:look_atlas/features/shoots/presentation/models/shoot_modal_kind.dart';
import 'package:look_atlas/features/shoots/presentation/widgets/shoot_option_wrap.dart';
import 'package:look_atlas/shared/image_picker/image_picker_providers.dart';
import 'package:look_atlas/shared/image_picker/image_source_sheet.dart';
import 'package:look_atlas/shared/widgets/app_card.dart';
import 'package:look_atlas/shared/widgets/app_dialog.dart';
import 'package:look_atlas/shared/widgets/app_feedback.dart';
import 'package:look_atlas/shared/widgets/app_image.dart';
import 'package:look_atlas/shared/widgets/app_modal_frame.dart';
import 'package:look_atlas/shared/widgets/app_outlined_button.dart';
import 'package:look_atlas/shared/widgets/app_snack_bar.dart';
import 'package:look_atlas/shared/widgets/app_tap_icon_button.dart';
import 'package:look_atlas/shared/widgets/app_text.dart';
import 'package:look_atlas/shared/widgets/app_text_field.dart';
import 'package:look_atlas/shared/widgets/primary_button.dart';

part 'shoot_catalog_dialogs.dart';
part 'shoot_dialogs.dart';
part 'shoot_form_widgets.dart';
part 'shoot_media_dialogs.dart';
part 'shoot_video_dialogs.dart';

typedef _ShootModalKind = ShootModalKind;

Future<void> openShootModal(
  BuildContext context,
  WidgetRef ref,
  ShootModalKind kind,
) {
  if (kind == _ShootModalKind.editAi) {
    return _showAiEditDialog(
      context,
      onToast: (text) => AppSnackBar.show(context, text),
    );
  }
  if (kind == _ShootModalKind.directorPortfolio) {
    final createState = ref.read(createShootControllerProvider);
    final shootDirector = _selectedShootDirector(ref);
    final director = _onboardingDirectorFor(shootDirector);
    if (director != null) {
      final selected = createState.demoMode
          ? createState.demoDirectors.any(
              (config) => config.directorId == shootDirector?.id,
            )
          : createState.selectedDirector == createState.previewDirector;
      return showDirectorPortfolio(
        context,
        director: director,
        isSelected: selected,
        onSelect: () {
          final controller = ref.read(createShootControllerProvider.notifier);
          if (createState.demoMode) {
            controller.toggleDemoDirector(createState.previewDirector);
          } else {
            controller.selectDirector(createState.previewDirector);
          }
        },
      );
    }
  }
  return showAppDialog<void>(
    context: context,
    builder: (_) => _ShootDialog(
      kind: kind,
      onOpenBilling: () => unawaited(
        context.push<void>(AppRoutes.dashboardBilling),
      ),
      onOpenModal: (nextKind) => openShootModal(context, ref, nextKind),
      onToast: (text) => AppSnackBar.show(context, text),
    ),
  );
}

Director? _onboardingDirectorFor(ShootLook? shootDirector) {
  if (shootDirector == null) return null;
  for (final director in directors) {
    if (director.apiId == shootDirector.id ||
        director.id == shootDirector.id ||
        director.name == shootDirector.name) {
      return director;
    }
  }
  return null;
}
