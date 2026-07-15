part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _JobsPage extends ConsumerWidget {
  const _JobsPage({required this.onNavigate});

  final ValueChanged<_DashboardPage> onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_shootsControllerProvider);
    return _Stack(
      children: [
        _RowWrap(
          children: [
            const _PageHeader(
              title: 'Shoots',
              body:
                  'Manage product photo jobs, generation status, exports, and approvals.',
            ),
            _Button(
              label: 'New Shoot',
              icon: Icons.add,
              full: true,
              onTap: () => onNavigate(_DashboardPage.create),
            ),
          ],
        ),
        const _FilterCard(
          children: [
            _InputLike('Search shoots'),
            _SelectLike('All statuses'),
          ],
        ),
        _Card(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < state.shoots.length; i++)
                _ShootRow(
                  shoot: state.shoots[i],
                  striped: i.isOdd,
                  onTap: () => onNavigate(_DashboardPage.jobDetail),
                ),
            ],
          ),
        ),
        _EmptyState(
          title: 'Empty state',
          body: 'Shown when there are no jobs or no matches for filters.',
          buttonLabel: 'Clear filters',
          secondary: true,
          onTap: () {},
        ),
      ],
    );
  }
}

class _JobDetailPage extends StatelessWidget {
  const _JobDetailPage({
    required this.onNavigate,
    required this.onOpenModal,
    required this.onToast,
  });

  final ValueChanged<_DashboardPage> onNavigate;
  final ValueChanged<_ModalKind> onOpenModal;
  final ValueChanged<String> onToast;

  @override
  Widget build(BuildContext context) {
    return _Stack(
      children: [
        _Button.secondary(
          label: 'Back to Jobs',
          icon: Icons.arrow_back,
          full: true,
          onTap: () => onNavigate(_DashboardPage.jobs),
        ),
        const _PageHeader(
          title: 'Summer drop hero shoot',
          body: 'Generated images for Maya Chen',
          small: true,
        ),
        _RowWrap(
          children: [
            const _Badge('Completed', kind: _BadgeKind.success),
            const _Badge('Video ready'),
            _Button.secondary(
              label: 'Refresh',
              icon: Icons.refresh,
              compact: true,
              onTap: () => onToast('Shoot refreshed'),
            ),
            _Button.secondary(
              label: 'Export',
              icon: Icons.download,
              compact: true,
              onTap: () => onToast('Export started'),
            ),
          ],
        ),
        const _Card(
          child: Column(
            children: [
              _ProgressHead(label: 'Processing state', value: '64%'),
              SizedBox(height: 10),
              _ProgressBar(value: 0.64),
              SizedBox(height: 8),
              _Caption(
                'Shown for processing, retrying, and cancel requested jobs.',
              ),
            ],
          ),
        ),
        const _Alert(
          kind: _AlertKind.warn,
          text:
              'Partially completed state: generated images stay visible and missing credits are refunded.',
        ),
        const _Grid2(
          children: [
            _MetricCard('Product', 'Emerald Slip Dress'),
            _MetricCard('Model', 'Maya Chen'),
            _MetricCard('Shots', '6 selected'),
            _MetricCard('Credits', '36 used'),
          ],
        ),
        _Card(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionTitle('Variation 1'),
                      _Caption('6 shots, 4 angles'),
                    ],
                  ),
                  _Button.secondary(
                    label: 'Approve',
                    compact: true,
                    onTap: () => onToast('Variation approved'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _ShotGrid(onOpenModal: onOpenModal),
            ],
          ),
        ),
        _Button(
          label: 'Generate Video',
          full: true,
          onTap: () => onOpenModal(_ModalKind.video),
        ),
      ],
    );
  }
}

class _ShootRow extends StatelessWidget {
  const _ShootRow({
    required this.shoot,
    required this.striped,
    required this.onTap,
  });

  final _Shoot shoot;
  final bool striped;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        color: striped ? AppColors.neutral100Alpha30 : AppColors.white,
        child: Column(
          children: [
            Row(
              children: [
                _ShootThumb(shoot),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: _CardTitle(shoot.name)),
                          const SizedBox(width: 8),
                          _StatusBadge(shoot.status),
                        ],
                      ),
                      const SizedBox(height: 5),
                      _Caption('${shoot.renders} renders, ${shoot.date}'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ShootThumb extends StatelessWidget {
  const _ShootThumb(this.shoot);

  final _Shoot shoot;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        children: [
          _AssetBox(shoot.productAsset, width: 56, height: 56),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.white, width: 2),
              ),
              child: _AssetImage(shoot.modelAsset),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShotGrid extends ConsumerWidget {
  const _ShotGrid({required this.onOpenModal});

  final ValueChanged<_ModalKind> onOpenModal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_shootsControllerProvider);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: state.shotAssets.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemBuilder: (context, index) => _ShotCard(
        asset: state.shotAssets[index],
        title: const [
          'Hero',
          'Side',
          'Detail',
          'Front',
          'Lifestyle',
          'Crop',
        ][index],
        index: index,
        approved: index == 0 || index == 2,
        onEdit: index == 1 ? () => onOpenModal(_ModalKind.editAi) : null,
      ),
    );
  }
}

class _ShotCard extends StatelessWidget {
  const _ShotCard({
    required this.asset,
    required this.title,
    required this.index,
    required this.approved,
    this.onEdit,
  });

  final String asset;
  final String title;
  final int index;
  final bool approved;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: _AssetImage(asset)),
        Positioned(
          top: 8,
          right: 8,
          child: _SmallOverlayButton(icon: Icons.download, onTap: () {}),
        ),
        Positioned(
          top: 8,
          left: 8,
          child: _SmallOverlayButton(
            icon: approved ? Icons.check : Icons.circle_outlined,
            onTap: () {},
          ),
        ),
        if (onEdit != null)
          Positioned(
            left: 8,
            right: 8,
            top: 52,
            child: _Button.secondary(
              label: 'Edit with AI',
              icon: Icons.auto_awesome,
              compact: true,
              onTap: onEdit!,
            ),
          ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.all(8),
            color: AppColors.blackAlpha70,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 12,
                      fontWeight: AppTypography.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Shot #${index + 1}',
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.75),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
