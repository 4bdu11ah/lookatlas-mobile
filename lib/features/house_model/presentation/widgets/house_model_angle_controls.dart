part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _AnglePager extends StatelessWidget {
  const _AnglePager({
    required this.controller,
    required this.model,
    required this.onChanged,
  });

  final PageController controller;
  final _HouseModel model;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      key: ValueKey('model-${model.id}-angle-pager'),
      controller: controller,
      itemCount: _ModelAngle.values.length,
      onPageChanged: onChanged,
      itemBuilder: (context, index) {
        final angle = _ModelAngle.values[index];
        return _ModelPhoto(
          key: ValueKey('model-${model.id}-photo-${angle.name}'),
          asset: model.assetForAngle(angle),
          label: angle.label,
        );
      },
    );
  }
}

class _AngleSelector extends StatelessWidget {
  const _AngleSelector({
    required this.modelId,
    required this.selected,
    required this.onChanged,
  });

  final String modelId;
  final _ModelAngle selected;
  final ValueChanged<_ModelAngle> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
      child: Align(
        child: Wrap(
          spacing: 3,
          children: [
            for (final angle in _ModelAngle.values)
              _AngleButton(
                key: ValueKey(
                  'model-$modelId-angle-${angle.name}'
                  '${angle == selected ? '-active' : ''}',
                ),
                angle: angle,
                active: angle == selected,
                onTap: () => onChanged(angle),
              ),
          ],
        ),
      ),
    );
  }
}

class _AngleButton extends StatelessWidget {
  const _AngleButton({
    required this.angle,
    required this.active,
    required this.onTap,
    super.key,
  });

  final _ModelAngle angle;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 20,
        height: 18,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.black : AppColors.neutral100,
        ),
        child: Text(
          angle.shortLabel,
          style: TextStyle(
            fontSize: 9,
            fontWeight: AppTypography.bold,
            color: active ? AppColors.white : AppColors.neutral500,
          ),
        ),
      ),
    );
  }
}
