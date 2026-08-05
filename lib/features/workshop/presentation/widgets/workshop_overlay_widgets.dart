part of '../screens/workshop_screen.dart';

class _WorkshopDeleteDialog extends StatelessWidget {
  const _WorkshopDeleteDialog({
    required this.onCancel,
    required this.onDelete,
  });

  final VoidCallback onCancel;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox.square(
                dimension: 54,
                child: ColoredBox(
                  color: AppColors.dangerDark,
                  child: Icon(
                    Icons.delete_outline,
                    size: 25,
                    color: AppColors.white,
                  ),
                ),
              ),
              SizedBox(height: 18),
              Text(
                'Delete generation?',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: AppTypography.bold,
                  color: AppColors.black,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'This removes the generation from Workshop history.',
                style: TextStyle(
                  fontSize: 13,
                  height: 20 / 13,
                  color: AppColors.neutral500,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppColors.neutral100,
            border: Border(top: BorderSide(color: AppColors.neutral200)),
          ),
          child: Column(
            children: [
              AppOutlinedButton(
                label: 'Cancel',
                onPressed: onCancel,
                borderColor: AppColors.black,
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Delete',
                icon: Icons.delete_outline,
                iconSize: 16,
                onPressed: onDelete,
                backgroundColor: AppColors.dangerDark,
                foregroundColor: AppColors.white,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WorkshopPaywallDialog extends StatelessWidget {
  const _WorkshopPaywallDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(right: 44),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SUBSCRIBER FEATURE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: AppTypography.bold,
                            letterSpacing: 0.88,
                            color: AppColors.neutral500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Edit any image in seconds.',
                          style: TextStyle(
                            fontSize: 22,
                            height: 28 / 22,
                            fontWeight: AppTypography.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Workshop turns one image plus a prompt into a finished edit. Subscribers get 1-credit generations.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 21 / 14,
                      color: AppColors.neutral500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _WorkshopBulletList(
                    items: [
                      'Multi-reference compositing',
                      'Auto aspect-ratio detection',
                      '1 credit per generation',
                    ],
                  ),
                  const SizedBox(height: 20),
                  _WorkshopPrimaryButton(
                    label: 'View plans',
                    onTap: () => Navigator.pop(context, true),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: _WorkshopIconButton(
                icon: Icons.close,
                label: 'Close paywall',
                onTap: () => Navigator.pop(context, false),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkshopBulletList extends StatelessWidget {
  const _WorkshopBulletList({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '•',
                  style: TextStyle(fontSize: 14, height: 26 / 14),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(fontSize: 14, height: 26 / 14),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
