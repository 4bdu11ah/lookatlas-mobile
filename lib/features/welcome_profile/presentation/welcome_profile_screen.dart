import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:look_atlas/core/providers/core_providers.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/core/theme/app_typography.dart';
import 'package:look_atlas/features/auth/presentation/auth_controller.dart';
import 'package:look_atlas/features/dashboard/domain/entities/dashboard_welcome.dart';
import 'package:look_atlas/features/studio_school/di/studio_school_providers.dart';
import 'package:look_atlas/features/studio_school/presentation/studio_school_controller.dart';
import 'package:look_atlas/features/studio_school/presentation/studio_school_state.dart';
import 'package:look_atlas/features/welcome_profile/domain/welcome_profile_draft.dart';
import 'package:look_atlas/shared/widgets/app_snack_bar.dart';
import 'package:look_atlas/shared/widgets/app_text_field.dart';
import 'package:look_atlas/shared/widgets/look_atlas_loader.dart';
import 'package:look_atlas/shared/widgets/loading_icon_button.dart';
import 'package:look_atlas/shared/widgets/profile_use_card.dart';

part 'welcome_profile_steps.dart';
part 'welcome_profile_controls.dart';
part 'welcome_profile_worktable.dart';

enum _ProfileStep { brand, uses, cadence, referral }

class _ProfilePrintsAnimated extends Notifier<bool> {
  @override
  bool build() => false;

  void complete() => state = true;
}

final _profilePrintsAnimatedProvider =
    NotifierProvider.autoDispose<_ProfilePrintsAnimated, bool>(
      _ProfilePrintsAnimated.new,
    );

class WelcomeProfileScreen extends ConsumerStatefulWidget {
  const WelcomeProfileScreen({super.key});

  @override
  ConsumerState<WelcomeProfileScreen> createState() =>
      _WelcomeProfileScreenState();
}

class _WelcomeProfileScreenState extends ConsumerState<WelcomeProfileScreen> {
  final _brandController = TextEditingController();
  final _verticalController = TextEditingController();
  final _referralOtherController = TextEditingController();
  final _urlFocus = FocusNode();
  final _uses = <String>{};
  _ProfileStep _step = _ProfileStep.brand;
  String? _cadence;
  String? _referral;
  bool _initialized = false;
  bool _urlTouched = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _urlFocus.addListener(_handleUrlFocus);
  }

  void _handleUrlFocus() {
    if (!_urlFocus.hasFocus && !_urlTouched) {
      setState(() => _urlTouched = true);
    }
  }

  @override
  void dispose() {
    _urlFocus
      ..removeListener(_handleUrlFocus)
      ..dispose();
    _brandController.dispose();
    _verticalController.dispose();
    _referralOtherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final school = ref.watch(studioSchoolControllerProvider);
    final welcome = switch (school) {
      SchoolReady(:final welcome) ||
      SchoolOfflineCached(:final welcome) => welcome,
      _ => null,
    };
    if (welcome == null) {
      return const Scaffold(body: Center(child: LookAtlasLoader()));
    }
    if (!_initialized) _initialize(welcome.dashboard?.profile);
    final printsAnimated = ref.watch(_profilePrintsAnimatedProvider);
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: _ProfileWorktable(
        child: SafeArea(
          child: Column(
            children: [
              Offstage(
                offstage: keyboardOpen,
                child: _DirectorPrints(
                  step: _step.index,
                  animateEntrance: !printsAnimated,
                  onEntranceComplete: () => ref
                      .read(_profilePrintsAnimatedProvider.notifier)
                      .complete(),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    _ProfileProgress(step: _step.index),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) =>
                            SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(
                                24,
                                0,
                                24,
                                54,
                              ),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight - 60,
                                ),
                                child: Center(child: _buildStep()),
                              ),
                            ),
                      ),
                    ),
                    _ProfileFooter(
                      finalStep: _step == _ProfileStep.referral,
                      canContinue: _canContinue,
                      submitting: _submitting,
                      onSkip: () => unawaited(_finish(skipped: true)),
                      onContinue: _canContinue ? _next : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _initialize(DashboardWelcomeProfile? profile) {
    final value = profile ?? const DashboardWelcomeProfile();
    _brandController.text = value.brandUrl;
    _verticalController.text = value.vertical;
    _referralOtherController.text = value.referralOther;
    _uses.addAll(value.primaryUses);
    _cadence = value.dropCadence;
    _referral = value.referral;
    _initialized = true;
  }

  Widget _buildStep() => switch (_step) {
    _ProfileStep.brand => _BrandStep(
      brandController: _brandController,
      verticalController: _verticalController,
      urlFocus: _urlFocus,
      showUrlError: _urlTouched && !brandUrlLooksValid(_brandController.text),
      onChanged: () => setState(() {}),
    ),
    _ProfileStep.uses => _UsesStep(
      selected: _uses,
      onToggle: (value) => setState(
        () => _uses.contains(value) ? _uses.remove(value) : _uses.add(value),
      ),
    ),
    _ProfileStep.cadence => _CadenceStep(
      selected: _cadence,
      onSelected: (value) => setState(() => _cadence = value),
    ),
    _ProfileStep.referral => _ReferralStep(
      selected: _referral,
      otherController: _referralOtherController,
      onSelected: (value) => setState(() => _referral = value),
    ),
  };

  bool get _canContinue => switch (_step) {
    _ProfileStep.brand =>
      (_brandController.text.trim().isNotEmpty ||
              _verticalController.text.trim().isNotEmpty) &&
          brandUrlLooksValid(_brandController.text),
    _ProfileStep.uses => _uses.isNotEmpty,
    _ProfileStep.cadence => _cadence != null,
    _ProfileStep.referral => _referral != null,
  };

  void _next() {
    if (!_canContinue || _submitting) return;
    FocusManager.instance.primaryFocus?.unfocus();
    if (_step == _ProfileStep.brand) {
      _brandController.text = normalizeBrandUrl(_brandController.text);
    }
    if (_step == _ProfileStep.referral) {
      unawaited(_finish(skipped: false));
      return;
    }
    setState(() {
      _step = _ProfileStep.values[_step.index + 1];
      _urlTouched = false;
    });
  }

  Future<void> _finish({required bool skipped}) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    final userId = ref.read(authStateProvider).value?.id;
    if (userId == null) {
      if (mounted) context.go(AppRoutes.home);
      return;
    }
    try {
      await ref
          .read(keyValueStoreProvider)
          .setBool('la_welcome_intro_done:$userId', value: true);
    } on Object {
      // Storage is best effort. The in-memory route transition still proceeds.
    }
    final repository = ref.read(welcomeRepositoryProvider);
    if (skipped) {
      await repository.recordEvent(
        userId,
        'welcome.intro_skipped',
        properties: {'step': _step.index + 1},
      );
    } else {
      await repository.recordEvent(userId, 'welcome.intro_completed');
      final result = await repository.saveProfile(userId, _draft.toPayload());
      if (mounted && result.isErr) {
        AppSnackBar.showError(
          context,
          'Profile could not be saved. You can try again from the dashboard.',
        );
      }
    }
    if (!mounted) return;
    unawaited(
      ref.read(studioSchoolControllerProvider.notifier).refresh(),
    );
    context.go(AppRoutes.home);
  }

  WelcomeProfileDraft get _draft => WelcomeProfileDraft(
    brandUrl: _brandController.text,
    vertical: _verticalController.text,
    primaryUses: _uses.toList(growable: false),
    dropCadence: _cadence,
    referral: _referral,
    referralOther: _referralOtherController.text,
  );
}
