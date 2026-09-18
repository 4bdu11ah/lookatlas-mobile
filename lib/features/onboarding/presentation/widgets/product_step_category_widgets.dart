part of 'steps/product_step.dart';

/// Pixel-perfect Category Selection Screen ("What are you shooting?").
/// First screen of the free-shoot onboarding wizard directly after signup.
/// Pure Riverpod (zero setState): watches [wizardControllerProvider] for
/// selections and triggers controller actions.
class _CategoryPicker extends ConsumerWidget {
  const _CategoryPicker({
    this.onContinue,
    this.onBack,
  });

  final VoidCallback? onContinue;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    return isWide
        ? _CategoryWideLayout(onContinue: onContinue, onBack: onBack)
        : _CategoryPhoneLayout(onContinue: onContinue, onBack: onBack);
  }
}

// =============================================================================
// Phone Layout (< 900px)
// =============================================================================

class _CategoryPhoneLayout extends ConsumerWidget {
  const _CategoryPhoneLayout({
    required this.onContinue,
    required this.onBack,
  });

  final VoidCallback? onContinue;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(wizardControllerProvider);
    final selectedCategory = state.category;
    final activeFilter = state.categoryFilter;
    final filteredCategories = ProductCategory.values
        .where(activeFilter.matches)
        .toList();

    return Stack(
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Centered "LOOK ATLAS" branding
                Text(
                  'LOOK ATLAS',
                  textAlign: TextAlign.center,
                  style: AppTypography.sfPro(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: const Color(0xFF0F0F0F),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 20),

                // "CATEGORY" + "Step 1 of 7"
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'CATEGORY',
                      style: AppTypography.sfPro(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: const Color(0xFF0F0F0F),
                        height: 1.2,
                      ),
                    ),
                    Text(
                      'Step 1 of 7',
                      style: AppTypography.sfPro(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF6B6B6B),
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 7-segment progress indicator
                const _SevenSegmentProgressBar(),
                const SizedBox(height: 24),

                // "What are you shooting?" headline
                const _HeadlineTitle(),
                const SizedBox(height: 8),

                // Subtitle
                Text(
                  'This helps us show you the best way to photograph your product.',
                  style: AppTypography.sfPro(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF6B6B6B),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),

                // Filter chips (All, Apparel, Accessories, Footwear, Other)
                _FilterChipsBar(
                  activeFilter: activeFilter,
                  onSelectFilter: (f) => ref
                      .read(wizardControllerProvider.notifier)
                      .setCategoryFilter(f),
                ),
                const SizedBox(height: 16),

                // 2-column Category Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 175 / 208,
                  ),
                  itemCount: filteredCategories.length,
                  itemBuilder: (context, index) {
                    final cat = filteredCategories[index];
                    return _CategoryCard(
                      category: cat,
                      selected: selectedCategory == cat,
                      onTap: () => ref
                          .read(wizardControllerProvider.notifier)
                          .selectCategory(cat),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Product Preview Hero Card (woman model showcase)
                const _ProductPreviewHeroCard(),
              ],
            ),
          ),
        ),

        // Bottom floating glass navigation bar
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top border line
              Container(
                height: 1,
                color: const Color(0x33B0B0B0),
              ),
              Container(
                height: 72,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.fromRGBO(255, 255, 255, 0),
                      Color.fromRGBO(255, 255, 255, 0.95),
                    ],
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _CategoryBackButton(onTap: onBack),
                      _CategoryContinueButton(
                        enabled: selectedCategory != null,
                        onTap: onContinue,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Tablet / Desktop Layout (>= 900px)
// =============================================================================

class _CategoryWideLayout extends ConsumerWidget {
  const _CategoryWideLayout({
    required this.onContinue,
    required this.onBack,
  });

  final VoidCallback? onContinue;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(wizardControllerProvider);
    final selectedCategory = state.category;
    final activeFilter = state.categoryFilter;
    final filteredCategories = ProductCategory.values
        .where(activeFilter.matches)
        .toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left Column: Step Navigation Sidebar
        const SizedBox(
          width: 220,
          child: _WideStepSidebar(),
        ),

        // Center Column: Category Selection Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'STEP 01 • SELECT CATEGORY',
                  style: AppTypography.sfPro(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: const Color(0xFF0F0F0F),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                const _HeadlineTitle(),
                const SizedBox(height: 8),
                Text(
                  'This helps us show you the best way to photograph your product.',
                  style: AppTypography.sfPro(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF6B6B6B),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 24),

                // Filter chips
                _FilterChipsBar(
                  activeFilter: activeFilter,
                  onSelectFilter: (f) => ref
                      .read(wizardControllerProvider.notifier)
                      .setCategoryFilter(f),
                ),
                const SizedBox(height: 24),

                // Responsive Category Grid (up to 4 columns matching screen width)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cols = (constraints.maxWidth / 160).floor().clamp(
                      2,
                      4,
                    );
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 175 / 208,
                      ),
                      itemCount: filteredCategories.length,
                      itemBuilder: (context, index) {
                        final cat = filteredCategories[index];
                        return _CategoryCard(
                          category: cat,
                          selected: selectedCategory == cat,
                          onTap: () => ref
                              .read(wizardControllerProvider.notifier)
                              .selectCategory(cat),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 36),

                // Back button pinned at bottom-left of content
                _CategoryBackButton(onTap: onBack),
              ],
            ),
          ),
        ),

        // Right Column: Full-height Hero Preview Panel with Continue CTA
        SizedBox(
          width: 360,
          child: _WideHeroPanel(
            enabled: selectedCategory != null,
            onContinue: onContinue,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Shared UI Components
// =============================================================================

class _HeadlineTitle extends StatelessWidget {
  const _HeadlineTitle();

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'What are you ',
            style: AppTypography.sfPro(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F0F0F),
              height: 1.18,
            ),
          ),
          TextSpan(
            text: 'shooting?',
            style: AppTypography.sfPro(
              fontSize: 32,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF9E9E9E),
              height: 1.18,
            ),
          ),
        ],
      ),
    );
  }
}

/// 7-segment progress bar for mobile view matching Figma.
class _SevenSegmentProgressBar extends StatelessWidget {
  const _SevenSegmentProgressBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < 7; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: i == 0
                    ? const Color(0xFF0F0F0F)
                    : const Color(0xFFE3E3E3),
                borderRadius: BorderRadius.circular(1),
                boxShadow: i == 0
                    ? const [
                        BoxShadow(
                          color: Color(0x26000000),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                        BoxShadow(
                          color: Color(0x4D000000),
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Filter chips row: All, Apparel, Accessories, Footwear, Other.
class _FilterChipsBar extends StatelessWidget {
  const _FilterChipsBar({
    required this.activeFilter,
    required this.onSelectFilter,
  });

  final CategoryFilter activeFilter;
  final ValueChanged<CategoryFilter> onSelectFilter;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in CategoryFilter.values) ...[
            _FilterChip(
              label: filter.label,
              selected: activeFilter == filter,
              onTap: () => onSelectFilter(filter),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 40,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0F0F0F) : const Color(0xFFFCFCFC),
          border: Border.all(
            color: selected ? const Color(0xFF0F0F0F) : const Color(0x4DE3E3E3),
          ),
          borderRadius: BorderRadius.circular(4),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x4D000000),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                  BoxShadow(
                    color: Color(0x26000000),
                    blurRadius: 6,
                    spreadRadius: 2,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: AppTypography.sfPro(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : const Color(0xFF525252),
            height: 1.17,
          ),
        ),
      ),
    );
  }
}

/// Pixel-perfect Category Card matching Figma CSS.
class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final ProductCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected ? null : const Color(0xFFF5F5F5),
          gradient: selected
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFE6E6E6),
                    Color(0xFFC3C1C1),
                  ],
                )
              : null,
          border: Border.all(color: const Color(0x4DE3E3E3)),
          borderRadius: BorderRadius.circular(4),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x03000000),
                    blurRadius: 37,
                    offset: Offset(0, 92),
                  ),
                  BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 31,
                    offset: Offset(0, 51),
                  ),
                  BoxShadow(
                    color: Color(0x17000000),
                    blurRadius: 23,
                    offset: Offset(0, 23),
                  ),
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 13,
                    offset: Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            // Center Image Section
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: category == ProductCategory.other
                      ? const _LayersIcon()
                      : Image.asset(
                          category.imageUrl,
                          width: 140,
                          height: 140,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const _LayersIcon(),
                        ),
                ),
              ),
            ),

            // Bottom Tag row: Label on left, arrow or check badge on right
            Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      category.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.sfPro(
                        fontSize: 14,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: selected
                            ? const Color(0xFF0F0F0F)
                            : const Color(0xFF525252),
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (selected)
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0F0F0F),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x26000000),
                            blurRadius: 13,
                            spreadRadius: 5,
                            offset: Offset(0, 8),
                          ),
                          BoxShadow(
                            color: Color(0x4D000000),
                            blurRadius: 4,
                            offset: Offset(0, 2.6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 14,
                        color: Colors.white,
                      ),
                    )
                  else
                    const Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: Color(0xFF6B6B6B),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Three stacked isometric diamond outlines matching `clarity:layers-line`.
class _LayersIcon extends StatelessWidget {
  const _LayersIcon();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      size: Size(56, 56),
      painter: _LayersPainter(color: Color(0xFFB0B0B0)),
    );
  }
}

class _LayersPainter extends CustomPainter {
  const _LayersPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // Top diamond
    final top = Path()
      ..moveTo(w * 0.5, h * 0.15)
      ..lineTo(w * 0.88, h * 0.32)
      ..lineTo(w * 0.5, h * 0.49)
      ..lineTo(w * 0.12, h * 0.32)
      ..close();
    canvas.drawPath(top, paint);

    // Middle chevron
    final mid = Path()
      ..moveTo(w * 0.12, h * 0.50)
      ..lineTo(w * 0.5, h * 0.67)
      ..lineTo(w * 0.88, h * 0.50);
    canvas.drawPath(mid, paint);

    // Bottom chevron
    final btm = Path()
      ..moveTo(w * 0.12, h * 0.68)
      ..lineTo(w * 0.5, h * 0.85)
      ..lineTo(w * 0.88, h * 0.68);
    canvas.drawPath(btm, paint);
  }

  @override
  bool shouldRepaint(_LayersPainter oldDelegate) => oldDelegate.color != color;
}

/// Product preview hero card at the bottom of the mobile view.
class _ProductPreviewHeroCard extends StatelessWidget {
  const _ProductPreviewHeroCard();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 450,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              AppAssets.categoryHero,
              fit: BoxFit.cover,
            ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.68, 1.0],
                  colors: [
                    Color.fromRGBO(0, 0, 0, 0.1),
                    Color.fromRGBO(0, 0, 0, 0.9),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 32,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Studio quality outputs.\nFor every product.',
                    style: AppTypography.sfPro(
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const _DotIndicators(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DotIndicators extends StatelessWidget {
  const _DotIndicators();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            color: Color(0xFFF5F5F5),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFFB0B0B0),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFFB0B0B0),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFFB0B0B0),
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}

/// Back button matching Figma specifications.
class _CategoryBackButton extends StatelessWidget {
  const _CategoryBackButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 109,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE3E3E3), width: 2),
          borderRadius: BorderRadius.circular(4),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.arrow_back,
              size: 14,
              color: Color(0xFF6B6B6B),
            ),
            const SizedBox(width: 8),
            Text(
              'BACK',
              style: AppTypography.sfPro(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6B6B6B),
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Continue CTA button matching Figma specifications.
class _CategoryContinueButton extends StatelessWidget {
  const _CategoryContinueButton({
    required this.enabled,
    required this.onTap,
  });

  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 150,
        height: 36,
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFF0F0F0F) : const Color(0xFFB0B0B0),
          borderRadius: BorderRadius.circular(4),
          boxShadow: enabled
              ? const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 7,
                    offset: Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'CONTINUE',
              style: AppTypography.sfPro(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
                height: 1.2,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward,
              size: 14,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}

/// Tablet / iPad Sidebar showing 7 vertical steps and progress.
class _WideStepSidebar extends StatelessWidget {
  const _WideStepSidebar();

  @override
  Widget build(BuildContext context) {
    final steps = [
      ('Category', 'Select product category', true),
      ('Product', '', false),
      ('Model', '', false),
      ('Director', '', false),
      ('Confirm', '', false),
      ('Photoshoot', '', false),
      ('Overview', '', false),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Color(0xFFE3E3E3)),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          Text(
            'LOOK ATLAS',
            style: AppTypography.sfPro(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: const Color(0xFF0F0F0F),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 48),

          // 7 Vertical Stepper items
          for (int i = 0; i < steps.length; i++) ...[
            _SidebarStepRow(
              index: i + 1,
              title: steps[i].$1,
              subtitle: steps[i].$2,
              isActive: steps[i].$3,
              isLast: i == steps.length - 1,
            ),
          ],

          const Spacer(),

          // Bottom sidebar progress indicator
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: const Color(0xFFE3E3E3),
              borderRadius: BorderRadius.circular(1.5),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 1 / 7,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0F0F0F),
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Step 1 of 7 - about 6 minutes',
            style: AppTypography.sfPro(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF6B6B6B),
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarStepRow extends StatelessWidget {
  const _SidebarStepRow({
    required this.index,
    required this.title,
    required this.subtitle,
    required this.isActive,
    required this.isLast,
  });

  final int index;
  final String title;
  final String subtitle;
  final bool isActive;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF0F0F0F) : Colors.transparent,
                shape: BoxShape.circle,
                border: isActive
                    ? null
                    : Border.all(color: const Color(0xFFE3E3E3)),
              ),
              child: Center(
                child: isActive
                    ? const Icon(
                        Icons.more_horiz,
                        size: 14,
                        color: Colors.white,
                      )
                    : index == 6
                    ? const Icon(
                        Icons.camera_alt_outlined,
                        size: 12,
                        color: Color(0xFF6B6B6B),
                      )
                    : Text(
                        index.toString().padLeft(2, '0'),
                        style: AppTypography.sfPro(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF6B6B6B),
                          height: 1.1,
                        ),
                      ),
              ),
            ),
            if (!isLast)
              Container(
                width: 1,
                height: subtitle.isNotEmpty ? 40 : 28,
                color: const Color(0xFFE3E3E3),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Text(
                title,
                style: AppTypography.sfPro(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                  color: isActive
                      ? const Color(0xFF0F0F0F)
                      : const Color(0xFF6B6B6B),
                  height: 1.2,
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: AppTypography.sfPro(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF6B6B6B),
                    height: 1.2,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Tablet / iPad Right Hero Showcase Panel.
class _WideHeroPanel extends StatelessWidget {
  const _WideHeroPanel({
    required this.enabled,
    required this.onContinue,
  });

  final bool enabled;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          AppAssets.categoryHero,
          fit: BoxFit.cover,
        ),
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.65, 1.0],
              colors: [
                Color.fromRGBO(0, 0, 0, 0.05),
                Color.fromRGBO(0, 0, 0, 0.9),
              ],
            ),
          ),
        ),
        Positioned(
          left: 24,
          right: 24,
          bottom: 32,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Studio quality outputs.\nFor every product.',
                style: AppTypography.sfPro(
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const _DotIndicators(),
                  _CategoryContinueButton(
                    enabled: enabled,
                    onTap: onContinue,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// --- States B/C: photo upload ------------------------------------------------

class _PhotoUpload extends ConsumerWidget {
  const _PhotoUpload({
    required this.state,
    required this.isSavingProduct,
    required this.onAddPhotos,
  });

  final WizardState state;
  final bool isSavingProduct;
  final VoidCallback onAddPhotos;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final category = state.category?.label.toLowerCase() ?? 'product';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 24,
        children: [
          WizardStepHeader(
            title: 'Upload your $category photos',
            subtitle:
                'More photos from different sides help our AI recreate your '
                'product accurately. Upload up to $maxWizardPhotos.',
          ),
          _AngleGuidance(category: state.category),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              CheckLine('White or plain background'),
              CheckLine('Show the full product'),
              CheckLine('Capture logos and unique details'),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 16,
              children: [
                Text(
                  'Your photos',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.43,
                    fontWeight: AppTypography.medium,
                    color: scheme.onSurface,
                  ),
                ),
                if (state.addingPhotos || isSavingProduct)
                  const _UploadingIndicator()
                else if (state.photos.isEmpty)
                  _DropZone(onTap: onAddPhotos)
                else
                  _PhotoGrid(state: state, onAddPhotos: onAddPhotos),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AngleGuidance extends StatelessWidget {
  const _AngleGuidance({required this.category});

  final ProductCategory? category;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Category-specific example shots (e.g. shoes: Front/Side/Top).
    final guides = (category ?? ProductCategory.other).angleGuides;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        Text(
          'For best results, capture these sides',
          style: TextStyle(
            fontSize: 16,
            height: 1.5,
            fontWeight: AppTypography.medium,
            color: scheme.onSurface,
          ),
        ),
        Row(
          spacing: 12,
          children: [
            for (final (label, asset) in guides)
              Expanded(
                child: Column(
                  spacing: 8,
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: scheme.outline),
                        ),
                        child: ShotImage(asset),
                      ),
                    ),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.43,
                        fontWeight: AppTypography.medium,
                        color: scheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        Text(
          "Don't have all of these? No worries, upload what you have.",
          style: TextStyle(
            fontSize: 14,
            height: 1.43,
            color: scheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

class _UploadingIndicator extends StatelessWidget {
  const _UploadingIndicator();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 160,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            const BarSpinner(size: 28),
            Text(
              'Uploading your photos...',
              style: TextStyle(
                fontSize: 14,
                height: 1.43,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The empty full-square drop target (mockup state C).
class _DropZone extends StatelessWidget {
  const _DropZone({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: DashedBorder(
        color: scheme.onSurface.withValues(alpha: 0.2),
        child: AspectRatio(
          aspectRatio: 1,
          child: ColoredBox(
            color: scheme.surface.withValues(alpha: 0.5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: scheme.onSurface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.upload, size: 28, color: scheme.surface),
                ),
                const SizedBox(height: 12),
                Text(
                  'Tap to add photos',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.4,
                    fontWeight: AppTypography.semiBold,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'JPG or PNG, up to 10MB',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: scheme.onSurface.withValues(alpha: 0.5),
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
