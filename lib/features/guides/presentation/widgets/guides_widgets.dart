part of '../screens/guides_page.dart';

class _GuideBlock extends StatelessWidget {
  const _GuideBlock(this.block, {required this.onNavigate});
  final LearningGuideBlock block;
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) => switch (block.kind) {
    GuideBlockKind.heading => _heading(),
    GuideBlockKind.feature => _feature(),
    GuideBlockKind.step => _step(),
    GuideBlockKind.tip => _tip(),
    GuideBlockKind.checklist => _checklist(),
    GuideBlockKind.figure => _figure(),
    GuideBlockKind.actions => _actions(),
  };

  Widget _heading() => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Text(
      block.title,
      style: LearningCenterStyle.body(
        16,
        color: LearningCenterStyle.ink,
        weight: FontWeight.w700,
      ),
    ),
  );

  Widget _feature() => _GuideCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          color: LearningCenterStyle.ink,
          alignment: Alignment.center,
          child: _GuideSvg(
            block.iconSvg,
            color: LearningCenterStyle.paper,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          block.title,
          style: LearningCenterStyle.body(
            14,
            color: LearningCenterStyle.ink,
            weight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        _GuideParagraphs(block.paragraphs),
      ],
    ),
  );

  Widget _step() => _GuideCard(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          color: LearningCenterStyle.ink,
          alignment: Alignment.center,
          child: Text(
            block.number,
            style: LearningCenterStyle.body(
              12,
              color: LearningCenterStyle.paper,
              weight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                block.title,
                style: LearningCenterStyle.body(
                  15,
                  color: LearningCenterStyle.ink,
                  weight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              _GuideParagraphs(block.paragraphs),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _tip() => _GuideCard(
    padding: 15,
    soft: true,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: _GuideSvg(block.iconSvg, size: 17),
        ),
        const SizedBox(width: 12),
        Expanded(child: _GuideParagraphs(block.paragraphs, size: 12)),
      ],
    ),
  );

  Widget _checklist() => _GuideCard(
    soft: true,
    child: Column(
      children: [
        for (var i = 0; i < block.paragraphs.length; i++)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    LucideIcons.check,
                    size: 15,
                    color: LearningCenterStyle.ink,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _GuideRichText(block.paragraphs[i], height: 1.55),
                ),
              ],
            ),
          ),
      ],
    ),
  );

  Widget _figure() => _GuideCard(
    soft: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomPaint(
          foregroundPainter: const _GuideDashedBorder(),
          child: Container(
            height: 90,
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _GuideSvg(block.iconSvg),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    block.title,
                    style: LearningCenterStyle.body(
                      12,
                      weight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          block.paragraphs.first.map((run) => run.$1).join().toUpperCase(),
          style: LearningCenterStyle.body(
            11,
            weight: FontWeight.w700,
          ).copyWith(letterSpacing: 0.55),
        ),
      ],
    ),
  );

  Widget _actions() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < block.actions.length; i++)
        Padding(
          padding: EdgeInsets.only(top: i == 0 ? 0 : 8),
          child: LearningAction(
            block.actions[i].$1,
            onPressed: () => onNavigate(block.actions[i].$2),
          ),
        ),
    ],
  );
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({required this.child, this.padding = 18, this.soft = false});
  final Widget child;
  final double padding;
  final bool soft;
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(padding),
    decoration: BoxDecoration(
      color: soft ? const Color(0xFFF3F2EC) : Colors.white,
      border: Border.all(color: LearningCenterStyle.line),
    ),
    child: child,
  );
}

class _GuideSvg extends StatelessWidget {
  const _GuideSvg(
    this.svg, {
    this.color = LearningCenterStyle.ink,
    this.size = 18,
  });
  final String svg;
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) => SvgPicture.string(
    svg,
    width: size,
    height: size,
    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
  );
}

class _GuideParagraphs extends StatelessWidget {
  const _GuideParagraphs(this.paragraphs, {this.size = 12.5});
  final List<GuideTextRuns> paragraphs;
  final double size;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (var i = 0; i < paragraphs.length; i++)
        Padding(
          padding: EdgeInsets.only(top: i == 0 ? 0 : 8),
          child: _GuideRichText(paragraphs[i], size: size),
        ),
    ],
  );
}

class _GuideRichText extends StatelessWidget {
  const _GuideRichText(this.runs, {this.size = 12.5, this.height = 1.6});
  final GuideTextRuns runs;
  final double size;
  final double height;
  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      children: [
        for (final (text, bold) in runs)
          TextSpan(
            text: text,
            style: bold
                ? const TextStyle(
                    color: LearningCenterStyle.ink,
                    fontWeight: FontWeight.w700,
                  )
                : null,
          ),
      ],
    ),
    style: LearningCenterStyle.body(
      size,
      height: height,
      color: const Color(0xFF707069),
    ),
  );
}

class _GuideDashedBorder extends CustomPainter {
  const _GuideDashedBorder();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = LearningCenterStyle.line
      ..style = PaintingStyle.stroke;
    final corners = [
      Offset.zero,
      Offset(size.width, 0),
      Offset(size.width, size.height),
      Offset(0, size.height),
    ];
    for (var edge = 0; edge < corners.length; edge++) {
      final start = corners[edge];
      final delta = corners[(edge + 1) % corners.length] - start;
      final length = delta.distance;
      for (double position = 0; position < length; position += 8) {
        canvas.drawLine(
          start + delta * (position / length),
          start + delta * ((position + 4).clamp(0, length) / length),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_GuideDashedBorder oldDelegate) => false;
}
