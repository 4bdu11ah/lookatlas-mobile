part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _VideoOptionsDialog extends StatefulWidget {
  const _VideoOptionsDialog({required this.onNext});

  final VoidCallback onNext;

  @override
  State<_VideoOptionsDialog> createState() => _VideoOptionsDialogState();
}

class _VideoOptionsDialogState extends State<_VideoOptionsDialog> {
  int _quality = 0;
  int _ratio = 0;
  int _variation = 0;

  @override
  Widget build(BuildContext context) {
    return _ModalFrame(
      title: 'Generate Model Video',
      subtitle: 'Choose quality, format, and variation',
      actions: [
        AppOutlinedButton(
          label: 'Cancel',
          onPressed: () => Navigator.pop(context),
        ),
        PrimaryButton(
          label: 'Next',
          icon: Icons.arrow_forward,
          iconAlignment: IconAlignment.end,
          onPressed: widget.onNext,
        ),
      ],
      children: [
        const _VideoStepProgress(currentStep: 1),
        const _FieldLabel('Choose quality'),
        Row(
          children: [
            Expanded(
              child: _VideoChoice(
                title: 'Video',
                body: 'Fast & clean',
                credits: '10 credits',
                active: _quality == 0,
                onTap: () => setState(() => _quality = 0),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _VideoChoice(
                title: 'Video HD',
                body: 'Best quality',
                credits: '25 credits',
                active: _quality == 1,
                onTap: () => setState(() => _quality = 1),
              ),
            ),
          ],
        ),
        const _FieldLabel('Aspect ratio'),
        _InteractiveSegmented(
          choices: const ['Portrait 9:16', 'Landscape 16:9'],
          selected: _ratio,
          onSelect: (index) => setState(() => _ratio = index),
        ),
        const _FieldLabel('Starting variation'),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 3,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 7,
            childAspectRatio: 0.72,
          ),
          itemBuilder: (context, index) => _VideoImageChoice(
            asset: _shotAssets[index],
            label: 'Variation ${index + 1}',
            active: _variation == index,
            onTap: () => setState(() => _variation = index),
          ),
        ),
      ],
    );
  }
}

class _VideoFrameDialog extends StatefulWidget {
  const _VideoFrameDialog({required this.onBack, required this.onNext});

  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  State<_VideoFrameDialog> createState() => _VideoFrameDialogState();
}

class _VideoFrameDialogState extends State<_VideoFrameDialog> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    const labels = [
      'Cafe Arrival',
      'Detail Moment',
      'Window Portrait',
      'Street Crossing',
    ];
    return _ModalFrame(
      title: 'Choose Starting Frame',
      subtitle: 'Pick which image from Variation 1 starts the video',
      actions: [
        AppOutlinedButton(
          label: 'Back',
          onPressed: widget.onBack,
        ),
        PrimaryButton(
          label: 'Next',
          icon: Icons.arrow_forward,
          iconAlignment: IconAlignment.end,
          onPressed: widget.onNext,
        ),
      ],
      children: [
        const _VideoStepProgress(currentStep: 2),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _shotAssets.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.75,
          ),
          itemBuilder: (context, index) => _VideoImageChoice(
            asset: _shotAssets[index],
            label: labels[index],
            active: _selected == index,
            onTap: () => setState(() => _selected = index),
          ),
        ),
      ],
    );
  }
}

class _VideoConfirmDialog extends StatelessWidget {
  const _VideoConfirmDialog({
    required this.onBack,
    required this.onToast,
  });

  final VoidCallback onBack;
  final ValueChanged<String> onToast;

  @override
  Widget build(BuildContext context) {
    return _ModalFrame(
      title: 'Almost There',
      subtitle: 'Review and confirm',
      actionFlexes: const [1, 3],
      actions: [
        KeyedSubtree(
          key: const ValueKey('video-confirm-back'),
          child: AppOutlinedButton(label: 'Back', onPressed: onBack),
        ),
        KeyedSubtree(
          key: const ValueKey('video-confirm-generate'),
          child: PrimaryButton(
            label: 'Generate Video · 10 Credits',
            fitToContent: true,
            icon: Icons.auto_awesome,
            onPressed: () {
              Navigator.pop(context);
              onToast('Video generation started');
            },
          ),
        ),
      ],
      children: const [
        _VideoStepProgress(currentStep: 3),
        _VideoSummary(),
        _Alert(
          kind: _AlertKind.warn,
          text:
              'AI video is still in early access. \nResults may vary — it sometimes takes 2-3 generations to get a great result. Credits are consumed per generation.',
        ),
      ],
    );
  }
}

class _VideoStepProgress extends StatelessWidget {
  const _VideoStepProgress({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        3,
        (index) => Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == 2 ? 0 : 6),
            child: Container(
              key: ValueKey('video-progress-${index + 1}'),
              height: 4,
              color: index < currentStep
                  ? AppColors.black
                  : AppColors.neutral200,
            ),
          ),
        ),
      ),
    );
  }
}

class _VideoChoice extends StatelessWidget {
  const _VideoChoice({
    required this.title,
    required this.body,
    required this.credits,
    required this.active,
    required this.onTap,
  });

  final String title;
  final String body;
  final String credits;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: active ? AppColors.neutral50 : AppColors.white,
          border: Border.all(
            color: active ? AppColors.black : AppColors.neutral200,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CardTitle(title),
            _Caption(body),
            const SizedBox(height: 8),
            Text(
              credits,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: AppTypography.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InteractiveSegmented extends StatelessWidget {
  const _InteractiveSegmented({
    required this.choices,
    required this.selected,
    required this.onSelect,
  });

  final List<String> choices;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        choices.length,
        (index) => Expanded(
          child: InkWell(
            onTap: () => onSelect(index),
            child: Container(
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: index == selected ? AppColors.black : AppColors.white,
                border: Border.all(color: AppColors.black),
              ),
              child: Text(
                choices[index],
                style: TextStyle(
                  color: index == selected ? AppColors.white : AppColors.black,
                  fontSize: 10,
                  fontWeight: AppTypography.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VideoImageChoice extends StatelessWidget {
  const _VideoImageChoice({
    required this.asset,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String asset;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: active ? AppColors.black : AppColors.neutral200,
            width: 2,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _AssetImage(asset),
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Text(
                label,
                maxLines: 2,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 9,
                  fontWeight: AppTypography.bold,
                  shadows: [Shadow(blurRadius: 5)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoSummary extends StatelessWidget {
  const _VideoSummary();

  @override
  Widget build(BuildContext context) {
    const rows = [
      ('Quality', 'Video'),
      ('Aspect Ratio', 'Portrait 9:16'),
      ('Variation', '1'),
      ('Cost', '10 credits'),
    ];
    return Container(
      padding: const EdgeInsets.all(12),
      color: AppColors.neutral100,
      child: Column(
        children: List.generate(
          rows.length,
          (index) => Padding(
            padding: EdgeInsets.only(
              top: index == rows.length - 1 ? 10 : 4,
              bottom: 4,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: _Caption(rows[index].$1)),
                const SizedBox(width: 12),
                Flexible(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _CardTitle(rows[index].$2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
