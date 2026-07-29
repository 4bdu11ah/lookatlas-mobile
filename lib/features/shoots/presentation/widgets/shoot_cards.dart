part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _ShootFilters extends StatelessWidget {
  const _ShootFilters({
    required this.query,
    required this.status,
    required this.onQueryChanged,
    required this.onStatusChanged,
  });

  final String query;
  final String status;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.blackAlpha07,
            blurRadius: 9,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: _Stack(
        gap: 12,
        children: [
          _ShootSearchField(
            query: query,
            onChanged: onQueryChanged,
          ),
          Row(
            children: [
              Expanded(
                child: _ShootSelect(
                  label: 'Status',
                  value: status,
                  items: const {
                    'all': 'All statuses',
                    'completed': 'Completed',
                    'processing': 'Processing',
                    'failed': 'Failed',
                  },
                  onChanged: onStatusChanged,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: _ShootSelect(
                  label: 'Per page',
                  value: '20',
                  items: {'20': '20'},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShootSearchField extends StatefulWidget {
  const _ShootSearchField({required this.query, required this.onChanged});

  final String query;
  final ValueChanged<String> onChanged;

  @override
  State<_ShootSearchField> createState() => _ShootSearchFieldState();
}

class _ShootSearchFieldState extends State<_ShootSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
  }

  @override
  void didUpdateWidget(covariant _ShootSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query == _controller.text) return;
    _controller.value = TextEditingValue(
      text: widget.query,
      selection: TextSelection.collapsed(offset: widget.query.length),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      fieldKey: const ValueKey('shoot-search-field'),
      controller: _controller,
      hintText: 'Search shoots by name or product...',
      textInputAction: TextInputAction.search,
      onChanged: widget.onChanged,
      leading: const Icon(Icons.search, size: 20),
    );
  }
}

class _ShootSelect extends StatelessWidget {
  const _ShootSelect({
    required this.label,
    required this.value,
    required this.items,
    this.onChanged,
  });

  final String label;
  final String value;
  final Map<String, String> items;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Eyebrow(label),
        const SizedBox(height: 6),
        AppDropdown<String>(
          value: value,
          values: items.keys.toList(growable: false),
          labelFor: (value) => items[value]!,
          enabled: onChanged != null,
          onChanged: onChanged ?? (_) {},
        ),
      ],
    );
  }
}

class _ShootCard extends StatelessWidget {
  const _ShootCard({required this.shoot, required this.onTap});

  final _Shoot shoot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.blackAlpha07,
            blurRadius: 9,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ShootVisual(shoot: shoot),
          const SizedBox(height: 10),
          _CardTitle(shoot.name),
          const SizedBox(height: 10),
          _StatusBadge(shoot.status),
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _ShootPill(
                icon: Icons.inventory_2_outlined,
                label: '${shoot.renders} renders',
              ),
              _ShootPill(icon: Icons.schedule, label: shoot.date),
            ],
          ),
          const SizedBox(height: 12),
          AppOutlinedButton(
            label: 'View Details',
            onPressed: onTap,
            borderColor: AppColors.black,
          ),
        ],
      ),
    );
  }
}

class _ShootRow extends StatelessWidget {
  const _ShootRow({
    required this.shoot,
    required this.striped,
    required this.onTap,
  });

  final _Shoot shoot;
  final bool striped;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        color: striped ? AppColors.neutral100Alpha30 : AppColors.white,
        child: Row(
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: Stack(
                children: [
                  _AssetBox(shoot.productAsset, width: 56, height: 56),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.white, width: 2),
                      ),
                      child: _AssetImage(shoot.modelAsset),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: _CardTitle(shoot.name)),
                      const SizedBox(width: 8),
                      _StatusBadge(shoot.status),
                    ],
                  ),
                  const SizedBox(height: 5),
                  _Caption('${shoot.renders} renders, ${shoot.date}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShootVisual extends StatelessWidget {
  const _ShootVisual({required this.shoot});

  final _Shoot shoot;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        height: 100,
        width: 100,
        decoration: BoxDecoration(
          color: AppColors.neutral150,
          border: Border.all(color: AppColors.neutralLight),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 10,
              right: 15,
              child: Transform.rotate(
                angle: 0.08,
                child: _ShootPolaroid(asset: shoot.productAsset, size: 64),
              ),
            ),
            Positioned(
              left: 10,
              child: Transform.rotate(
                angle: -0.08,
                child: _ShootPolaroid(
                  asset: shoot.modelAsset,
                  size: 58,
                  circular: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShootPolaroid extends StatelessWidget {
  const _ShootPolaroid({
    required this.asset,
    required this.size,
    this.circular = false,
  });

  final String asset;
  final double size;
  final bool circular;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.white,
        shape: circular ? BoxShape.circle : BoxShape.rectangle,
        boxShadow: const [
          BoxShadow(
            color: AppColors.blackAlpha20,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(circular ? size : 6),
        child: _AssetImage(asset),
      ),
    );
  }
}

class _ShootPill extends StatelessWidget {
  const _ShootPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.neutral50,
        border: Border.all(color: AppColors.neutral250),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.neutral500),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppColors.neutral500),
          ),
        ],
      ),
    );
  }
}
