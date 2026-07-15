part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _TextFieldBlock extends StatelessWidget {
  const _TextFieldBlock({
    required this.label,
    required this.controller,
    required this.onChanged,
    this.required = false,
    this.hint,
    this.keyboardType,
    this.invalid = false,
    this.error = '',
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool required;
  final String? hint;
  final TextInputType? keyboardType;
  final bool invalid;
  final String error;

  @override
  Widget build(BuildContext context) {
    return _FieldShell(
      label: label,
      required: required,
      invalid: invalid,
      error: error,
      child: AppTextField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: onChanged,
        hintText: hint,
      ),
    );
  }
}

class _TextAreaBlock extends StatelessWidget {
  const _TextAreaBlock({
    required this.controller,
    required this.onChanged,
    required this.invalid,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool invalid;

  @override
  Widget build(BuildContext context) {
    return _FieldShell(
      label: 'Describe the model',
      required: true,
      invalid: invalid,
      error: 'Please add at least 10 characters.',
      footer: '${controller.text.length}/600',
      child: AppTextField(
        key: const ValueKey('ai-description'),
        controller: controller,
        minLines: 4,
        maxLines: 6,
        maxLength: 600,
        showCounter: false,
        onChanged: onChanged,
        hintText: 'Share vibe, hair, complexion, styling cues...',
      ),
    );
  }
}

class _SelectBlock<T> extends StatelessWidget {
  const _SelectBlock({
    required this.label,
    required this.value,
    required this.values,
    required this.labelFor,
    required this.onChanged,
    this.required = false,
  });

  final String label;
  final T value;
  final List<T> values;
  final String Function(T value) labelFor;
  final ValueChanged<T> onChanged;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return _FieldShell(
      label: label,
      required: required,
      child: AppDropdown<T>(
        value: value,
        values: values,
        labelFor: labelFor,
        onChanged: onChanged,
      ),
    );
  }
}

class _HeightBlock extends StatelessWidget {
  const _HeightBlock({
    required this.controller,
    required this.estimated,
    required this.invalid,
    required this.onEstimatedChanged,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool estimated;
  final bool invalid;
  final ValueChanged<bool> onEstimatedChanged;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return _FieldShell(
      label: 'Height',
      required: true,
      invalid: invalid,
      error: 'Enter a height between 100 and 250 cm.',
      footer: 'Typical range 150-200 cm. Check "Est." if approximate.',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppTextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    onChanged: onChanged,
                    hintText: '170',
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 54,
                  height: 45,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.neutral100,
                    border: Border.all(color: AppColors.neutral200),
                  ),
                  child: const Text(
                    'cm',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: AppTypography.bold,
                      color: AppColors.neutral500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: () => onEstimatedChanged(!estimated),
            child: Container(
              width: 86,
              height: 45,
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(color: AppColors.neutral200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 15,
                    height: 15,
                    decoration: BoxDecoration(
                      color: estimated ? AppColors.black : AppColors.white,
                      border: Border.all(color: AppColors.neutral250),
                    ),
                    child: estimated
                        ? const Icon(
                            Icons.check,
                            size: 11,
                            color: AppColors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: 7),
                  const Text(
                    'Est.',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: AppTypography.semiBold,
                      color: AppColors.neutral500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoUploadBlock extends StatelessWidget {
  const _PhotoUploadBlock({
    required this.count,
    required this.invalid,
    required this.onAdd,
    required this.onRemove,
  });

  final int count;
  final bool invalid;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return _FieldShell(
      label: 'Model Photos',
      required: true,
      invalid: invalid,
      error: 'Add at least one clear model photo.',
      trailingLabel: '($count/5)',
      child: Column(
        children: [
          InkWell(
            key: const ValueKey('model-photo-upload'),
            onTap: onAdd,
            child: AppDottedBorder(
              color: AppColors.neutral200,
              strokeWidth: 2,
              dotWidth: 8,
              gap: 6,
              child: Container(
                height: 132,
                width: double.infinity,
                alignment: Alignment.center,
                color: AppColors.white,
                padding: const EdgeInsets.all(8),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.file_upload_outlined,
                      size: 34,
                      color: AppColors.neutral500,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Click to upload photos',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: AppTypography.bold,
                        color: AppColors.black,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'PNG, JPG up to 10MB each',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.35,
                        color: AppColors.neutral500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (count > 0) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 132,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemExtent: 105,
                itemCount: count,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(right: 9),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const ColoredBox(
                        color: AppColors.neutral100,
                        child: _AssetImage('$_img/angle-example-front.png'),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: InkWell(
                          onTap: onRemove,
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: const BoxDecoration(
                              color: AppColors.inkAlpha80,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 13,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FieldShell extends StatelessWidget {
  const _FieldShell({
    required this.label,
    required this.child,
    this.required = false,
    this.invalid = false,
    this.error = '',
    this.footer,
    this.trailingLabel,
  });

  final String label;
  final Widget child;
  final bool required;
  final bool invalid;
  final String error;
  final String? footer;
  final String? trailingLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: AppTypography.bold,
                  color: AppColors.black,
                ),
              ),
              if (required)
                const Text(' *', style: TextStyle(color: AppColors.dangerDark)),
              const Spacer(),
              if (trailingLabel != null)
                Text(
                  trailingLabel!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.neutral500,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          child,
          if (footer != null || invalid)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                invalid ? error : footer!,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: invalid ? AppColors.dangerDark : AppColors.neutral500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BenefitCard extends StatelessWidget {
  const _BenefitCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.inkAlpha04,
        border: Border.all(color: AppColors.inkAlpha20),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 17, color: AppColors.black),
              SizedBox(width: 8),
              Text(
                "What you'll get",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: AppTypography.bold,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            '- 4 studio-ready angles: front, left, right, back\n- Consistent face, hair, skin tone, and body\n- Flat 20 credit charge for the full set',
            style: TextStyle(
              fontSize: 13,
              height: 1.55,
              color: AppColors.neutral800,
            ),
          ),
        ],
      ),
    );
  }
}

class _GenerationStatus extends StatelessWidget {
  const _GenerationStatus();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.neutral200),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Model generated',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: AppTypography.bold,
                    color: AppColors.black,
                  ),
                ),
              ),
              Text(
                '100%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: AppTypography.bold,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
          SizedBox(height: 3),
          Text(
            'Four angles were saved to Your Models.',
            style: TextStyle(fontSize: 11, color: AppColors.neutral500),
          ),
          SizedBox(height: 12),
          LinearProgressIndicator(
            value: 1,
            minHeight: 6,
            backgroundColor: AppColors.neutral100,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.black),
          ),
        ],
      ),
    );
  }
}
