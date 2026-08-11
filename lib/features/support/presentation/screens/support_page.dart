part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppFeatureScaffold(
      backgroundColor: AppColors.neutral50,
      title: 'Support',
      child: _SupportPage(),
    );
  }
}

class _SupportPage extends StatelessWidget {
  const _SupportPage();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      children: const [
        _SupportPageHeader(),
        SizedBox(height: 32),
        _SupportContactCard(),
        SizedBox(height: 24),
        _SupportFormCard(),
      ],
    );
  }
}

class _SupportPageHeader extends StatelessWidget {
  const _SupportPageHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Support',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            height: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Get help with Look Atlas. We're here to assist you.",
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            height: 1.5,
            color: AppColors.neutral500,
          ),
        ),
      ],
    );
  }
}

class _SupportContactCard extends StatelessWidget {
  const _SupportContactCard();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.neutral200),
      ),
      child: const Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SupportSectionTitle(),
            SizedBox(height: 24),
            _SupportContactRow(
              icon: Icons.mail_outline,
              title: 'Email Support',
              detail: 'support@lookatlas.com',
            ),
            SizedBox(height: 16),
            _SupportContactRow(
              icon: Icons.schedule,
              title: 'Support Hours',
              detail: 'Mon-Fri, 9AM-6PM EST',
            ),
            SizedBox(height: 16),
            _SupportResponseTime(),
          ],
        ),
      ),
    );
  }
}

class _SupportSectionTitle extends StatelessWidget {
  const _SupportSectionTitle();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _SupportSquareIcon(
          icon: Icons.chat_bubble_outline,
          inverted: true,
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            'Contact Info',
            style: TextStyle(
              fontSize: 18,
              fontWeight: AppTypography.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _SupportContactRow extends StatelessWidget {
  const _SupportContactRow({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.neutral100Alpha68,
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SupportSquareIcon(icon: icon),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: AppTypography.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    detail,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.43,
                      color: AppColors.neutral500,
                    ),
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

class _SupportSquareIcon extends StatelessWidget {
  const _SupportSquareIcon({required this.icon, this.inverted = false});

  final IconData icon;
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: inverted ? AppColors.black : AppColors.white,
        border: inverted ? null : Border.all(color: AppColors.neutral200),
      ),
      child: Icon(
        icon,
        size: 20,
        color: inverted ? AppColors.white : AppColors.black,
      ),
    );
  }
}

class _SupportResponseTime extends StatelessWidget {
  const _SupportResponseTime();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.black,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'RESPONSE TIME',
              style: TextStyle(
                fontSize: 12,
                fontWeight: AppTypography.medium,
                color: AppColors.whiteAlpha60,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'We typically respond within 24 hours',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
