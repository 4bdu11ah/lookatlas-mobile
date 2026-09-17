part of '../screens/shoots_page.dart';

class _ShootDraftSection extends StatelessWidget {
  const _ShootDraftSection({
    required this.drafts,
    required this.onOpen,
    required this.onDelete,
  });

  final List<ShootDraftSummary> drafts;
  final ValueChanged<ShootDraftSummary> onOpen;
  final ValueChanged<ShootDraftSummary> onDelete;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _shootPaper,
      border: Border.all(color: _shootLine),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _EditorialEyebrow('Unfinished'),
        const SizedBox(height: 4),
        const Text(
          'Pick up where you left off.',
          style: TextStyle(
            fontFamily: 'InstrumentSerif',
            fontSize: 22,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: drafts.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, index) => _ShootDraftRow(
            draft: drafts[index],
            onOpen: () => onOpen(drafts[index]),
            onDelete: () => onDelete(drafts[index]),
          ),
        ),
      ],
    ),
  );
}

class _ShootDraftRow extends StatelessWidget {
  const _ShootDraftRow({
    required this.draft,
    required this.onOpen,
    required this.onDelete,
  });

  final ShootDraftSummary draft;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: _shootWash.withValues(alpha: .5),
      border: Border.all(color: _shootLine),
    ),
    child: Row(
      children: [
        Expanded(
          child: InkWell(
            key: ValueKey('resume-shoot-draft-${draft.id}'),
            onTap: onOpen,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  AppImage(
                    draft.thumbnailUrl,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          draft.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Step ${draft.stepNumber} of 5 · ${draft.stepLabel}',
                          style: const TextStyle(
                            color: _shootMuted,
                            fontSize: 10,
                          ),
                        ),
                        Text(
                          _draftEditedLabel(draft.updatedAt),
                          style: const TextStyle(
                            color: _shootMuted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Container(
          width: 44,
          height: 64,
          decoration: const BoxDecoration(
            border: Border(left: BorderSide(color: _shootLine)),
          ),
          child: IconButton(
            key: ValueKey('delete-shoot-draft-${draft.id}'),
            tooltip: 'Delete draft',
            onPressed: onDelete,
            icon: const Icon(
              Icons.delete_outline,
              size: 19,
              color: _shootMuted,
            ),
          ),
        ),
      ],
    ),
  );
}

String _draftEditedLabel(DateTime updatedAt) {
  final now = DateTime.now();
  final local = updatedAt.toLocal();
  final today = DateTime(now.year, now.month, now.day);
  final edited = DateTime(local.year, local.month, local.day);
  final days = today.difference(edited).inDays;
  if (days <= 0) return 'Edited today';
  if (days == 1) return 'Edited yesterday';
  return 'Edited $days days ago';
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
    if (_controller.text == widget.query) return;
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
  Widget build(BuildContext context) => AppTextField(
    fieldKey: const ValueKey('shoot-search-field'),
    controller: _controller,
    height: 44,
    hintText: 'Search generated shoots, products, or models',
    textInputAction: TextInputAction.search,
    onChanged: widget.onChanged,
    leading: const Icon(Icons.search, size: 17, color: _shootMuted),
    trailing: widget.query.isEmpty
        ? const SizedBox(width: 8)
        : IconButton(
            key: const ValueKey('clear-shoot-search'),
            onPressed: () => widget.onChanged(''),
            icon: const Icon(Icons.close, size: 16),
          ),
  );
}

class ShootRow extends StatelessWidget {
  const ShootRow({
    required this.shoot,
    required this.striped,
    required this.onTap,
    super.key,
  });

  final ShootViewModel shoot;
  final bool striped;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(16),
      color: striped ? _shootWash : _shootPaper,
      child: Row(
        children: [
          AppImage(
            _primaryAsset(shoot),
            width: 56,
            height: 64,
            fit: BoxFit.cover,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shoot.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 5),
                Text(
                  '${shoot.renders} renders · ${shoot.date}',
                  style: const TextStyle(color: _shootMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward, size: 18),
        ],
      ),
    ),
  );
}

List<String> _galleryAssets(ShootViewModel shoot) {
  final assets = <String>[
    ...shoot.galleryAssets,
    shoot.productAsset,
    shoot.modelAsset,
  ].where((asset) => asset.isNotEmpty).toList();
  if (assets.isEmpty) return const ['', '', ''];
  return List.generate(3, (index) => assets[index % assets.length]);
}

String _primaryAsset(ShootViewModel shoot) =>
    shoot.galleryAssets.firstOrNull ?? shoot.productAsset;
