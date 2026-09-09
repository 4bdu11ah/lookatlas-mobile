library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/core/theme/app_typography.dart';
import 'package:look_atlas/features/account_deletion/presentation/screens/account_deletion_page.dart';
import 'package:look_atlas/features/auth/di/auth_providers.dart';
import 'package:look_atlas/shared/widgets/app_feature_scaffold.dart';

part 'models/account_settings_mock_data.dart';
part 'models/account_settings_state.dart';
part 'controllers/account_settings_controller.dart';
part 'screens/account_settings_page.dart';
part 'widgets/account_settings_content.dart';
