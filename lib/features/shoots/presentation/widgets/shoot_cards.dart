part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _ShootFilters extends StatelessWidget {
  const _ShootFilters({
    required this.query,
    required this.status,
    required this.shootCount,
    required this.onQueryChanged,
    required this.onStatusChanged,
  });

  final String query;
  final String status;
  final int shootCount;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final hasActiveFilters = status != 'all';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ShootSearchField(query: query, onChanged: onQueryChanged),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(
                '$shootCount ${shootCount == 1 ? 'shoot' : 'shoots'}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.neutral500,
                ),
              ),
            ),
            AppOutlinedButton(
              key: const ValueKey('open-shoot-filter-sheet'),
              label: hasActiveFilters ? 'Filters (1)' : 'Filters',
              icon: Icons.tune,
              fitToContent: true,
              height: 40,
              onPressed: () => _showShootFilterSheet(
                context,
                status: status,
                onStatusChanged: onStatusChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

Future<void> _showShootFilterSheet(
  BuildContext context, {
  required String status,
  required ValueChanged<String> onStatusChanged,
}) {
  return showAppBottomSheet<void>(
    context,
    builder: (_) => _ShootFilterSheet(
      initialStatus: status,
      onStatusChanged: onStatusChanged,
    ),
  );
}

class _ShootFilterSheet extends ConsumerWidget {
  const _ShootFilterSheet({
    required this.initialStatus,
    required this.onStatusChanged,
  });

  final String initialStatus;
  final ValueChanged<String> onStatusChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_shootFilterSheetProvider(initialStatus));
    final controller = ref.read(
      _shootFilterSheetProvider(initialStatus).notifier,
    );
    return _SheetFrame(
      title: 'Filter shoots',
      actions: [
        AppOutlinedButton(
          label: 'Clear',
          onPressed: () {
            onStatusChanged('all');
            Navigator.pop(context);
          },
        ),
        PrimaryButton(
          label: 'Show shoots',
          foregroundColor: AppColors.white,
          onPressed: () {
            onStatusChanged(state.status);
            Navigator.pop(context);
          },
        ),
      ],
      child: _ShootStatusList(
        value: state.status,
        onChanged: controller.setStatus,
      ),
    );
  }
}

class _ShootFilterSheetState {
  const _ShootFilterSheetState({required this.status});

  final String status;
}

class _ShootFilterSheetController extends Notifier<_ShootFilterSheetState> {
  _ShootFilterSheetController(this.initialStatus);

  final String initialStatus;

  @override
  _ShootFilterSheetState build() => _ShootFilterSheetState(
    status: initialStatus,
  );

  void setStatus(String status) => state = _ShootFilterSheetState(
    status: status,
  );
}

final _shootFilterSheetProvider = NotifierProvider.autoDispose
    .family<_ShootFilterSheetController, _ShootFilterSheetState, String>(
      _ShootFilterSheetController.new,
    );

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
      height: 40,
      hintText: 'Search shoots by name or product...',
      textInputAction: TextInputAction.search,
      onChanged: widget.onChanged,
      leading: const Icon(Icons.search, size: 16, color: AppColors.neutral500),
      trailing: widget.query.isEmpty
          ? const SizedBox(width: 11)
          : InkWell(
              key: const ValueKey('clear-shoot-search'),
              onTap: () => widget.onChanged(''),
              child: const SizedBox(
                width: 38,
                height: 40,
                child: Icon(Icons.close, size: 16, color: AppColors.black),
              ),
            ),
    );
  }
}

class _ShootStatusList extends StatelessWidget {
  const _ShootStatusList({required this.value, required this.onChanged});

  static const _items = {
    'all': 'All statuses',
    'completed': 'Completed',
    'processing': 'Processing',
    'failed': 'Failed',
  };

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Eyebrow('Status'),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.neutral200),
          ),
          child: Column(
            children: [
              for (final entry in _items.entries) ...[
                InkWell(
                  onTap: () => onChanged(entry.key),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.value,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.black,
                            ),
                          ),
                        ),
                        Icon(
                          entry.key == value
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          size: 20,
                          color: entry.key == value
                              ? AppColors.black
                              : AppColors.neutral400,
                        ),
                      ],
                    ),
                  ),
                ),
                if (entry.key != 'failed')
                  const Divider(height: 1, color: AppColors.neutral200),
              ],
            ],
          ),
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
            height: 40,
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
