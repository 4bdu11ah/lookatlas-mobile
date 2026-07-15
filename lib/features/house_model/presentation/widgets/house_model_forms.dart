part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

Future<void> _showModelFormSheet(
  BuildContext context,
  WidgetRef ref,
  ValueChanged<String> onToast, [
  _HouseModel? model,
]) {
  void submit(BuildContext formContext, _ModelFormInput input) {
    final controller = ref.read(_houseModelControllerProvider.notifier);
    if (model == null) {
      final added = controller.addModel(input);
      onToast('${added.name} was added to Your Models');
    } else {
      controller.updateModel(model, input);
      onToast('Model details updated');
    }
    Navigator.pop(formContext);
  }

  if (model == null) {
    return showAppDialog<void>(
      context: context,
      builder: (context) => _ModelFormSheet(
        dialog: true,
        onSubmit: (input) => submit(context, input),
      ),
    );
  }

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.neutral50,
    shape: const RoundedRectangleBorder(),
    builder: (context) => _ModelFormSheet(
      model: model,
      onSubmit: (input) => submit(context, input),
      onDelete: () => _showDeleteSheet(context, ref, model, onToast),
    ),
  );
}

Future<void> _showAiSheet(
  BuildContext context,
  WidgetRef ref,
  ValueChanged<String> onToast,
) {
  return showAppDialog<void>(
    context: context,
    builder: (context) => _AiModelSheet(
      dialog: true,
      onGenerated: (gender, age, description) {
        final model = ref
            .read(_houseModelControllerProvider.notifier)
            .addAiModel(gender: gender, age: age, description: description);
        onToast('${model.name} is ready');
      },
    ),
  );
}

Future<void> _showDeleteSheet(
  BuildContext context,
  WidgetRef ref,
  _HouseModel model,
  ValueChanged<String> onToast,
) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(),
    builder: (context) => SafeArea(
      child: _SheetFrame(
        actions: [
          _ModelActionButton.secondary(
            label: 'Cancel',
            full: true,
            onTap: () => Navigator.pop(context),
          ),
          _DangerButton(
            label: 'Delete model',
            onTap: () {
              ref
                  .read(_houseModelControllerProvider.notifier)
                  .deleteModel(model);
              Navigator.pop(context);
              onToast('Model deleted');
            },
          ),
        ],
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ConfirmIcon(),
            Text(
              'Delete model?',
              style: TextStyle(
                fontSize: 21,
                fontWeight: AppTypography.bold,
                color: AppColors.black,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'This permanently removes the model and all associated photos. This action cannot be undone.',
              style: TextStyle(
                fontSize: 13,
                height: 1.55,
                color: AppColors.neutral500,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ModelDialogHeader extends StatelessWidget {
  const _ModelDialogHeader({
    required this.title,
    required this.subtitle,
    required this.onClose,
  });

  final String title;
  final String subtitle;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.neutral100)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 23,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: AppTypography.medium,
                    color: AppColors.neutral500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Semantics(
            label: 'Close',
            button: true,
            child: InkWell(
              onTap: onClose,
              child: const SizedBox.square(
                dimension: 40,
                child: Icon(Icons.close, size: 20, color: AppColors.neutral500),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModelDialogFooter extends StatelessWidget {
  const _ModelDialogFooter({required this.actions, this.stacked = false});

  final List<Widget> actions;
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    final children = [
      for (var i = 0; i < actions.length; i++) ...[
        if (stacked) actions[i] else Expanded(child: actions[i]),
        if (i != actions.length - 1)
          SizedBox(width: stacked ? 0 : 12, height: stacked ? 12 : 0),
      ],
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        color: AppColors.neutral100,
        border: Border(top: BorderSide(color: AppColors.neutral100)),
      ),
      child: stacked
          ? Column(mainAxisSize: MainAxisSize.min, children: children)
          : Row(children: children),
    );
  }
}

class _ModelFormSheet extends StatefulWidget {
  const _ModelFormSheet({
    required this.onSubmit,
    this.model,
    this.onDelete,
    this.dialog = false,
  });

  final _HouseModel? model;
  final ValueChanged<_ModelFormInput> onSubmit;
  final VoidCallback? onDelete;
  final bool dialog;

  @override
  State<_ModelFormSheet> createState() => _ModelFormSheetState();
}

class _ModelFormSheetState extends State<_ModelFormSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _heightController;
  late _ModelGender _gender;
  late int _photoCount;
  bool _heightEstimated = false;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    final model = widget.model;
    _nameController = TextEditingController(text: model?.name ?? '');
    _heightController = TextEditingController(
      text: model == null ? '' : model.heightCm.toString(),
    );
    _gender = model?.gender ?? _ModelGender.female;
    _photoCount = model?.photoCount ?? 0;
    _heightEstimated = model?.heightEstimated ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.model != null;
    final nameValid = _nameController.text.trim().isNotEmpty;
    final height = int.tryParse(_heightController.text);
    final heightValid = height != null && height >= 100 && height <= 250;
    final photosValid = _photoCount > 0;
    final formValid = nameValid && heightValid && photosValid;
    final body = SingleChildScrollView(
      padding: widget.dialog
          ? const EdgeInsets.fromLTRB(20, 18, 20, 20)
          : const EdgeInsets.fromLTRB(18, 24, 18, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!widget.dialog)
            _IntroCopy(
              title: editing ? 'Update model details' : 'Add your house model',
              body: editing
                  ? 'Keep this profile accurate so future shoots preserve the right appearance and proportions.'
                  : 'Upload clear photos and a few details so the same face and proportions stay consistent across every shoot.',
            ),
          _TextFieldBlock(
            label: 'Model Name',
            required: true,
            controller: _nameController,
            hint: 'Sarah Martinez',
            invalid: _submitted && !nameValid,
            error: 'Enter a model name.',
            onChanged: (_) => setState(() {}),
          ),
          _SelectBlock<_ModelGender>(
            label: 'Gender',
            required: true,
            value: _gender,
            values: _ModelGender.values,
            labelFor: (value) => value.label,
            onChanged: (value) => setState(() => _gender = value),
          ),
          _HeightBlock(
            controller: _heightController,
            estimated: _heightEstimated,
            invalid: _submitted && !heightValid,
            onEstimatedChanged: (value) =>
                setState(() => _heightEstimated = value),
            onChanged: (_) => setState(() {}),
          ),
          _PhotoUploadBlock(
            count: _photoCount,
            invalid: _submitted && !photosValid,
            onAdd: () => setState(() {
              if (_photoCount < 5) _photoCount++;
            }),
            onRemove: () => setState(() {
              if (_photoCount > 0) _photoCount--;
            }),
          ),
          const _TipCard(
            icon: Icons.info_outline,
            title: 'Pro Tip',
            body:
                'Upload 3-5 photos showing different angles and poses for best AI results.',
          ),
        ],
      ),
    );
    final actions = [
      _ModelActionButton.secondary(
        label: 'Cancel',
        full: true,
        onTap: () => Navigator.pop(context),
      ),
      Opacity(
        opacity: widget.dialog && !formValid ? 0.48 : 1,
        child: _ModelActionButton(
          key: const ValueKey('submit-model-form'),
          label: editing ? 'Save changes' : 'Add Model',
          icon: Icons.check,
          full: true,
          onTap: () {
            setState(() => _submitted = true);
            final parsedHeight = int.tryParse(_heightController.text);
            if (!nameValid || parsedHeight == null || !heightValid) {
              return;
            }
            if (!photosValid) return;
            widget.onSubmit(
              _ModelFormInput(
                name: _nameController.text.trim(),
                gender: _gender,
                heightCm: parsedHeight,
                photoCount: _photoCount,
                heightEstimated: _heightEstimated,
              ),
            );
          },
        ),
      ),
    ];

    if (widget.dialog) {
      return Column(
        children: [
          _ModelDialogHeader(
            title: 'Add New Model',
            subtitle: 'Upload photos and details for your house model',
            onClose: () => Navigator.pop(context),
          ),
          Expanded(child: body),
          _ModelDialogFooter(actions: actions),
        ],
      );
    }

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.94,
      child: Column(
        children: [
          _InnerHeader(
            title: editing ? 'Edit model' : 'Add new model',
            onClose: () => Navigator.pop(context),
            trailing: widget.onDelete == null
                ? null
                : IconButton(
                    tooltip: 'Delete model',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: widget.onDelete,
                  ),
          ),
          Expanded(child: body),
          _SheetActionBar(actions: actions),
        ],
      ),
    );
  }
}

class _AiModelSheet extends StatefulWidget {
  const _AiModelSheet({required this.onGenerated, this.dialog = false});

  final void Function(_ModelGender gender, int age, String description)
  onGenerated;
  final bool dialog;

  @override
  State<_AiModelSheet> createState() => _AiModelSheetState();
}

class _AiModelSheetState extends State<_AiModelSheet> {
  final _ageController = TextEditingController(text: '25');
  final _descriptionController = TextEditingController();
  _ModelGender _gender = _ModelGender.female;
  bool _submitted = false;
  bool _generated = false;

  @override
  void dispose() {
    _ageController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final age = int.tryParse(_ageController.text);
    final ageValid = age != null && age >= 18 && age <= 100;
    final description = _descriptionController.text.trim();
    final descriptionValid = description.length >= 10;
    final form = SingleChildScrollView(
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
            value: _gender,
            values: const [
              _ModelGender.female,
              _ModelGender.male,
              _ModelGender.nonBinary,
            ],
            labelFor: (value) => value.label,
            onChanged: (value) => setState(() => _gender = value),
          ),
          _TextFieldBlock(
            label: 'Age',
            required: true,
            controller: _ageController,
            keyboardType: TextInputType.number,
            invalid: _submitted && !ageValid,
            error: 'Age must be between 18 and 100.',
            onChanged: (_) => setState(() {}),
          ),
          _TextAreaBlock(
            controller: _descriptionController,
            invalid: _submitted && !descriptionValid,
            onChanged: (_) => setState(() {}),
          ),
          const _BenefitCard(),
          if (_generated) const _GenerationStatus(),
        ],
      ),
    );
    final generateAction = _ModelActionButton(
      key: const ValueKey('generate-ai-model'),
      label: _generated ? 'Generate another' : 'Generate model (20 credits)',
      icon: Icons.auto_awesome,
      full: true,
      onTap: () {
        setState(() => _submitted = true);
        if (age == null || !ageValid || !descriptionValid) return;
        widget.onGenerated(_gender, age, description);
        setState(() {
          _generated = true;
          _descriptionController.clear();
          _submitted = false;
        });
      },
    );

    if (widget.dialog) {
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
              _ModelActionButton.secondary(
                label: 'Close',
                full: true,
                onTap: () => Navigator.pop(context),
              ),
              generateAction,
            ],
          ),
        ],
      );
    }

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
              _ModelActionButton.secondary(
                label: 'Close',
                full: true,
                onTap: () => Navigator.pop(context),
              ),
              _ModelActionButton(
                key: const ValueKey('generate-ai-model'),
                label: _generated
                    ? 'Generate another'
                    : 'Generate model (20 credits)',
                icon: Icons.auto_awesome,
                full: true,
                onTap: () {
                  setState(() => _submitted = true);
                  if (age == null || !ageValid || !descriptionValid) return;
                  widget.onGenerated(_gender, age, description);
                  setState(() {
                    _generated = true;
                    _descriptionController.clear();
                    _submitted = false;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
