part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _DialogUpload extends StatelessWidget {
  const _DialogUpload({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        const SizedBox(height: 7),
        InkWell(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.neutral250,
                width: 2,
              ),
            ),
            child: const Column(
              children: [
                Icon(Icons.upload_outlined, size: 24),
                SizedBox(height: 6),
                _CardTitle('Click to upload'),
                _Caption('PNG, JPG up to 10MB'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
