part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _CalibrationDialog extends StatelessWidget {
  const _CalibrationDialog();

  @override
  Widget build(BuildContext context) {
    return _ModalFrame(
      title: 'Calibrate Tan Leather Bag',
      subtitle: 'Help Look Atlas place this product correctly on every model.',
      actions: [
        AppOutlinedButton(
          label: 'Cancel',
          onPressed: () => Navigator.pop(context),
        ),
      ],
      children: const [
        _Alert(
          kind: _AlertKind.info,
          text: 'Recommended for bags to improve scale and placement.',
        ),
        _CalibrationOption(
          icon: Icons.person_outline,
          title: 'Place on body outline',
          body: 'Position your product on a standard body view.',
        ),
        _CalibrationOption(
          icon: Icons.camera_alt_outlined,
          title: 'Upload a worn photo',
          body: 'Use a real photo of the product being worn.',
        ),
        _CalibrationOption(
          icon: Icons.inventory_2_outlined,
          title: 'Copy from another product',
          body: 'Reuse an existing product calibration.',
        ),
      ],
    );
  }
}

class _CalibrationOption extends StatelessWidget {
  const _CalibrationOption({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return _Card(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _SquareIcon(icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [_CardTitle(title), _Caption(body)],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 14),
        ],
      ),
    );
  }
}

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
