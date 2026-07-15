import 'package:flutter/material.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/core/theme/app_typography.dart';

class AppDropdownConfig {
  const AppDropdownConfig({
    this.height = 48,
    this.menuMaxHeight = 240,
    this.menuGap = 4,
    this.backgroundColor = AppColors.white,
    this.borderColor = AppColors.neutral200,
    this.focusedBorderColor = AppColors.black,
    this.menuBorderColor = AppColors.neutral200,
    this.selectedItemColor = AppColors.neutral100,
    this.textColor = AppColors.black,
    this.mutedColor = AppColors.neutral500,
    this.horizontalPadding = 14,
  });

  static const AppDropdownConfig standard = AppDropdownConfig();

  final double height;
  final double menuMaxHeight;
  final double menuGap;
  final Color backgroundColor;
  final Color borderColor;
  final Color focusedBorderColor;
  final Color menuBorderColor;
  final Color selectedItemColor;
  final Color textColor;
  final Color mutedColor;
  final double horizontalPadding;
}

class AppDropdown<T> extends StatefulWidget {
  const AppDropdown({
    required this.values,
    required this.labelFor,
    required this.onChanged,
    this.value,
    this.hintText,
    this.enabled = true,
    this.config = AppDropdownConfig.standard,
    super.key,
  });

  final T? value;
  final List<T> values;
  final String Function(T value) labelFor;
  final ValueChanged<T> onChanged;
  final String? hintText;
  final bool enabled;
  final AppDropdownConfig config;

  @override
  State<AppDropdown<T>> createState() => _AppDropdownState<T>();
}

class _AppDropdownState<T> extends State<AppDropdown<T>> {
  final _layerLink = LayerLink();
  final GlobalKey _fieldKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  bool _open = false;

  @override
  void didUpdateWidget(covariant AppDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _overlayEntry?.markNeedsBuild();
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _open = false;
    super.dispose();
  }

  void _toggleOverlay() {
    if (!widget.enabled) return;
    if (_open) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _showOverlay() {
    final renderBox =
        _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;
    final fieldSize = renderBox.size;
    final overlay = Overlay.of(context);

    setState(() => _open = true);
    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _removeOverlay,
            ),
          ),
          CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0, fieldSize.height + widget.config.menuGap),
            child: SizedBox(
              width: fieldSize.width,
              child: _AppDropdownMenu<T>(
                value: widget.value,
                values: widget.values,
                labelFor: widget.labelFor,
                config: widget.config,
                onSelected: (value) {
                  widget.onChanged(value);
                  _removeOverlay();
                },
              ),
            ),
          ),
        ],
      ),
    );
    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted && _open) setState(() => _open = false);
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.config;
    final value = widget.value;
    final label = value == null ? widget.hintText : widget.labelFor(value);
    final textColor = value == null ? config.mutedColor : config.textColor;

    return CompositedTransformTarget(
      link: _layerLink,
      child: Semantics(
        button: true,
        expanded: _open,
        child: InkWell(
          key: _fieldKey,
          onTap: _toggleOverlay,
          child: Container(
            height: config.height,
            padding: EdgeInsets.symmetric(horizontal: config.horizontalPadding),
            decoration: BoxDecoration(
              color: config.backgroundColor,
              border: Border.all(
                color: _open ? config.focusedBorderColor : config.borderColor,
                width: _open ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: AppTypography.medium,
                      color: textColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  _open ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 18,
                  color: config.mutedColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppDropdownMenu<T> extends StatelessWidget {
  const _AppDropdownMenu({
    required this.value,
    required this.values,
    required this.labelFor,
    required this.config,
    required this.onSelected,
  });

  final T? value;
  final List<T> values;
  final String Function(T value) labelFor;
  final AppDropdownConfig config;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: config.backgroundColor,
          border: Border.all(color: config.menuBorderColor),
          boxShadow: const [
            BoxShadow(
              color: AppColors.blackAlpha15,
              blurRadius: 18,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: config.menuMaxHeight),
          child: ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: values.length,
            itemBuilder: (context, index) {
              final item = values[index];
              final selected = item == value;
              return InkWell(
                onTap: () => onSelected(item),
                child: Container(
                  height: config.height,
                  color: selected ? config.selectedItemColor : null,
                  padding: EdgeInsets.symmetric(
                    horizontal: config.horizontalPadding,
                  ),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    labelFor(item),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: selected
                          ? AppTypography.bold
                          : AppTypography.medium,
                      color: config.textColor,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
