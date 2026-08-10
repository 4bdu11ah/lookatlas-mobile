part of '../screens/dashboard_screen.dart';

class _DashboardModal extends StatelessWidget {
  const _DashboardModal({
    required this.kind,
    required this.onNavigate,
    required this.onOpenModal,
    required this.onToast,
  });

  final _ModalKind kind;
  final ValueChanged<_DashboardPage> onNavigate;
  final ValueChanged<_ModalKind> onOpenModal;
  final ValueChanged<String> onToast;

  @override
  Widget build(BuildContext context) {
    return kind == _ModalKind.delete
        ? _DeleteModal(onToast: onToast)
        : _ShootDialog(
            kind: kind,
            onNavigate: onNavigate,
            onOpenModal: onOpenModal,
            onToast: onToast,
          );
  }
}

class _DeleteModal extends StatelessWidget {
  const _DeleteModal({required this.onToast});

  final ValueChanged<String> onToast;

  @override
  Widget build(BuildContext context) {
    return _ModalFrame(
      title: 'Delete Item',
      actions: [
        AppOutlinedButton(
          label: 'Cancel',
          onPressed: () => Navigator.pop(context),
        ),
        PrimaryButton(
          label: 'Delete',
          backgroundColor: AppColors.danger,
          foregroundColor: AppColors.white,
          onPressed: () {
            Navigator.pop(context);
            onToast('Deleted');
          },
        ),
      ],
      children: const [
        _BodyText('This item will be permanently deleted.'),
      ],
    );
  }
}

class _ModalFrame extends StatelessWidget {
  const _ModalFrame({
    required this.title,
    this.subtitle,
    this.leading,
    this.children = const [],
    this.actions = const [],
    this.actionFlexes = const [],
  }) : assert(
         actionFlexes.length == 0 || actionFlexes.length == actions.length,
         'actionFlexes must match actions length.',
       );

  final String title;
  final String? subtitle;
  final IconData? leading;
  final List<Widget> children;
  final List<Widget> actions;
  final List<int> actionFlexes;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(17, 17, 10, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (leading != null) ...[
                _SquareIcon(leading!),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      _Caption(subtitle!),
                    ],
                  ],
                ),
              ),
              _IconButton(
                icon: Icons.close,
                label: 'Close dialog',
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        const _Hairline(),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(17),
            child: _Column(gap: 12, children: children),
          ),
        ),
        if (actions.isNotEmpty) ...[
          const _Hairline(),
          Container(
            padding: const EdgeInsets.all(13),
            color: AppColors.neutral50,
            child: Row(
              children: [
                for (var index = 0; index < actions.length; index++) ...[
                  Expanded(
                    flex: actionFlexes.isEmpty ? 1 : actionFlexes[index],
                    child: actions[index],
                  ),
                  if (index != actions.length - 1) const SizedBox(width: 9),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
