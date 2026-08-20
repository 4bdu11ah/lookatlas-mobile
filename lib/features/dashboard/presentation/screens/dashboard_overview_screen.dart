part of 'dashboard_screen.dart';

class _DashboardOverviewScreen extends ConsumerWidget {
  const _DashboardOverviewScreen({
    required this.onNavigate,
  });

  final ValueChanged<_DashboardPage> onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_dashboardOverviewControllerProvider);
    final welcomeState = ref.watch(studioSchoolControllerProvider);
    final welcome = switch (welcomeState) {
      SchoolReady(:final welcome) ||
      SchoolOfflineCached(:final welcome) => welcome.dashboard,
      _ => null,
    };
    final shouldOpenIntro = switch (state) {
      AsyncData(:final value)
          when value.subscription?.accessTier == 'subscriber' &&
              welcome != null =>
        ref
            .read(dashboardWelcomeControllerProvider.notifier)
            .shouldOpenIntro(welcome),
      _ => false,
    };
    if (shouldOpenIntro) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go(AppRoutes.welcome);
      });
    }
    return _Column(
      gap: 32,
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
          _ => const _DashboardOverviewContent(
            state: _DashboardOverviewState(),
            onNavigate: _ignoreDashboardNavigation,
            onOpenShoot: _ignoreDashboardShoot,
          ),
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
      gap: 32,
      children: [
        if (state.subscription?.needsPaymentUpdate ?? false)
          const _Alert(
            kind: _AlertKind.error,
            text: 'Your subscription payment needs attention.',
          )
        else if (state.subscription?.cancelAtPeriodEnd ?? false)
          const _Alert(
            kind: _AlertKind.warn,
            text: 'Your subscription is set to end after this billing period.',
          )
        else if (state.subscription?.accessTier == 'onetime_download' &&
            (state.subscription?.proUpsellActive ?? false))
          const _Alert(
            kind: _AlertKind.info,
            text: 'Your limited-time Pro offer is available in Billing.',
          ),
        _DashboardGuidanceAndStats(
          subscription: state.subscription,
          focusJob: state.recentJobs.firstOrNull,
          stats: state.stats,
        ),
        _RecentShoots(
          shoots: state.shoots,
          isLoading: state.isLoadingRecentJobs,
          onNavigate: onNavigate,
          onOpenShoot: onOpenShoot,
        ),
        _QuickActions(onNavigate: onNavigate),
      ],
    );
  }
}

class _DashboardGuidanceAndStats extends ConsumerWidget {
  const _DashboardGuidanceAndStats({
    required this.subscription,
    required this.focusJob,
    required this.stats,
  });

  final DashboardSubscription? subscription;
  final DashboardRecentJob? focusJob;
  final DashboardStats? stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) => _Column(
    gap: 32,
    children: [
      if (subscription != null &&
          DashboardWelcomeBlock.isVisible(
            ref,
            subscription: subscription!,
            focusJob: focusJob,
          ))
        DashboardWelcomeBlock(
          subscription: subscription!,
          focusJob: focusJob,
        ),
      if (SchoolDashboardHelper.isVisible(ref)) const SchoolDashboardHelper(),
      if (stats case final stats?)
        _StatsList(stats: stats)
      else
        const _DashboardStatsLoading(),
    ],
  );
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
    return LayoutBuilder(
      builder: (context, constraints) => _Card(
        padding: EdgeInsets.all(constraints.maxWidth < 140 ? 16 : 24),
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
      ),
    );
  }
}

class _RecentShoots extends StatelessWidget {
  const _RecentShoots({
    required this.shoots,
    required this.isLoading,
    required this.onNavigate,
    required this.onOpenShoot,
  });

  final List<_Shoot> shoots;
  final bool isLoading;
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
                  label: 'View all',
                  icon: Icons.arrow_forward,
                  iconAlignment: IconAlignment.end,
                  fitToContent: true,
                  onPressed: () => onNavigate(_DashboardPage.jobs),
                ),
              ],
            ),
          ),
          const _Hairline(),
          if (isLoading && shoots.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: BarSpinner(),
            )
          else if (shoots.isEmpty)
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

class _DashboardStatsLoading extends StatelessWidget {
  const _DashboardStatsLoading();

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
        ],
      ),
    );
  }
}

int _dashboardStatColumns(double width) => width >= 600 ? 3 : 2;

void _ignoreDashboardNavigation(_DashboardPage _) {}

void _ignoreDashboardShoot(_Shoot _) {}

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
