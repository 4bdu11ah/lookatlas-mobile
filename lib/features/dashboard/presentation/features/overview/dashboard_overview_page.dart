part of '../../screens/dashboard_screen.dart';

class _DashboardPageView extends ConsumerWidget {
  const _DashboardPageView({
    required this.onNavigate,
  });

  final ValueChanged<_DashboardPage> onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_dashboardOverviewControllerProvider);
    final shootsController = ref.read(_shootsControllerProvider.notifier);
    return _Stack(
      gap: 12,
      children: [
        const _PageHeader(
          title: 'Dashboard',
          body: "Welcome back! Here's your Look Atlas overview.",
        ),
        const _StatsList(),
        _RecentShoots(
          shoots: state.shoots,
          onNavigate: onNavigate,
          onOpenShoot: (shoot) {
            shootsController.selectShoot(shoot);
            unawaited(context.push<void>(AppRoutes.shootDetail));
          },
        ),
        _QuickActions(onNavigate: onNavigate),
      ],
    );
  }
}

class _StatsList extends StatelessWidget {
  const _StatsList();

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        _StatCard(Icons.trending_up, 'Credits Remaining', '142'),
        _StatCard(Icons.inventory_2_outlined, 'Total Renders', '386'),
        _StatCard(Icons.schedule, 'Active Shoots', '2'),
        _StatCard(Icons.check_circle_outline, 'Completed Shoots', '18'),
      ],
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
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SquareIcon(icon),
          const SizedBox(height: 16),
          _Eyebrow(label),
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

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onNavigate});

  final ValueChanged<_DashboardPage> onNavigate;

  @override
  Widget build(BuildContext context) {
    return _Stack(
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
