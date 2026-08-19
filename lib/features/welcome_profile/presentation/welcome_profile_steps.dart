part of 'welcome_profile_screen.dart';

class _ProfileProgress extends StatelessWidget {
  const _ProfileProgress({required this.step});
  final int step;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'WELCOME TO LOOK ATLAS',
          style: TextStyle(
            color: AppColors.neutral500,
            fontSize: 10,
            fontWeight: AppTypography.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 20),
        Semantics(
          label: 'Step ${step + 1} of 4',
          child: Row(
            children: [
              for (var index = 0; index < 4; index++) ...[
                Expanded(
                  child: SizedBox(
                    height: 3,
                    child: ColoredBox(
                      color: index <= step
                          ? AppColors.black
                          : AppColors.neutral200,
                    ),
                  ),
                ),
                if (index != 3) const SizedBox(width: 6),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

class _BrandStep extends StatelessWidget {
  const _BrandStep({
    required this.brandController,
    required this.verticalController,
    required this.urlFocus,
    required this.showUrlError,
    required this.onChanged,
  });

  final TextEditingController brandController;
  final TextEditingController verticalController;
  final FocusNode urlFocus;
  final bool showUrlError;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => _Question(
    titleStart: 'Where does your ',
    emphasis: 'brand',
    titleEnd: ' live?',
    body: 'We tune your shoots to what you sell.',
    child: Column(
      children: [
        Semantics(
          label: 'Store URL',
          textField: true,
          child: AppTextField(
            controller: brandController,
            focusNode: urlFocus,
            hintText: 'Store URL (yourstore.com)',
            keyboardType: TextInputType.url,
            validator: (_) =>
                showUrlError ? 'Enter a web address like yourstore.com' : null,
            autovalidateMode: AutovalidateMode.always,
            onChanged: (_) => onChanged(),
          ),
        ),
        const SizedBox(height: 12),
        Semantics(
          label: 'What do you sell?',
          textField: true,
          child: AppTextField(
            controller: verticalController,
            hintText: 'What do you sell? Jewelry, dresses, bags...',
            textInputAction: TextInputAction.done,
            onChanged: (_) => onChanged(),
          ),
        ),
      ],
    ),
  );
}

class _UsesStep extends StatelessWidget {
  const _UsesStep({required this.selected, required this.onToggle});
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  static const List<(String, IconData, String, String)> _options = [
    (
      'product_pages',
      LucideIcons.store,
      'Product pages',
      'Clean shots for your store.',
    ),
    ('ads', LucideIcons.megaphone, 'Ads', 'Scroll-stopping creative.'),
    (
      'social',
      LucideIcons.sparkles,
      'Social',
      'Posts and stories.',
    ),
    (
      'lookbook',
      LucideIcons.images,
      'Lookbook',
      'A full campaign look.',
    ),
  ];

  @override
  Widget build(BuildContext context) => _Question(
    titleStart: 'What will you use your ',
    emphasis: 'shoots',
    titleEnd: ' for?',
    body: 'Pick all that apply. We start you with the right look.',
    child: Column(
      children: [
        for (final option in _options) ...[
          ProfileUseCard(
            icon: option.$2,
            title: option.$3,
            subtitle: option.$4,
            selected: selected.contains(option.$1),
            onPressed: () => onToggle(option.$1),
          ),
          if (option != _options.last) const SizedBox(height: 12),
        ],
      ],
    ),
  );
}

class _CadenceStep extends StatelessWidget {
  const _CadenceStep({required this.selected, required this.onSelected});
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => _Question(
    titleStart: 'How do you ',
    emphasis: 'release',
    titleEnd: '?',
    body: 'This shapes how we plan your shoots.',
    child: Column(
      children: [
        ProfileUseCard(
          icon: LucideIcons.package,
          title: 'One collection for now',
          subtitle: 'A catalog to shoot, start to finish.',
          selected: selected == 'one_collection',
          mutuallyExclusive: true,
          onPressed: () => onSelected('one_collection'),
        ),
        const SizedBox(height: 12),
        ProfileUseCard(
          icon: LucideIcons.repeat,
          title: 'Ongoing drops',
          subtitle: 'New pieces landing all the time.',
          selected: selected == 'ongoing_drops',
          mutuallyExclusive: true,
          onPressed: () => onSelected('ongoing_drops'),
        ),
      ],
    ),
  );
}

class _ReferralStep extends StatelessWidget {
  const _ReferralStep({
    required this.selected,
    required this.otherController,
    required this.onSelected,
  });

  final String? selected;
  final TextEditingController otherController;
  final ValueChanged<String> onSelected;

  static const _options = [
    ('instagram_facebook', 'Instagram or Facebook'),
    ('google', 'Google'),
    ('tiktok', 'TikTok'),
    ('youtube', 'YouTube'),
    ('friend', 'A friend or another brand'),
    ('email', 'An email from us'),
    ('other', 'Somewhere else'),
  ];

  @override
  Widget build(BuildContext context) => _Question(
    titleStart: 'Where did you ',
    emphasis: 'find',
    titleEnd: ' us?',
    body: 'One tap. It helps us show up in the right places.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in _options)
              Semantics(
                checked: selected == option.$1,
                inMutuallyExclusiveGroup: true,
                button: true,
                child: _ProfileChip(
                  label: option.$2,
                  selected: selected == option.$1,
                  onPressed: () => onSelected(option.$1),
                ),
              ),
          ],
        ),
        if (selected == 'other') ...[
          const SizedBox(height: 18),
          Semantics(
            label: 'Tell us where',
            textField: true,
            child: AppTextField(
              controller: otherController,
              autofocus: true,
              hintText: 'Tell us where',
            ),
          ),
        ],
      ],
    ),
  );
}

class _Question extends StatelessWidget {
  const _Question({
    required this.titleStart,
    required this.emphasis,
    required this.titleEnd,
    required this.body,
    required this.child,
  });

  final String titleStart;
  final String emphasis;
  final String titleEnd;
  final String body;
  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(
          TextSpan(
            text: titleStart,
            children: [
              TextSpan(
                text: emphasis,
                style: const TextStyle(
                  fontFamily: 'Georgia',
                  fontStyle: FontStyle.italic,
                  fontWeight: AppTypography.regular,
                ),
              ),
              TextSpan(text: titleEnd),
            ],
          ),
          style: const TextStyle(
            color: AppColors.black,
            fontSize: 34,
            height: 1.03,
            letterSpacing: -1.36,
            fontWeight: AppTypography.bold,
          ),
        ),
        const SizedBox(height: 10),
        Text(body, style: const TextStyle(color: AppColors.neutral500)),
        const SizedBox(height: 24),
        child,
      ],
    ),
  );
}
