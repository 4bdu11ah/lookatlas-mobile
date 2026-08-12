part of '../screens/dashboard_screen.dart';

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.title,
    required this.body,
    this.small = false,
  });

  final String title;
  final String body;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          softWrap: true,
          style:
              (small
                      ? Theme.of(context).textTheme.headlineSmall
                      : Theme.of(context).textTheme.headlineMedium)
                  ?.copyWith(
                    height: small ? 1.1 : 1.05,
                    letterSpacing: -0.6,
                    color: AppColors.black,
                  ),
        ),
        const SizedBox(height: 6),
        _BodyText(body),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      softWrap: true,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        height: 1.2,
        letterSpacing: -0.2,
        color: AppColors.black,
      ),
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle(
    this.text, {
    this.fontSize,
    this.color,
  });

  final String text;
  final double? fontSize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      overflow: TextOverflow.ellipsis,
      maxLines: 2,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        height: 1.2,
        fontSize: fontSize,
        color: color ?? AppColors.black,
      ),
    );
  }
}

class _BodyText extends StatelessWidget {
  const _BodyText(this.text, {this.textAlign});

  final String text;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      softWrap: true,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        height: 1.55,
        color: AppColors.neutral500,
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption(
    this.text, {
    this.fontSize,
    this.color,
  });

  final String text;
  final double? fontSize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      softWrap: true,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        height: 1.45,
        fontSize: fontSize,
        color: color ?? AppColors.neutral500,
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text, {this.maxLines = 1});

  final String text;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      maxLines: maxLines,
      overflow: maxLines == 1 ? TextOverflow.ellipsis : TextOverflow.visible,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        height: 1.3,
        letterSpacing: 1.1,
        fontWeight: AppTypography.bold,
        color: AppColors.neutral500,
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        fontWeight: AppTypography.bold,
        color: AppColors.black,
      ),
    );
  }
}
