library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/core/theme/app_typography.dart';
import 'package:look_atlas/shared/widgets/app_dotted_border.dart';
import 'package:look_atlas/shared/widgets/app_feature_scaffold.dart';

part 'models/guides_mock_data.dart';
part 'models/guides_screen_state.dart';
part 'controllers/guides_controller.dart';
part 'screens/guides_page.dart';
part 'tabs/getting_started_guide.dart';
part 'tabs/models_guide.dart';
part 'tabs/product_photos_guide.dart';
part 'tabs/shoots_guide.dart';
part 'widgets/guides_widgets.dart';
