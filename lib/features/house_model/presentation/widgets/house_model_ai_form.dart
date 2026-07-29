part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _AiModelSheet extends StatefulWidget {
  const _AiModelSheet({required this.onGenerated, this.dialog = false});

  final Future<bool> Function(
    _ModelGender gender,
    int age,
    String description,
  )
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
  bool _generating = false;

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
    setState(() => _submitted = true);
    if (age == null || !ageValid || description.length < 10) return;
    setState(() => _generating = true);
    final generated = await widget.onGenerated(_gender, age, description);
    if (!mounted) return;
    setState(() {
      _generating = false;
      if (!generated) return;
      _generated = true;
      _descriptionController.clear();
      _submitted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final age = int.tryParse(_ageController.text);
    final ageValid = age != null && age >= 18 && age <= 100;
    final description = _descriptionController.text.trim();
    final form = _buildForm(ageValid, description.length >= 10);
    final action = _ModelActionButton(
      key: const ValueKey('generate-ai-model'),
      label: _generated ? 'Generate another' : 'Generate model (20 credits)',
      icon: Icons.auto_awesome,
      full: true,
      isLoading: _generating,
      onTap: () => unawaited(_generate(age, ageValid, description)),
    );
    return widget.dialog
        ? _buildDialog(form, action)
        : _buildBottomSheet(form, action);
  }

  Widget _buildForm(bool ageValid, bool descriptionValid) {
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
            _ModelActionButton.secondary(
              label: 'Close',
              full: true,
              onTap: () => Navigator.pop(context),
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
              _ModelActionButton.secondary(
                label: 'Close',
                full: true,
                onTap: () => Navigator.pop(context),
              ),
              action,
            ],
          ),
        ],
      ),
    );
  }
}
