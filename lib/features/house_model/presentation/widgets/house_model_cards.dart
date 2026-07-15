part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

class _ModelGrid extends StatelessWidget {
  const _ModelGrid({required this.models});

  final List<_HouseModel> models;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.only(top: 16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 11,
        mainAxisSpacing: 11,
        childAspectRatio: 0.52,
      ),
      itemCount: models.length,
      itemBuilder: (context, index) {
        return _LibraryModelCard(model: models[index]);
      },
    );
  }
}

class _LibraryModelCard extends StatefulWidget {
  const _LibraryModelCard({required this.model});

  final _HouseModel model;

  @override
  State<_LibraryModelCard> createState() => _LibraryModelCardState();
}

class _LibraryModelCardState extends State<_LibraryModelCard> {
  late final PageController _pageController;
  _ModelAngle _angle = _ModelAngle.front;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _selectAngle(_ModelAngle angle) {
    if (_angle == angle) return;
    setState(() => _angle = angle);
    unawaited(
      _pageController.animateToPage(
        angle.index,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _ModelCardFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardTop(title: widget.model.name),
          Expanded(
            child: _AnglePager(
              controller: _pageController,
              model: widget.model,
              onChanged: (index) {
                setState(() => _angle = _ModelAngle.values[index]);
              },
            ),
          ),
          _AngleSelector(
            modelId: widget.model.id,
            selected: _angle,
            onChanged: _selectAngle,
          ),
          _CardMeta(model: widget.model),
        ],
      ),
    );
  }
}

class _UserModelCard extends ConsumerWidget {
  const _UserModelCard({required this.model, required this.onToast});

  final _HouseModel model;
  final ValueChanged<String> onToast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _ModelCardFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardTop(
            title: model.name,
            icon: Icons.edit_outlined,
            onTap: () => _showModelFormSheet(context, ref, onToast, model),
          ),
          AspectRatio(
            aspectRatio: 9 / 11.3,
            child: _ModelPhoto(asset: model.asset, label: model.source.label),
          ),
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.neutral200)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.photo_camera_outlined,
                  size: 14,
                  color: AppColors.neutral500,
                ),
                const SizedBox(width: 6),
                Text(
                  '${model.photoCount} ${model.photoCount == 1 ? 'photo' : 'photos'}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.neutral500,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Delete model',
                  icon: const Icon(Icons.delete_outline, size: 18),
                  color: AppColors.neutral500,
                  onPressed: () =>
                      _showDeleteSheet(context, ref, model, onToast),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModelCardFrame extends StatelessWidget {
  const _ModelCardFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      shape: const Border.fromBorderSide(
        BorderSide(color: AppColors.neutral200),
      ),
      child: child,
    );
  }
}

class _CardTop extends StatelessWidget {
  const _CardTop({required this.title, this.icon, this.onTap});

  final String title;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: Row(
        children: [
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: AppTypography.bold,
                color: AppColors.black,
              ),
            ),
          ),
          if (icon != null) ...[
            InkWell(
              onTap: onTap,
              child: SizedBox.square(
                dimension: 28,
                child: Icon(icon, size: 16, color: AppColors.neutral500),
              ),
            ),
            const SizedBox(width: 5),
          ] else
            const SizedBox(width: 10),
        ],
      ),
    );
  }
}

class _ModelPhoto extends StatelessWidget {
  const _ModelPhoto({
    required this.asset,
    required this.label,
    super.key,
  });

  final String asset;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: const Color(0xFFEEEAE2),
            child: _AssetImage(asset),
          ),
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              color: AppColors.black,
              child: Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: AppTypography.bold,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardMeta extends StatelessWidget {
  const _CardMeta({required this.model});

  final _HouseModel model;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 42),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          Container(
            constraints: const BoxConstraints(minWidth: 22),
            height: 20,
            padding: const EdgeInsets.symmetric(horizontal: 5),
            color: AppColors.neutral100,
            alignment: Alignment.center,
            child: Text(
              model.gender.badge,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: AppTypography.bold,
                color: AppColors.neutral500,
              ),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              model.body.label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: AppColors.neutral500),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModelEmptyState extends StatelessWidget {
  const _ModelEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 34),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.neutral200),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.groups_outlined,
            size: 28,
            color: AppColors.neutral500,
          ),
          SizedBox(height: 12),
          Text(
            'No models found',
            style: TextStyle(
              fontSize: 15,
              fontWeight: AppTypography.bold,
              color: AppColors.black,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Try clearing a filter to see more models.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppColors.neutral500),
          ),
        ],
      ),
    );
  }
}
