part of '../screens/dashboard_overview_screen.dart';

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.onTap,
    this.subtitle = '',
  });

  final IconData icon;
  final String title;
  final String body;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSquareIcon(icon),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppCardTitle(title),
                    const SizedBox(height: 4),
                    AppCaption(body),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Flexible(
                            child: Text(
                              subtitle,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                height: 1.2,
                                fontWeight: AppTypography.bold,
                                color: AppColors.black,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Transform.translate(
                            offset: const Offset(0, 3),
                            child: const Icon(
                              Icons.arrow_forward,
                              size: 13,
                              color: AppColors.black,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
