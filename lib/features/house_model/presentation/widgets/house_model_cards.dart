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
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 205,
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
    _pageController.animateToPage(
      angle.index,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
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

class _UserModelCard extends ConsumerStatefulWidget {
  const _UserModelCard({
    required this.model,
    required this.onToast,
    super.key,
  });

  final _HouseModel model;
  final ValueChanged<String> onToast;

  @override
  ConsumerState<_UserModelCard> createState() => _UserModelCardState();
}

class _UserModelCardState extends ConsumerState<_UserModelCard> {
  var _selectedPhoto = 0;

  List<String> get _photos => widget.model.photoUrls.isEmpty
      ? [widget.model.asset]
      : widget.model.photoUrls;

  @override
  void didUpdateWidget(covariant _UserModelCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedPhoto >= _photos.length) _selectedPhoto = 0;
  }

  @override
  Widget build(BuildContext context) {
    final model = widget.model;
    final photos = _photos;
    return _ModelCardFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        model.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: AppTypography.bold,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                    Tooltip(
                      message: 'Edit model',
                      child: InkWell(
                        onTap: () => _showModelFormDialog(
                          context,
                          ref,
                          widget.onToast,
                          model,
                        ),
                        child: const SizedBox.square(
                          dimension: 32,
                          child: Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: AppColors.neutral500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Tooltip(
                      message: 'Delete model',
                      child: InkWell(
                        onTap: () => unawaited(
                          _showDeleteSheet(
                            context,
                            ref,
                            model,
                            widget.onToast,
                          ),
                        ),
                        child: const SizedBox.square(
                          dimension: 32,
                          child: Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: AppColors.neutral500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      height: 20,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      color: AppColors.neutral100,
                      alignment: Alignment.center,
                      child: Text(
                        model.gender.label,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: AppTypography.bold,
                          color: AppColors.neutral500,
                        ),
                      ),
                    ),
                    if (model.ageRange != 'Not specified') ...[
                      const SizedBox(width: 8),
                      Text(
                        'Age ${model.ageRange}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.neutral500,
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    Text(
                      model.heightLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.neutral500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 9 / 16,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildPhotoPager(model, photos),
            ),
          ),
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoPager(_HouseModel model, List<String> photos) {
    if (photos.length == 1) {
      return ColoredBox(
        color: const Color(0xFFEEEAE2),
        child: _AssetImage(photos.single),
      );
    }
    return Stack(
      children: [
        PageView.builder(
          key: ValueKey('user-model-${model.id}-photo-pager'),
          itemCount: photos.length,
          onPageChanged: (index) => setState(() => _selectedPhoto = index),
          itemBuilder: (context, index) => ColoredBox(
            key: ValueKey('user-model-${model.id}-photo-$index'),
            color: const Color(0xFFEEEAE2),
            child: _AssetImage(photos[index]),
          ),
        ),
        Positioned(
          right: 8,
          bottom: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            color: AppColors.blackAlpha60,
            child: Text(
              '${_selectedPhoto + 1} / ${photos.length}',
              style: const TextStyle(fontSize: 11, color: AppColors.white),
            ),
          ),
        ),
      ],
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
  const _CardTop({required this.title});

  final String title;

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
