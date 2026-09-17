part of '../screens/shoots_page.dart';

const _shootInk = Color(0xFF181816);
const _shootPaper = Color(0xFFFFFEFA);
const _shootWash = Color(0xFFF2F1EB);
const _shootLine = Color(0xFFD9D8D0);
const _shootMuted = Color(0xFF6F6F68);
const _shootLive = Color(0xFF2E7D32);
const _shootWarning = Color(0xFF8A612D);

class _OverviewHeader extends StatelessWidget {
  const _OverviewHeader();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _EditorialEyebrow('Production Archive'),
      SizedBox(height: 4),
      Text(
        'Shoots',
        style: TextStyle(
          color: _shootInk,
          fontFamily: 'InstrumentSerif',
          fontSize: 36,
          height: .98,
          letterSpacing: -1.2,
        ),
      ),
      SizedBox(height: 8),
      Text(
        'Every campaign, from the first generated frame to your final selection.',
        style: TextStyle(color: _shootMuted, fontSize: 12, height: 1.6),
      ),
    ],
  );
}

class _EditorialEyebrow extends StatelessWidget {
  const _EditorialEyebrow(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label.toUpperCase(),
    style: const TextStyle(
      color: _shootMuted,
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.4,
      height: 1.2,
    ),
  );
}

class _OverviewSectionHeader extends StatelessWidget {
  const _OverviewSectionHeader({
    required this.index,
    required this.eyebrow,
    required this.title,
    required this.count,
  });

  final String index;
  final String eyebrow;
  final String title;
  final String count;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.only(top: 12, bottom: 16),
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: _shootLine)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 32,
          child: Text(
            index,
            style: const TextStyle(
              color: _shootMuted,
              fontFamily: 'InstrumentSerif',
              fontSize: 18,
              fontStyle: FontStyle.italic,
              height: 1,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _EditorialEyebrow(eyebrow),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(
                  color: _shootInk,
                  fontFamily: 'InstrumentSerif',
                  fontSize: 24,
                  height: 1.05,
                  letterSpacing: -.6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            count.toUpperCase(),
            style: const TextStyle(
              color: _shootMuted,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: .9,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ReadyShootCard extends StatelessWidget {
  const _ReadyShootCard({required this.shoot, required this.onTap});

  final ShootViewModel shoot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final images = _galleryAssets(shoot);
    return Container(
      decoration: BoxDecoration(
        color: _shootPaper,
        border: Border.all(color: _shootLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onTap,
            child: SizedBox(
              height: 200,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: List.generate(
                  3,
                  (index) => Expanded(
                    flex: index == 0 ? 4 : 3,
                    child: Container(
                      margin: EdgeInsets.only(left: index == 0 ? 0 : 2),
                      color: _shootWash,
                      height: 200,
                      child: AppImage(
                        images[index],
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    _DarkLabel('New'),
                    SizedBox(width: 8),
                    _EditorialEyebrow('Ready to review'),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  shoot.name,
                  style: const TextStyle(
                    fontFamily: 'InstrumentSerif',
                    fontSize: 26,
                    height: 1,
                    letterSpacing: -.7,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Your finished campaign is ready. Compare every variation and choose your final images.',
                  style: TextStyle(
                    color: _shootMuted,
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                _ReadyFacts(shoot: shoot),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    label: 'Review shoot',
                    icon: Icons.arrow_forward,
                    iconAlignment: IconAlignment.end,
                    foregroundColor: AppColors.white,
                    onPressed: onTap,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadyFacts extends StatelessWidget {
  const _ReadyFacts({required this.shoot});

  final ShootViewModel shoot;

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: _shootLine)),
    ),
    child: GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3.3,
      ),
      itemBuilder: (_, index) {
        final facts = [
          ('Product', shoot.name),
          ('Model', shoot.modelName ?? 'No model'),
          ('Delivered', '${shoot.renders} images'),
          ('Completed', shoot.date),
        ];
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: _shootLine)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _EditorialEyebrow(facts[index].$1),
              const SizedBox(height: 2),
              Text(
                facts[index].$2,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class _ActiveShootList extends StatelessWidget {
  const _ActiveShootList({required this.shoots, required this.onTap});

  final List<ShootViewModel> shoots;
  final ValueChanged<ShootViewModel> onTap;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: _shootPaper,
      border: Border.all(color: _shootLine),
    ),
    child: ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: shoots.length,
      separatorBuilder: (_, _) => const Divider(height: 1, color: _shootLine),
      itemBuilder: (_, index) => _ActiveShootRow(
        shoot: shoots[index],
        onTap: () => onTap(shoots[index]),
      ),
    ),
  );
}

class _ActiveShootRow extends StatelessWidget {
  const _ActiveShootRow({required this.shoot, required this.onTap});

  final ShootViewModel shoot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    key: ValueKey('active-shoot-${shoot.id}'),
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppImage(shoot.productAsset, width: 60, height: 76, fit: BoxFit.cover),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    SizedBox(
                      width: 6,
                      height: 6,
                      child: ColoredBox(color: _shootLive),
                    ),
                    SizedBox(width: 5),
                    Text(
                      'GENERATING',
                      style: TextStyle(
                        color: _shootLive,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  shoot.name,
                  style: const TextStyle(
                    fontFamily: 'InstrumentSerif',
                    fontSize: 20,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  shoot.modelName ?? 'Product-only production',
                  style: const TextStyle(color: _shootMuted, fontSize: 11),
                ),
                const SizedBox(height: 9),
                Semantics(
                  label: 'Shoot progress',
                  value: '${(shoot.progress * 100).round()} percent',
                  child: LinearProgressIndicator(
                    value: shoot.progress,
                    minHeight: 2,
                    color: _shootLive,
                    backgroundColor: _shootLine,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Preparing high-resolution renders · ${(shoot.progress * 100).round()}%',
                  style: const TextStyle(color: _shootMuted, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _ArchiveFilterTabs extends StatelessWidget {
  const _ArchiveFilterTabs({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    const filters = [
      ('all', 'All'),
      ('completed', 'Completed'),
      ('attention', 'Needs attention'),
    ];
    return Row(
      children: [
        for (final filter in filters)
          Expanded(
            child: InkWell(
              key: ValueKey('shoot-filter-${filter.$1}'),
              onTap: () => onSelected(filter.$1),
              child: Container(
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected == filter.$1 ? _shootInk : _shootPaper,
                  border: Border.all(
                    color: selected == filter.$1 ? _shootInk : _shootLine,
                  ),
                ),
                child: Text(
                  filter.$2,
                  style: TextStyle(
                    color: selected == filter.$1 ? _shootPaper : _shootMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ArchiveShootCard extends StatelessWidget {
  const _ArchiveShootCard({
    required this.index,
    required this.shoot,
    required this.onTap,
  });

  final int index;
  final ShootViewModel shoot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    key: ValueKey('archive-shoot-${shoot.id}'),
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: _shootLine),
                ),
                child: AppImage(
                  _primaryAsset(shoot),
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 6,
                left: 6,
                child: _DarkLabel((index + 1).toString().padLeft(2, '0')),
              ),
              if (shoot.needsAttention)
                const Positioned(
                  top: 6,
                  right: 6,
                  child: _WarningLabel(),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          shoot.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          shoot.needsAttention
              ? 'Generation stopped'
              : shoot.directorName ?? shoot.modelName ?? 'Studio production',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: _shootMuted, fontSize: 10),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.only(top: 6),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: _shootLine)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  shoot.needsAttention
                      ? 'Needs attention'
                      : '${shoot.renders} final images',
                  style: const TextStyle(color: _shootMuted, fontSize: 9),
                ),
              ),
              Text(
                shoot.date,
                style: const TextStyle(color: _shootMuted, fontSize: 9),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ArchiveEmptyState extends StatelessWidget {
  const _ArchiveEmptyState();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(border: Border.all(color: _shootLine)),
    child: const Text(
      'No collections match this archive filter.',
      textAlign: TextAlign.center,
      style: TextStyle(color: _shootMuted, fontSize: 12),
    ),
  );
}

class _DarkLabel extends StatelessWidget {
  const _DarkLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: _shootInk,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: _shootPaper,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    ),
  );
}

class _WarningLabel extends StatelessWidget {
  const _WarningLabel();

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: _shootWarning,
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      child: Text(
        'NEEDS ATTENTION',
        style: TextStyle(
          color: AppColors.white,
          fontSize: 8,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}
