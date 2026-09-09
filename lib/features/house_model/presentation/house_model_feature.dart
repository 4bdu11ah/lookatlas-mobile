library;

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/core/error/failure.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/core/theme/app_typography.dart';
import 'package:look_atlas/features/house_model/di/house_model_providers.dart';
import 'package:look_atlas/features/house_model/domain/entities/house_model_profile.dart';
import 'package:look_atlas/features/house_model/domain/repositories/house_models_repository.dart';
import 'package:look_atlas/services/service_providers.dart';
import 'package:look_atlas/shared/image_picker/image_picker_providers.dart';
import 'package:look_atlas/shared/image_picker/image_source_sheet.dart';
import 'package:look_atlas/shared/widgets/app_asset_image.dart';
import 'package:look_atlas/shared/widgets/app_bottom_sheet.dart';
import 'package:look_atlas/shared/widgets/app_dialog.dart';
import 'package:look_atlas/shared/widgets/app_dotted_border.dart';
import 'package:look_atlas/shared/widgets/app_dropdown.dart';
import 'package:look_atlas/shared/widgets/app_feature_scaffold.dart';
import 'package:look_atlas/shared/widgets/app_floating_action_button.dart';
import 'package:look_atlas/shared/widgets/app_hairline.dart';
import 'package:look_atlas/shared/widgets/app_image.dart';
import 'package:look_atlas/shared/widgets/app_outlined_button.dart';
import 'package:look_atlas/shared/widgets/app_sheet_frame.dart';
import 'package:look_atlas/shared/widgets/app_snack_bar.dart';
import 'package:look_atlas/shared/widgets/app_spaced_column.dart';
import 'package:look_atlas/shared/widgets/app_tap_icon_button.dart';
import 'package:look_atlas/shared/widgets/app_text_field.dart';
import 'package:look_atlas/shared/widgets/primary_button.dart';

part 'controllers/house_model_controller.dart';
part 'models/house_model_view_model.dart';
part 'screens/house_model_page.dart';
part 'widgets/house_model_ai_form.dart';
part 'widgets/house_model_angle_controls.dart';
part 'widgets/house_model_cards.dart';
part 'widgets/house_model_filter_sheet.dart';
part 'widgets/house_model_form_fields.dart';
part 'widgets/house_model_forms.dart';
part 'widgets/house_model_loading.dart';
part 'widgets/house_model_sections.dart';
part 'widgets/house_model_sheet_widgets.dart';

const _houseModelImagePath = 'assets/images/onboarding';
