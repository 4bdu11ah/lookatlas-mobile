import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/core/theme/app_typography.dart';
import 'package:look_atlas/features/house_model/domain/entities/house_model_profile.dart';
import 'package:look_atlas/features/house_model/presentation/controllers/house_model_controller.dart';
import 'package:look_atlas/features/house_model/presentation/models/house_model_view_model.dart';
import 'package:look_atlas/shared/image_picker/image_picker_providers.dart';
import 'package:look_atlas/shared/image_picker/image_source_sheet.dart';
import 'package:look_atlas/shared/widgets/app_bottom_sheet.dart';
import 'package:look_atlas/shared/widgets/app_card.dart';
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
import 'package:look_atlas/shared/widgets/app_square_icon.dart';
import 'package:look_atlas/shared/widgets/app_tap_icon_button.dart';
import 'package:look_atlas/shared/widgets/app_text_field.dart';
import 'package:look_atlas/shared/widgets/primary_button.dart';
import 'package:look_atlas/shared/widgets/shimmer_box.dart';

part '../widgets/house_model_ai_form.dart';
part '../widgets/house_model_angle_controls.dart';
part '../widgets/house_model_cards.dart';
part '../widgets/house_model_filter_sheet.dart';
part '../widgets/house_model_form_fields.dart';
part '../widgets/house_model_forms.dart';
part '../widgets/house_model_loading.dart';
part '../widgets/house_model_sections.dart';
part '../widgets/house_model_sheet_widgets.dart';

class HouseModelsScreen extends ConsumerWidget {
  const HouseModelsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppFeatureScaffold(
      title: 'House Models',
      contentBackgroundColor: AppColors.neutral50,
      maxContentWidth: 440,
      floatingActionButton: AppFloatingActionButton(
        key: const ValueKey('add-model-fab'),
        label: 'Add Model',
        icon: Icons.people_alt_outlined,
        onPressed: () => _showModelFormDialog(
          context,
          ref,
          (text) => AppSnackBar.show(context, text),
        ),
      ),

      child: RefreshIndicator(
        onRefresh: ref.read(houseModelControllerProvider.notifier).reload,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 112),
          child: _HouseModelPage(
            onToast: (text) => AppSnackBar.show(context, text),
          ),
        ),
      ),
    );
  }
}

class _HouseModelPage extends ConsumerWidget {
  const _HouseModelPage({required this.onToast});

  final ValueChanged<String> onToast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(houseModelControllerProvider);
    if (state.failure != null &&
        state.libraryModels.isEmpty &&
        state.userModels.isEmpty) {
      return _HouseModelsLoadError(
        message: state.failure!.message,
        onRetry: ref.read(houseModelControllerProvider.notifier).reload,
      );
    }
    return AppSpacedColumn(
      children: [
        if (state.failure != null)
          _HouseModelsRefreshError(
            message: state.failure!.message,
            onRetry: ref.read(houseModelControllerProvider.notifier).reload,
          ),
        Text(
          'Manage your brand models for consistent on-model imagery.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            height: 1.45,
            color: AppColors.neutral500,
          ),
        ),
        _CreateAiButton(onToast: onToast),
        const _LibraryModelsSection(),
        const AppHairline(),
        _UserModelsSection(onToast: onToast),
      ],
    );
  }
}

class _HouseModelsRefreshError extends StatelessWidget {
  const _HouseModelsRefreshError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: AppColors.neutral100,
      child: Row(
        children: [
          const Icon(
            Icons.sync_problem_outlined,
            size: 20,
            color: AppColors.neutral500,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Could not refresh models. Displayed data may be outdated. $message',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.neutral500,
              ),
            ),
          ),
          TextButton(
            onPressed: () => unawaited(onRetry()),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _HouseModelsLoadError extends StatelessWidget {
  const _HouseModelsLoadError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 420,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 38,
              color: AppColors.neutral500,
            ),
            const SizedBox(height: 12),
            const Text(
              'Could not load house models',
              style: TextStyle(
                fontSize: 18,
                fontWeight: AppTypography.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.neutral500),
            ),
            const SizedBox(height: 18),
            AppOutlinedButton(
              label: 'Retry',
              icon: Icons.refresh,
              onPressed: () => unawaited(onRetry()),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateAiButton extends ConsumerWidget {
  const _CreateAiButton({required this.onToast});

  final ValueChanged<String> onToast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppOutlinedButton(
      label: 'Create with AI',
      icon: Icons.auto_awesome,
      onPressed: () => _showAiSheet(context, ref, onToast),
    );
  }
}
