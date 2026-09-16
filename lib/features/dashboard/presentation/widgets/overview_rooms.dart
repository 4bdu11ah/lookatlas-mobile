import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/features/dashboard/presentation/widgets/overview_style.dart';

class OverviewBrandRoom extends StatelessWidget {
  const OverviewBrandRoom({super.key});
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: OverviewStyle.ink,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(
          height: 220,
          child: OverviewImage(
            'assets/images/dashboard/brand_studio.jpg',
            label: 'Brand Studio Environment',
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OverviewLabel(
                'Featured room',
                color: OverviewStyle.paper.withValues(alpha: .55),
              ),
              const SizedBox(height: 10),
              Text(
                'Build the world around your product.',
                style: OverviewStyle.serif(32, color: OverviewStyle.paper),
              ),
              const SizedBox(height: 10),
              Text(
                'Turn an approved shoot into a complete campaign for your store, email, and launch story.',
                style: OverviewStyle.body(
                  12,
                  height: 1.6,
                  color: OverviewStyle.paper.withValues(alpha: .7),
                ),
              ),
              const SizedBox(height: 24),
              const OverviewComingSoon(label: 'Brand Studio is coming soon'),
            ],
          ),
        ),
      ],
    ),
  );
}

class OverviewCreativeRooms extends StatelessWidget {
  const OverviewCreativeRooms({super.key});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const OverviewSectionHeading(
        index: '04',
        label: 'Creative rooms',
        title: 'More ways to shape the work.',
      ),
      const SizedBox(height: 14),
      const _CreativeRoom(
        label: 'Design Boards',
        title: 'Give every shoot a point of view.',
        body: 'Turn visual taste into a reusable Director and an exact shot recipe for every product.',
        photo: 'assets/images/dashboard/design_boards.jpg',
      ),
      const SizedBox(height: 16),
      const _CreativeRoom(
        label: 'Lookbooks',
        title: 'Turn a shoot into a story.',
        body: 'Publish one collection for customers, buyers, and press.',
        photo: 'assets/images/dashboard/lookbooks.jpg',
      ),
      const SizedBox(height: 16),
      _CreativeRoom(
        label: 'Social Studio',
        title: 'Plan the next month, not the next post.',
        body: 'Create campaign content, then organise it into your publishing calendar.',
        photo: 'assets/images/dashboard/social_studio.jpg',
        action: OverviewLink(
          'Create content',
          size: 10,
          onTap: () => context.push(AppRoutes.createContent),
        ),
      ),
      const SizedBox(height: 16),
      const _CreativeRoom(
        label: 'Human finishing',
        title: 'When the last five percent matters.',
        body: 'Send a chosen image to our team for a careful, professional touch-up.',
        photo: 'assets/images/dashboard/human_finishing.jpg',
      ),
    ],
  );
}

class _CreativeRoom extends StatelessWidget {
  const _CreativeRoom({
    required this.label,
    required this.title,
    required this.body,
    required this.photo,
    this.action,
  });
  final String label;
  final String title;
  final String body;
  final String photo;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(border: Border.all(color: OverviewStyle.line)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 160, child: OverviewImage(photo, label: label)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OverviewLabel(label),
              const SizedBox(height: 8),
              Text(title, style: OverviewStyle.serif(26)),
              const SizedBox(height: 8),
              Text(body, style: OverviewStyle.body(11, height: 1.6)),
              const SizedBox(height: 18),
              action ?? const OverviewComingSoon(),
            ],
          ),
        ),
      ],
    ),
  );
}

class OverviewComingSoon extends StatelessWidget {
  const OverviewComingSoon({this.label = 'Coming soon', super.key});
  final String label;
  @override
  Widget build(BuildContext context) => Semantics(
    enabled: false,
    child: Container(
      color: OverviewStyle.soft,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      child: Text(
        label.toUpperCase(),
        style: OverviewStyle.body(9, bold: true).copyWith(letterSpacing: .45),
      ),
    ),
  );
}

class OverviewLearningStrip extends StatelessWidget {
  const OverviewLearningStrip({super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.only(top: 20),
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: OverviewStyle.line)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const OverviewLabel('Learning Center'),
        const SizedBox(height: 4),
        Text(
          'Learn the craft behind stronger shoots.',
          style: OverviewStyle.serif(28, height: 1.1),
        ),
        const SizedBox(height: 12),
        Text(
          'Short guides and video tutorials for brand owners, from product prep to campaign direction.',
          style: OverviewStyle.body(11.5),
        ),
        const SizedBox(height: 12),
        OverviewLink(
          'Explore learning',
          underline: true,
          onTap: () => context.push(AppRoutes.studioSchool),
        ),
      ],
    ),
  );
}
