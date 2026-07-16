part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

enum _GuideCalloutType { info, tip, warning, success }

class _GuideStack extends StatelessWidget {
  const _GuideStack({required this.children, this.gap = 32});

  final List<Widget> children;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < children.length; index++) ...[
          children[index],
          if (index != children.length - 1) SizedBox(height: gap),
        ],
      ],
    );
  }
}

class _GuideSection extends StatelessWidget {
  const _GuideSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return _GuideStack(
      gap: 16,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            height: 1.4,
            fontWeight: AppTypography.bold,
          ),
        ),
        ...children,
      ],
    );
  }
}

class _GuideIntroSection extends StatelessWidget {
  const _GuideIntroSection({
    required this.title,
    required this.body,
    this.largeBody = false,
  });

  final String title;
  final String body;
  final bool largeBody;

  @override
  Widget build(BuildContext context) {
    return _GuideStack(
      gap: 16,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            height: 1.33,
            fontWeight: AppTypography.bold,
          ),
        ),
        Text(
          body,
          style: TextStyle(
            fontSize: largeBody ? 16 : 14,
            height: largeBody ? 1.56 : 1.5,
            color: AppColors.neutral500,
          ),
        ),
      ],
    );
  }
}

class _GuideFeatureCard extends StatelessWidget {
  const _GuideFeatureCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return _GuideBorderedCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GuideFeatureIcon(icon: icon),
          const SizedBox(height: 16),
          _GuideCardTitle(title),
          const SizedBox(height: 8),
          _GuideBodyText(body),
        ],
      ),
    );
  }
}

class _GuideStep extends StatelessWidget {
  const _GuideStep({
    required this.number,
    required this.title,
    required this.body,
    this.extra,
  });

  final int number;
  final String title;
  final String body;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    return _GuideBorderedCard(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GuideNumberBox(number: '$number'),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    height: 1.39,
                    fontWeight: AppTypography.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _GuideBodyText(body),
                if (extra != null) ...[
                  const SizedBox(height: 12),
                  extra!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideCallout extends StatelessWidget {
  const _GuideCallout({
    required this.type,
    required this.text,
    this.strongPrefix,
  });

  final _GuideCalloutType type;
  final String? strongPrefix;
  final String text;

  @override
  Widget build(BuildContext context) {
    final dark = type == _GuideCalloutType.success;
    final warning = type == _GuideCalloutType.warning;
    final icon = switch (type) {
      _GuideCalloutType.info => Icons.info_outline,
      _GuideCalloutType.tip => Icons.lightbulb_outline,
      _GuideCalloutType.warning => Icons.warning_amber_outlined,
      _GuideCalloutType.success => Icons.check,
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark
            ? AppColors.black
            : warning
            ? AppColors.white
            : AppColors.neutral100,
        border: Border.all(
          color: warning || dark ? AppColors.black : AppColors.neutral200,
          width: warning ? 2 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: dark ? AppColors.white : AppColors.black),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  if (strongPrefix != null)
                    TextSpan(
                      text: strongPrefix,
                      style: const TextStyle(fontWeight: AppTypography.bold),
                    ),
                  TextSpan(text: text),
                ],
              ),
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: dark ? AppColors.white : AppColors.neutral500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideBorderedCard extends StatelessWidget {
  const _GuideBorderedCard({required this.child, required this.padding});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.neutral200),
      ),
      child: child,
    );
  }
}

class _GuideContentCard extends StatelessWidget {
  const _GuideContentCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return _GuideBorderedCard(
      padding: const EdgeInsets.all(20),
      child: _GuideStack(gap: 16, children: children),
    );
  }
}

class _GuideFeatureIcon extends StatelessWidget {
  const _GuideFeatureIcon({required this.icon, this.size = 40});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: AppColors.black,
      child: Icon(icon, size: 20, color: AppColors.white),
    );
  }
}

class _GuideNumberBox extends StatelessWidget {
  const _GuideNumberBox({required this.number, this.size = 32});

  final String number;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      color: AppColors.black,
      child: Text(
        number,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: AppTypography.bold,
          color: AppColors.white,
        ),
      ),
    );
  }
}

class _GuideCardTitle extends StatelessWidget {
  const _GuideCardTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        height: 1.5,
        fontWeight: AppTypography.bold,
      ),
    );
  }
}

class _GuideBodyText extends StatelessWidget {
  const _GuideBodyText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        height: 1.5,
        color: AppColors.neutral500,
      ),
    );
  }
}

class _GuideRouteButton extends StatelessWidget {
  const _GuideRouteButton({
    required this.label,
    required this.onTap,
    this.outlined = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: outlined ? AppColors.white : AppColors.black,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            border: outlined
                ? Border.all(color: AppColors.black, width: 2)
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: AppTypography.medium,
                    color: outlined ? AppColors.black : AppColors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward,
                size: 16,
                color: outlined ? AppColors.black : AppColors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuideScreenshotPlaceholder extends StatelessWidget {
  const _GuideScreenshotPlaceholder({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return AppDottedBorder(
      color: AppColors.neutral200,
      strokeWidth: 2,
      child: Container(
        constraints: const BoxConstraints(minHeight: 200),
        padding: const EdgeInsets.all(32),
        color: AppColors.neutral100Alpha68,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.image_outlined,
              size: 40,
              color: AppColors.neutral500,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: AppTypography.medium,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Screenshot coming soon',
              style: TextStyle(fontSize: 12, color: AppColors.neutral400),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideCheckRow extends StatelessWidget {
  const _GuideCheckRow({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return _GuideBorderedCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check, size: 20, color: Color(0xFF16A34A)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: AppTypography.bold,
                  ),
                ),
                _GuideBodyText(body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideBulletList extends StatelessWidget {
  const _GuideBulletList({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return _GuideStack(
      gap: 4,
      children: [
        for (final item in items)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  width: 4,
                  height: 4,
                  color: AppColors.neutral500,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: _GuideBodyText(item)),
            ],
          ),
      ],
    );
  }
}
