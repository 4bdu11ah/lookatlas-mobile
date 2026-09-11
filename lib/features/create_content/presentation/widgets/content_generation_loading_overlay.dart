import 'package:flutter/material.dart';
import 'package:look_atlas/features/create_content/domain/entities/content_models.dart';
import 'package:look_atlas/shared/widgets/bar_spinner.dart';

String contentGenerationPhaseLabel(String? phase) => switch (phase) {
  'reading_product' => 'Reading your product',
  'directing_story' => 'Directing the story',
  'building_visuals' => 'Building the visuals',
  'writing_publishing_kit' => 'Writing the publishing kit',
  'finishing' => 'Finishing your content',
  null => 'Reading your product',
  _ => 'Working on your content',
};

class ContentGenerationLoadingOverlay extends StatelessWidget {
  const ContentGenerationLoadingOverlay({
    required this.format,
    this.generation,
    super.key,
  });

  final ContentFormat format;
  final ContentGeneration? generation;

  @override
  Widget build(BuildContext context) {
    final progress = generation?.data['progress'] as num?;
    final textTheme = Theme.of(context).textTheme;
    return ColoredBox(
      color: const Color(0xd1131311),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .12),
                  border: Border.all(color: Colors.white.withValues(alpha: .2)),
                ),
                child: const BarSpinner(color: Colors.white),
              ),
              const SizedBox(height: 20),
              Text(
                contentGenerationPhaseLabel(
                  generation?.data['phase'] as String?,
                ),
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontFamily: 'InstrumentSerif',
                  fontSize: 28,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                format == ContentFormat.slideshow
                    ? 'Building one connected visual world, frame by frame.'
                    : 'Composing the visual and publishing copy.',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: .6),
                  fontSize: 11,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 230,
                child: LinearProgressIndicator(
                  minHeight: 2,
                  value: ((progress ?? 0) / 100).clamp(0.0, 1.0),
                  color: const Color(0xff83a98b),
                  backgroundColor: Colors.white.withValues(alpha: .16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
