part of 'dashboard_screen.dart';

class _DashboardOverviewScreen extends ConsumerWidget {
  const _DashboardOverviewScreen({
    required this.onNavigate,
  });

  final ValueChanged<_DashboardPage> onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_dashboardOverviewControllerProvider);
    return _Column(
      gap: 12,
      children: [
        const _PageHeader(
          title: 'Dashboard',
          body: "Welcome back! Here's your Look Atlas overview.",
        ),
        switch (state) {
          AsyncData(:final value) => _DashboardOverviewContent(
            state: value,
            onNavigate: onNavigate,
            onOpenShoot: (shoot) => unawaited(
              context.push<void>(AppRoutes.shootDetail(shoot.id)),
            ),
          ),
          AsyncError(:final error) => _DashboardLoadError(
            message: error is Failure
                ? error.message
                : 'Could not load your dashboard.',
            onRetry: () => ref
                .read(_dashboardOverviewControllerProvider.notifier)
                .refresh(),
          ),
          _ => const _DashboardLoading(),
        },
      ],
    );
  }
}

class _DashboardOverviewContent extends StatelessWidget {
  const _DashboardOverviewContent({
    required this.state,
    required this.onNavigate,
    required this.onOpenShoot,
  });

  final _DashboardOverviewState state;
  final ValueChanged<_DashboardPage> onNavigate;
  final ValueChanged<_Shoot> onOpenShoot;

  @override
  Widget build(BuildContext context) {
    return _Column(
      gap: 12,
      children: [
        if (state.subscription.needsPaymentUpdate)
          const _Alert(
            kind: _AlertKind.error,
            text: 'Your subscription payment needs attention.',
          )
        else if (state.subscription.cancelAtPeriodEnd)
          const _Alert(
            kind: _AlertKind.warn,
            text: 'Your subscription is set to end after this billing period.',
          )
        else if (state.subscription.accessTier == 'onetime_download' &&
            state.subscription.proUpsellActive)
          const _Alert(
            kind: _AlertKind.info,
            text: 'Your limited-time Pro offer is available in Billing.',
          ),
        const SchoolDashboardHelper(),
        _StatsList(stats: state.stats),
        _RecentShoots(
          shoots: state.shoots,
          onNavigate: onNavigate,
          onOpenShoot: onOpenShoot,
        ),
        _QuickActions(onNavigate: onNavigate),
      ],
    );
  }
}

class _StatsList extends StatelessWidget {
  const _StatsList({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatCard(Icons.trending_up, 'Credits Remaining', '${stats.credits}'),
      _StatCard(
        Icons.inventory_2_outlined,
        'Total Renders',
        '${stats.totalRenders}',
      ),
      _StatCard(Icons.schedule, 'Active Shoots', '${stats.activeJobs}'),
      _StatCard(
        Icons.check_circle_outline,
        'Completed Shoots',
        '${stats.completedJobs}',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: cards.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _dashboardStatColumns(constraints.maxWidth),
          mainAxisExtent: 192,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
        itemBuilder: (context, index) => cards[index],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return _Card(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SquareIcon(icon),
          const SizedBox(height: 16),
          _Eyebrow(label, maxLines: 2),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              height: 1.1,
              fontWeight: AppTypography.bold,
              letterSpacing: -0.64,
              color: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentShoots extends StatelessWidget {
  const _RecentShoots({
    required this.shoots,
    required this.onNavigate,
    required this.onOpenShoot,
  });

  final List<_Shoot> shoots;
  final ValueChanged<_DashboardPage> onNavigate;
  final ValueChanged<_Shoot> onOpenShoot;

  @override
  Widget build(BuildContext context) {
    return _Card(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Expanded(child: _SectionTitle('Recent Shoots')),
                const SizedBox(width: 12),
                AppOutlinedButton(
                  label: 'View all shoots',
                  icon: Icons.arrow_forward,
                  iconAlignment: IconAlignment.end,
                  fitToContent: true,
                  onPressed: () => onNavigate(_DashboardPage.jobs),
                ),
              ],
            ),
          ),
          const _Hairline(),
          if (shoots.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: _BodyText('No recent shoots yet.'),
            )
          else
            for (var i = 0; i < shoots.length; i++)
              _ShootRow(
                shoot: shoots[i],
                striped: i.isOdd,
                onTap: () => onOpenShoot(shoots[i]),
              ),
        ],
      ),
    );
  }
}

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => _Column(
        gap: 12,
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 4,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _dashboardStatColumns(constraints.maxWidth),
              mainAxisExtent: 192,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemBuilder: (_, _) => const ShimmerBox(),
          ),
          const ContentShimmer(itemCount: 2, itemHeight: 104),
        ],
      ),
    );
  }
}

int _dashboardStatColumns(double width) => width >= 600 ? 3 : 2;

class _DashboardLoadError extends StatelessWidget {
  const _DashboardLoadError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: _Column(
        gap: 16,
        children: [
          _Alert(kind: _AlertKind.error, text: message),
          AppOutlinedButton(
            label: 'Try again',
            icon: Icons.refresh,
            onPressed: () => unawaited(onRetry()),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onNavigate});

  final ValueChanged<_DashboardPage> onNavigate;

  @override
  Widget build(BuildContext context) {
    return _Column(
      gap: 12,
      children: [
        const _SectionTitle('Quick Actions'),
        _ActionCard(
          icon: Icons.groups_outlined,
          title: 'Manage Models',
          body: 'Upload and manage house models for consistent photography.',
          subtitle: 'Go to Models',
          onTap: () => onNavigate(_DashboardPage.models),
        ),
        _ActionCard(
          icon: Icons.inventory_2_outlined,
          title: 'Upload Products',
          body: 'Add products for AI-generated photo shoots.',
          subtitle: 'Manage Products',
          onTap: () => onNavigate(_DashboardPage.products),
        ),
        _ActionCard(
          icon: Icons.auto_fix_high_outlined,
          title: 'Workshop',
          body: 'Edit a photo with a prompt, references, and AI.',
          subtitle: 'Open Workshop',
          onTap: () => onNavigate(_DashboardPage.workshop),
        ),
        _ActionCard(
          icon: Icons.check_circle_outline,
          title: 'New Shoot',
          subtitle: 'Create Shoot',
          body: 'Generate new on-model product photos with AI.',
          onTap: () => unawaited(context.push<void>(AppRoutes.createShoot)),
        ),
      ],
    );
  }
}
