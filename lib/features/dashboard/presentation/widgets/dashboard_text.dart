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
          style: TextStyle(
            fontSize: small ? 24 : 30,
            height: small ? 1.1 : 1.05,
            fontWeight: AppTypography.bold,
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
      style: const TextStyle(
        fontSize: 20,
        height: 1.2,
        fontWeight: AppTypography.bold,
        letterSpacing: -0.2,
        color: AppColors.black,
      ),
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      overflow: TextOverflow.ellipsis,
      maxLines: 2,
      style: const TextStyle(
        fontSize: 15,
        height: 1.2,
        fontWeight: AppTypography.bold,
        color: AppColors.black,
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
      style: const TextStyle(
        fontSize: 14,
        height: 1.55,
        color: AppColors.neutral500,
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      softWrap: true,
      style: const TextStyle(
        fontSize: 12,
        height: 1.45,
        color: AppColors.neutral500,
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 11,
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
      style: const TextStyle(
        fontSize: 12,
        fontWeight: AppTypography.bold,
        color: AppColors.black,
      ),
    );
  }
}
