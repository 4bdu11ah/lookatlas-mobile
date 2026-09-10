part of '../shell/dashboard_shell.dart';

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.tileKey,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final Key? tileKey;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: tileKey,
      onTap: onTap,
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        color: active ? AppColors.black : AppColors.transparent,
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: active ? AppColors.white : AppColors.neutral500,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: AppTypography.semiBold,
                  color: active ? AppColors.white : AppColors.neutral500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.black),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, color: AppColors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
