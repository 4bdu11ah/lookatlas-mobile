part of '../screens/workshop_screen.dart';

class _WorkshopHeader extends StatelessWidget {
  const _WorkshopHeader({required this.onShowGuide});

  final VoidCallback onShowGuide;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reshape any photo with a sentence. Swap a face, recolor a product, '
          'drop a new model into the same shot. 1 credit per generation.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            height: 20 / 14,
            color: AppColors.neutral500,
          ),
        ),
        const SizedBox(height: 8),
        _WorkshopOutlineButton(
          icon: Icons.help_outline,
          label: 'HOW DOES THIS WORK?',
          height: 34,
          compact: true,
          onTap: onShowGuide,
        ),
      ],
    );
  }
}

class _WorkshopEditorActions {
  const _WorkshopEditorActions({
    required this.pickBase,
    required this.removeBase,
    required this.changeMode,
    required this.addReference,
    required this.removeReference,
    required this.changePrompt,
    required this.generate,
    required this.retry,
  });

  final VoidCallback pickBase;
  final VoidCallback removeBase;
  final ValueChanged<WorkshopEditMode> changeMode;
  final VoidCallback addReference;
  final ValueChanged<String> removeReference;
  final ValueChanged<String> changePrompt;
  final VoidCallback generate;
  final VoidCallback retry;
}

class _WorkshopEditor extends StatelessWidget {
  const _WorkshopEditor({
    required this.state,
    required this.isPremium,
    required this.promptController,
    required this.actions,
  });

  final WorkshopState state;
  final bool isPremium;
  final TextEditingController promptController;
  final _WorkshopEditorActions actions;

  @override
  Widget build(BuildContext context) {
    final error = state.validationMessage ?? state.failure?.message;
    final busy = state.isGenerating;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IgnorePointer(
          ignoring: busy,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: busy ? 0.5 : 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BaseImageField(
                  image: state.baseImage,
                  onPick: actions.pickBase,
                  onRemove: actions.removeBase,
                ),
                if (state.hasBaseImage) ...[
                  const SizedBox(height: 16),
                  _ModePicker(
                    selected: state.editMode,
                    onChanged: actions.changeMode,
                  ),
                ],
                const SizedBox(height: 16),
                _ReferenceField(
                  references: state.references,
                  onAdd: actions.addReference,
                  onRemove: actions.removeReference,
                ),
                const SizedBox(height: 16),
                _PromptField(
                  controller: promptController,
                  onChanged: actions.changePrompt,
                ),
              ],
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 16),
          _WorkshopErrorBox(message: error),
          if (state.failure != null && state.history.isEmpty) ...[
            const SizedBox(height: 8),
            _WorkshopOutlineButton(
              icon: Icons.refresh,
              label: 'TRY AGAIN',
              height: 34,
              compact: true,
              onTap: actions.retry,
            ),
          ],
        ],
        const SizedBox(height: 16),
        _GenerateButton(
          locked: !isPremium,
          starting: state.isStarting,
          processing: state.isProcessing,
          enabled: isPremium && state.canGenerate,
          onTap: actions.generate,
        ),
      ],
    );
  }
}

class _ReferenceField extends StatelessWidget {
  const _ReferenceField({
    required this.references,
    required this.onAdd,
    required this.onRemove,
  });

  final List<WorkshopSample> references;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final showAdd = references.length < 4;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _WorkshopFieldLabel(
          title: 'Reference images',
          optional: '(optional, up to 4)',
          tooltip:
              'Optional. The AI uses these as visual inspiration alongside your base. Useful for compositing.',
        ),
        const SizedBox(height: 8),
        Container(
          height: 106,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.neutral100Alpha30,
            border: Border.all(color: AppColors.neutral200),
          ),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: references.length + (showAdd ? 1 : 0),
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              if (index == references.length) {
                return _ReferenceAddTile(onTap: onAdd);
              }
              final reference = references[index];
              return _ReferenceTile(
                reference: reference,
                onRemove: () => onRemove(reference.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ReferenceAddTile extends StatelessWidget {
  const _ReferenceAddTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: const Key('workshop-reference-add-button'),
      onTap: onTap,
      child: const AppDottedBorder(
        strokeWidth: 2,
        child: SizedBox(
          width: 80,
          height: 80,
          child: Icon(Icons.add, size: 20, color: AppColors.neutral500),
        ),
      ),
    );
  }
}

class _ReferenceTile extends StatelessWidget {
  const _ReferenceTile({required this.reference, required this.onRemove});

  final WorkshopSample reference;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 80,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: AppImage.memory(reference.bytes, fit: BoxFit.cover),
          ),
          Positioned(
            top: -8,
            right: -8,
            child: _WorkshopIconButton(
              icon: Icons.close,
              label: 'Remove ${reference.label}',
              onTap: onRemove,
              dark: true,
              dimension: 20,
              iconSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _PromptField extends StatelessWidget {
  const _PromptField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _WorkshopFieldLabel(title: 'Prompt', isRequired: true),
        const SizedBox(height: 8),
        AppTextField(
          fieldKey: const Key('workshop-prompt-field'),
          controller: controller,
          onChanged: onChanged,
          minLines: 5,
          maxLines: 5,
          maxLength: WorkshopState.maxPromptLength,
          maxLengthEnforcement: MaxLengthEnforcement.none,
          showCounter: false,
          textStyle: const TextStyle(fontSize: 16, height: 20 / 16),
          hintText:
              "Describe the edit. e.g. 'place the watch from image 2 on the model's wrist, keep the studio lighting'.",
          hintStyle: const TextStyle(fontSize: 14, height: 20 / 14),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, value, _) => Text(
              '${value.text.length} / ${WorkshopState.maxPromptLength}',
              style: TextStyle(
                fontSize: 12,
                height: 16 / 12,
                color: value.text.length > WorkshopState.maxPromptLength
                    ? AppColors.dangerDark
                    : AppColors.neutral500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GenerateButton extends StatelessWidget {
  const _GenerateButton({
    required this.locked,
    required this.starting,
    required this.processing,
    required this.enabled,
    required this.onTap,
  });

  final bool locked;
  final bool starting;
  final bool processing;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final busy = starting || processing;
    final available = enabled && !busy;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: available || starting ? 1 : 0.5,
          child: DecoratedBox(
            decoration: BoxDecoration(
              boxShadow: available
                  ? const [
                      BoxShadow(
                        color: AppColors.blackAlpha20,
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ]
                  : null,
            ),
            child: PrimaryButton(
              key: const Key('workshop-generate-button'),
              label: 'Generate',
              onPressed: busy ? null : onTap,
              isLoading: starting,
              backgroundColor: AppColors.black,
              foregroundColor: AppColors.white,
              loadingChild: const ButtonLoader(
                text: 'Starting…',
                color: AppColors.white,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome_outlined,
                    size: 16,
                    color: AppColors.white,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Generate',
                    style: TextStyle(
                      fontSize: 14,
                      height: 20 / 14,
                      fontWeight: AppTypography.semiBold,
                      color: AppColors.white,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    '— 1 credit',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.whiteAlpha70,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (locked)
          const Positioned(
            top: -4,
            right: -4,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.black,
                border: Border.fromBorderSide(
                  BorderSide(color: AppColors.white, width: 2),
                ),
              ),
              child: SizedBox.square(
                dimension: 20,
                child: Icon(
                  Icons.lock_outline,
                  size: 11,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
