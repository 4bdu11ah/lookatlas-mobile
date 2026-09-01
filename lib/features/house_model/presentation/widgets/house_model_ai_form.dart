part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _AiModelFormState {
  const _AiModelFormState({
    this.gender = _ModelGender.female,
    this.submitted = false,
    this.generating = false,
    this.generated = false,
    this.errorMessage,
  });

  final _ModelGender gender;
  final bool submitted;
  final bool generating;
  final bool generated;
  final String? errorMessage;

  _AiModelFormState copyWith({
    _ModelGender? gender,
    bool? submitted,
    bool? generating,
    bool? generated,
    String? errorMessage,
    bool clearError = false,
  }) {
    return _AiModelFormState(
      gender: gender ?? this.gender,
      submitted: submitted ?? this.submitted,
      generating: generating ?? this.generating,
      generated: generated ?? this.generated,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class _AiModelFormNotifier extends Notifier<_AiModelFormState> {
  @override
  _AiModelFormState build() => const _AiModelFormState();

  void setGender(_ModelGender value) =>
      state = state.copyWith(gender: value, clearError: true);

  void setSubmitted() => state = state.copyWith(submitted: true);

  void setGenerating() =>
      state = state.copyWith(generating: true, clearError: true);

  void setError(String message) =>
      state = state.copyWith(generating: false, errorMessage: message);

  void clearError() => state = state.copyWith(clearError: true);

  void setGenerated() => state = state.copyWith(
    generating: false,
    generated: true,
    submitted: false,
    clearError: true,
  );

  void reset() => state = const _AiModelFormState();
}

final _aiModelFormProvider =
    NotifierProvider<_AiModelFormNotifier, _AiModelFormState>(
      _AiModelFormNotifier.new,
    );

class _AiModelSheet extends ConsumerStatefulWidget {
  const _AiModelSheet({required this.onGenerated, this.dialog = false});

  final Future<String?> Function(
    _ModelGender gender,
    int age,
    String description,
  )
  onGenerated;
  final bool dialog;

  @override
  ConsumerState<_AiModelSheet> createState() => _AiModelSheetState();
}

class _AiModelSheetState extends ConsumerState<_AiModelSheet> {
  final _ageController = TextEditingController(text: '25');
  final _descriptionController = TextEditingController();
  final GlobalKey _errorKey = GlobalKey();

  @override
  void dispose() {
    _ageController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _generate(
    int? age,
    bool ageValid,
    String description,
  ) async {
    final notifier = ref.read(_aiModelFormProvider.notifier)..setSubmitted();
    if (age == null || !ageValid || description.length < 10) return;
    notifier.setGenerating();
    final gender = ref.read(_aiModelFormProvider).gender;
    final errorMessage = await widget.onGenerated(gender, age, description);
    if (!mounted) return;
    if (errorMessage != null) {
      notifier.setError(errorMessage);
      return;
    }
    notifier.setGenerated();
    _descriptionController.clear();
  }

  void _scrollToError() {
    final errorContext = _errorKey.currentContext;
    if (errorContext == null) return;
    Scrollable.ensureVisible(
      errorContext,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<_AiModelFormState>(_aiModelFormProvider, (prev, next) {
      if (prev?.errorMessage == null && next.errorMessage != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToError());
      }
    });
    final formState = ref.watch(_aiModelFormProvider);
    final age = int.tryParse(_ageController.text);
    final ageValid = age != null && age >= 18 && age <= 100;
    final description = _descriptionController.text.trim();
    final form = _buildForm(
      formState,
      ageValid,
      description.length >= 10,
    );
    final action = PrimaryButton(
      key: const ValueKey('generate-ai-model'),
      label: formState.generated
          ? 'Generate another'
          : 'Generate model (20 credits)',
      icon: Icons.auto_awesome,
      isLoading: formState.generating,
      onPressed: () => unawaited(_generate(age, ageValid, description)),
    );
    return widget.dialog
        ? _buildDialog(form, action)
        : _buildBottomSheet(form, action);
  }

  Widget _buildForm(
    _AiModelFormState formState,
    bool ageValid,
    bool descriptionValid,
  ) {
    return SingleChildScrollView(
      padding: widget.dialog
          ? const EdgeInsets.fromLTRB(20, 18, 20, 20)
          : const EdgeInsets.fromLTRB(18, 24, 18, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!widget.dialog)
            const _IntroCopy(
              title: 'Create your own model',
              body:
                  'Describe your ideal talent and we will generate four consistent, studio-ready poses for 20 credits.',
            ),
          _SelectBlock<_ModelGender>(
            label: 'Gender',
            value: formState.gender,
            values: const [
              _ModelGender.female,
              _ModelGender.male,
              _ModelGender.nonBinary,
            ],
            labelFor: (value) => value.label,
            onChanged: ref.read(_aiModelFormProvider.notifier).setGender,
          ),
          _TextFieldBlock(
            label: 'Age',
            required: true,
            controller: _ageController,
            keyboardType: TextInputType.number,
            invalid: formState.submitted && !ageValid,
            error: 'Age must be between 18 and 100.',
            onChanged: (_) =>
                ref.read(_aiModelFormProvider.notifier).clearError(),
          ),
          _TextAreaBlock(
            controller: _descriptionController,
            invalid: formState.submitted && !descriptionValid,
            onChanged: (_) =>
                ref.read(_aiModelFormProvider.notifier).clearError(),
          ),
          const _BenefitCard(),
          if (formState.errorMessage != null)
            _AiModelErrorBox(key: _errorKey, message: formState.errorMessage!),
          if (formState.generated) const _GenerationStatus(),
        ],
      ),
    );
  }

  Widget _buildDialog(Widget form, Widget action) {
    return Column(
      children: [
        _ModelDialogHeader(
          title: 'Create your own model (AI)',
          subtitle:
              'We will generate 4 consistent poses (front, left, right, back) for 20 credits.',
          onClose: () => Navigator.pop(context),
        ),
        Expanded(child: form),
        _ModelDialogFooter(
          stacked: true,
          actions: [
            AppOutlinedButton(
              label: 'Close',
              onPressed: () => Navigator.pop(context),
            ),
            action,
          ],
        ),
      ],
    );
  }

  Widget _buildBottomSheet(Widget form, Widget action) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.94,
      child: Column(
        children: [
          _InnerHeader(
            title: 'Create with AI',
            onClose: () => Navigator.pop(context),
          ),
          Expanded(child: form),
          _SheetActionBar(
            actions: [
              AppOutlinedButton(
                label: 'Close',
                onPressed: () => Navigator.pop(context),
              ),
              action,
            ],
          ),
        ],
      ),
    );
  }
}

class _AiModelErrorBox extends StatelessWidget {
  const _AiModelErrorBox({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: AppColors.dangerLight,
        border: Border(left: BorderSide(color: AppColors.danger, width: 4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline,
            size: 18,
            color: AppColors.dangerDark,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                height: 20 / 14,
                fontWeight: AppTypography.medium,
                color: AppColors.dangerDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
