import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:look_atlas/core/providers/core_providers.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/core/theme/app_colors.dart';
import 'package:look_atlas/core/theme/app_typography.dart';
import 'package:look_atlas/features/auth/di/auth_providers.dart';
import 'package:look_atlas/features/create_content/di/content_providers.dart';
import 'package:look_atlas/features/create_content/domain/entities/content_models.dart';
import 'package:look_atlas/features/create_content/presentation/controllers/create_content_controller.dart';
import 'package:look_atlas/features/create_content/presentation/widgets/content_widgets.dart';
import 'package:look_atlas/features/dashboard/di/dashboard_providers.dart';
import 'package:look_atlas/shared/widgets/app_icon_button.dart';
import 'package:look_atlas/shared/widgets/app_image.dart';
import 'package:look_atlas/shared/widgets/app_snack_bar.dart';
import 'package:look_atlas/shared/widgets/custom_app_bar.dart';
import 'package:look_atlas/shared/widgets/primary_button.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ContentHubScreen extends ConsumerWidget {
  const ContentHubScreen({super.key});

  Widget _hubDisplay(BuildContext context, String text, double size) => Text(
    text,
    style: Theme.of(context).textTheme.displayLarge?.copyWith(
      fontFamily: 'Georgia',
      fontFamilyFallback: const ['serif'],
      fontSize: size,
      height: 1,
      letterSpacing: -size * .03,
      fontWeight: AppTypography.regular,
    ),
  );

  void _choose(BuildContext context, ContentFormat format) =>
      context.go('${AppRoutes.createContent}/${format.name}');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(contentHistoryProvider);
    final discardingDraftId = ref.watch(
      createContentControllerProvider.select((s) => s.discardingDraftId),
    );

    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: const Color(0xfffbfbf8),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xfffbfbf8),
          foregroundColor: AppColors.ink,
        ),
        textTheme: Theme.of(context).textTheme.apply(
          bodyColor: AppColors.ink,
          displayColor: AppColors.ink,
          letterSpacingFactor: 0,
        ),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xfffbfbf8),
        appBar: CustomAppBar(
          title: 'Create Content',
          showBackButton: true,
          onBack: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
        body: SafeArea(
          top: false,
          child: RefreshIndicator(
            onRefresh: () async {
              ref
                ..invalidate(contentHistoryProvider)
                ..invalidate(dashboardStatsProvider);
              await ref.read(contentHistoryProvider.future);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 30, 16, 40),
              children: [
                contentEyebrow('Social studio'),
                const SizedBox(height: 5),
                contentDisplay('Create content', 44),
                const SizedBox(height: 16),
                contentBody(
                  'Choose a format. We’ll turn one product into the visuals and publishing copy.',
                ),
                const SizedBox(height: 28),
                contentRule(),
                const SizedBox(height: 17),
                contentEyebrow('Choose a format'),
                const SizedBox(height: 5),
                _hubDisplay(context, 'What would you like to make?', 29),
                const SizedBox(height: 21),
                _formatFeature(context),
                const SizedBox(height: 18),
                _secondary(context, ContentFormat.single),
                const SizedBox(height: 18),
                _secondary(context, ContentFormat.video),
                ...history.when(
                  data: (data) => _history(
                    context,
                    ref,
                    data.$1,
                    data.$2,
                    discardingDraftId,
                  ),
                  loading: () => const [],
                  error: (e, s) => [
                    const SizedBox(height: 20),
                    contentErrorBox(
                      'Your content history could not be loaded.',
                      () => ref.invalidate(contentHistoryProvider),
                    ),
                  ],
                ),
                const SizedBox(height: 38),
                contentRule(),
                const SizedBox(height: 30),
                _learning(context),
                const SizedBox(height: 38),
                contentRule(),
                const SizedBox(height: 28),
                contentEyebrow('Growth library'),
                const SizedBox(height: 6),
                _hubDisplay(
                  context,
                  'Make better content, more consistently.',
                  24,
                ),
                const SizedBox(height: 12),
                contentBody(
                  'Campaign breakdowns, practical guides, and clear tutorials made for brand owners.',
                ),
                const SizedBox(height: 22),
                _featuredCaseStudy(context),
                _guides(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _featuredCaseStudy(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.ink,
        border: Border.all(color: AppColors.ink),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 320,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/create_content/case-study-fashion-system-v3.webp',
                  fit: BoxFit.cover,
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0x99171715),
                          border: Border.all(
                            color: const Color(0x33ffffff),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: IntrinsicHeight(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'SOURCE\nPRODUCT',
                                textAlign: TextAlign.center,
                                style: textTheme.labelSmall?.copyWith(
                                  fontSize: 10,
                                  height: 1.15,
                                  color: Colors.white,
                                  fontWeight: AppTypography.bold,
                                  letterSpacing: .6,
                                ),
                              ),
                              const VerticalDivider(
                                width: 1,
                                thickness: 1,
                                color: Color(0x44ffffff),
                              ),
                              Text(
                                'CAMPAIGN\nASSETS',
                                textAlign: TextAlign.center,
                                style: textTheme.labelSmall?.copyWith(
                                  fontSize: 10,
                                  height: 1.15,
                                  color: Colors.white,
                                  fontWeight: AppTypography.bold,
                                  letterSpacing: .6,
                                ),
                              ),
                              const VerticalDivider(
                                width: 1,
                                thickness: 1,
                                color: Color(0x44ffffff),
                              ),
                              Text(
                                '14-DAY SYSTEM',
                                textAlign: TextAlign.center,
                                style: textTheme.labelSmall?.copyWith(
                                  fontSize: 10,
                                  height: 1.15,
                                  color: Colors.white,
                                  fontWeight: AppTypography.bold,
                                  letterSpacing: .6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FEATURED CASE STUDY',
                  style: textTheme.labelSmall?.copyWith(
                    fontSize: 11,
                    fontWeight: AppTypography.bold,
                    letterSpacing: 1.2,
                    color: const Color(0xff8e8e88),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'How one launch became fourteen days of content.',
                  style: textTheme.headlineSmall?.copyWith(
                    fontFamily: 'Georgia',
                    fontFamilyFallback: const ['serif'],
                    fontSize: 27,
                    height: 1.15,
                    letterSpacing: -0.5,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'A practical breakdown of how one product campaign was adapted into single posts, slideshow stories, and short-form video without losing its visual identity — the same system this studio automates for you.',
                  style: textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                    height: 1.55,
                    color: const Color(0xffc5c5be),
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xff2a2a26),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    for (final (index, fact) in [
                      ('01', 'Campaign source'),
                      ('03', 'Content formats'),
                      ('14', 'Day content plan'),
                    ].indexed) ...[
                      if (index > 0)
                        const SizedBox(
                          height: 48,
                          child: VerticalDivider(
                            width: 1,
                            thickness: 1,
                            color: Color(0xff2a2a26),
                          ),
                        ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fact.$1,
                              style: textTheme.headlineMedium?.copyWith(
                                fontFamily: 'Georgia',
                                fontFamilyFallback: const ['serif'],
                                fontSize: 26,
                                height: 1,
                                color: Colors.white,
                                fontWeight: AppTypography.regular,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              fact.$2,
                              style: textTheme.labelSmall?.copyWith(
                                fontSize: 10,
                                height: 1.2,
                                color: const Color(0xff808078),
                                fontWeight: AppTypography.medium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xff2a2a26),
                ),
                const SizedBox(height: 28),
                InkWell(
                  onTap: () => context.push<void>(AppRoutes.studioSchool),
                  child: Row(
                    children: [
                      Text(
                        'READ THE CASE STUDY',
                        style: textTheme.labelSmall?.copyWith(
                          fontSize: 12,
                          fontWeight: AppTypography.bold,
                          letterSpacing: 0.8,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        LucideIcons.arrowRight,
                        size: 16,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _guides(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final resources = [
      (
        'GUIDE',
        '6 MIN',
        'Build a slideshow people finish.',
        'Open on the strongest frame, not the product shot. Give every frame one job — hook, context, story, detail, finish — and end on what to do next.',
        'READ THE GUIDE',
      ),
      (
        'TUTORIAL',
        '8 MIN',
        'Turn one shoot into a two-week plan.',
        'One campaign becomes a single post, a slideshow, a detail close-up, and a video — spaced so the feed feels planned rather than repeated.',
        'WATCH THE TUTORIAL',
      ),
      (
        'ARTICLE',
        '5 MIN',
        'Write captions that sound like your brand.',
        'Name the material, the detail, or the reason it exists. Specific beats clever, and one confident sentence beats three qualifying ones.',
        'READ THE ARTICLE',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final resource in resources)
          Padding(
            padding: const EdgeInsets.only(top: 18),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xffd1d1ca)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 170,
                    color: switch (resource.$1) {
                      'GUIDE' => const Color(0xff553337),
                      'TUTORIAL' => const Color(0xffdedad2),
                      _ => const Color(0xff1f1f1d),
                    },
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(20),
                    child: switch (resource.$1) {
                      'GUIDE' => Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (final (i, h) in [
                            112.0,
                            102.0,
                            114.0,
                            126.0,
                            110.0,
                          ].indexed)
                            Expanded(
                              child: Container(
                                height: h,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                color: const Color(0xffecebe4),
                                alignment: Alignment.bottomLeft,
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  '0${i + 1}',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: const Color(0xff55554f),
                                    fontSize: 12,
                                    fontWeight: AppTypography.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      'TUTORIAL' => Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (final isBlue in [
                                false,
                                true,
                                false,
                                true,
                                false,
                                false,
                                true,
                              ])
                                Container(
                                  width: 32,
                                  height: 32,
                                  margin: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: isBlue
                                        ? const Color(0xff27538c)
                                        : const Color(0xfff6f6f4),
                                    border: Border.all(
                                      color: isBlue
                                          ? const Color(0xff27538c)
                                          : const Color(0xffb5b5ae),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (final isBlue in [
                                false,
                                false,
                                true,
                                false,
                                false,
                                true,
                                false,
                              ])
                                Container(
                                  width: 32,
                                  height: 32,
                                  margin: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: isBlue
                                        ? const Color(0xff27538c)
                                        : const Color(0xfff6f6f4),
                                    border: Border.all(
                                      color: isBlue
                                          ? const Color(0xff27538c)
                                          : const Color(0xffb5b5ae),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      _ => Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: const Icon(
                                LucideIcons.captions,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 28),
                            const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 175,
                                  child: Divider(
                                    height: 1,
                                    thickness: 1.5,
                                    color: Color(0xffc5c5be),
                                  ),
                                ),
                                SizedBox(height: 10),
                                SizedBox(
                                  width: 145,
                                  child: Divider(
                                    height: 1,
                                    thickness: 1.5,
                                    color: Color(0xffc5c5be),
                                  ),
                                ),
                                SizedBox(height: 10),
                                SizedBox(
                                  width: 115,
                                  child: Divider(
                                    height: 1,
                                    thickness: 1.5,
                                    color: Color(0xffc5c5be),
                                  ),
                                ),
                                SizedBox(height: 10),
                                SizedBox(
                                  width: 80,
                                  child: Divider(
                                    height: 1,
                                    thickness: 1.5,
                                    color: Color(0xffc5c5be),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              resource.$1,
                              style: textTheme.labelSmall?.copyWith(
                                fontSize: 11,
                                fontWeight: AppTypography.bold,
                                letterSpacing: 1.2,
                                color: const Color(0xff686861),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              resource.$2,
                              style: textTheme.labelSmall?.copyWith(
                                fontSize: 11,
                                fontWeight: AppTypography.bold,
                                letterSpacing: 1.2,
                                color: const Color(0xff686861),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          resource.$3,
                          style: textTheme.headlineSmall?.copyWith(
                            fontFamily: 'Georgia',
                            fontFamilyFallback: const ['serif'],
                            fontSize: 27,
                            height: 1.15,
                            letterSpacing: -0.5,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xff171715),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          resource.$4,
                          style: textTheme.bodySmall?.copyWith(
                            fontSize: 13,
                            height: 1.55,
                            color: const Color(0xff686861),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: Color(0xffdcdcd5),
                        ),
                        const SizedBox(height: 22),
                        InkWell(
                          onTap: () => context.push<void>(
                            AppRoutes.dashboardGuides,
                          ),
                          child: Row(
                            children: [
                              Text(
                                resource.$5,
                                style: textTheme.labelSmall?.copyWith(
                                  fontSize: 12,
                                  fontWeight: AppTypography.bold,
                                  letterSpacing: 0.8,
                                  color: const Color(0xff171715),
                                ),
                              ),
                              const Spacer(),
                              const Icon(
                                LucideIcons.arrowRight,
                                size: 16,
                                color: Color(0xff171715),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _art(BuildContext context, String file, String label) => Stack(
    fit: StackFit.expand,
    children: [
      Image.asset(
        'assets/images/create_content/$file',
        fit: BoxFit.cover,
      ),
      Positioned(
        left: 12,
        bottom: 12,
        child: Container(
          alignment: Alignment.centerLeft,
          child: Container(
            color: const Color(0xcc121210),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 11,
                color: Colors.white,
                fontWeight: AppTypography.bold,
                letterSpacing: .8,
              ),
            ),
          ),
        ),
      ),
    ],
  );

  Widget _formatFeature(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xfff1f1ed),
        border: Border.all(color: const Color(0xffa9a9a1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      color: AppColors.ink,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      child: Text(
                        'RECOMMENDED',
                        style: textTheme.labelSmall?.copyWith(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: AppTypography.bold,
                          letterSpacing: .8,
                        ),
                      ),
                    ),
                    const Spacer(),
                    contentEyebrow('3–8 frames'),
                  ],
                ),
                const SizedBox(height: 23),
                _hubDisplay(context, 'Slideshow', 42),
                const SizedBox(height: 18),
                Text(
                  'Build a connected visual story around one product, designed to keep people swiping.',
                  style: textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    height: 1.58,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 27),
                contentRule(),
                const SizedBox(height: 18),
                Row(
                  children: [
                    for (final labels in [
                      ['Visual sequence', 'Hashtags'],
                      ['Caption', 'Music direction'],
                    ])
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final label in labels)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Text(
                                  label,
                                  style: textTheme.labelSmall?.copyWith(
                                    fontSize: 11,
                                    fontWeight: AppTypography.bold,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                contentRule(),
                SizedBox(
                  width: 230,
                  child: contentAction(
                    'CREATE SLIDESHOW',
                    () => _choose(context, ContentFormat.slideshow),
                    icon: LucideIcons.arrowRight,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 230,
            child: Row(
              children: [
                Expanded(
                  flex: 112,
                  child: _art(context, 'slideshow-fur-hook-v2.webp', 'HOOK'),
                ),
                const SizedBox(width: 2),
                Expanded(
                  flex: 88,
                  child: Column(
                    children: [
                      Expanded(
                        child: _art(
                          context,
                          'slideshow-fur-hero-v2.webp',
                          'HERO',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Expanded(
                        child: _art(
                          context,
                          'slideshow-fur-detail-v2.webp',
                          'IN USE',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _secondary(BuildContext context, ContentFormat format) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xfff4f4f0),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(21),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    contentEyebrow(
                      format == ContentFormat.single
                          ? 'One image'
                          : 'Short motion',
                    ),
                    const Spacer(),
                    if (format == ContentFormat.single)
                      contentEyebrow('4:5 post')
                    else
                      Container(
                        color: AppColors.ink,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Text(
                          'BETA',
                          style: textTheme.labelSmall?.copyWith(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: AppTypography.bold,
                            letterSpacing: .8,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                _hubDisplay(context, format.label, 31),
                const SizedBox(height: 12),
                contentBody(
                  format == ContentFormat.single
                      ? 'One art-directed visual with its caption and hashtags ready.'
                      : 'A short motion concept from your product and campaign assets.',
                ),
                const SizedBox(height: 20),
                contentAction(
                  format == ContentFormat.single
                      ? 'CREATE A POST'
                      : 'TRY VIDEO BETA',
                  () => _choose(context, format),
                  dark: false,
                  icon: LucideIcons.arrowRight,
                ),
              ],
            ),
          ),
          SizedBox(
            height: 230,
            child: _art(
              context,
              format == ContentFormat.single
                  ? 'single-sapphire-necklace-v3.webp'
                  : 'video-motion-sneaker-v1.webp',
              format == ContentFormat.single ? '4:5 STILL' : '00:08',
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _history(
    BuildContext context,
    WidgetRef ref,
    List<ContentDraft> drafts,
    List<ContentGeneration> items,
    String? discardingDraftId,
  ) {
    if (drafts.isEmpty && items.isEmpty) return [];
    return [
      const SizedBox(height: 36),
      contentRule(),
      const SizedBox(height: 24),
      contentEyebrow('Your content'),
      const SizedBox(height: 6),
      _hubDisplay(
        context,
        drafts.isEmpty
            ? 'Everything you’ve made.'
            : 'Pick up where you left off.',
        29,
      ),
      const SizedBox(height: 20),
      for (final draft in drafts)
        _draftCard(
          context,
          ref,
          draft,
          isDiscarding: discardingDraftId == draft.id,
        ),
      for (final item in items)
        _generationCard(
          context,
          item,
          calendar: item.data['source'] == 'runway',
        ),
    ];
  }

  Widget _draftCard(
    BuildContext context,
    WidgetRef ref,
    ContentDraft draft, {
    required bool isDiscarding,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final title = draft.data['title'] as String? ?? draft.format.label;
    final dateStr = _relativeDate(draft.data['updatedAt']);
    final meta =
        'Continue brief • ${draft.format.label}${dateStr.isNotEmpty ? ' • $dateStr' : ''}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.line),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (isDiscarding) {
              ref
                  .read(createContentControllerProvider.notifier)
                  .setDiscardingDraftId(null);
            } else {
              _choose(context, draft.format);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  color: const Color(0xfff7f3ec),
                  alignment: Alignment.center,
                  child: const Icon(
                    LucideIcons.filePenLine,
                    size: 24,
                    color: Color(0xff9e7239),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleSmall?.copyWith(
                          fontSize: 15,
                          fontWeight: AppTypography.bold,
                          color: AppColors.ink,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          color: const Color(0xff757570),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (isDiscarding)
                  PrimaryButton(
                    label: 'Discard?',
                    fitToContent: true,
                    height: 34,
                    backgroundColor: const Color(0xff8a3a35),
                    foregroundColor: Colors.white,
                    textStyle: textTheme.labelMedium?.copyWith(
                      fontSize: 13,
                      fontWeight: AppTypography.bold,
                      color: Colors.white,
                    ),
                    onPressed: () => _discardDraft(context, ref, draft),
                  )
                else
                  AppIconButton(
                    icon: LucideIcons.x,
                    tooltip: 'Discard draft',
                    color: const Color(0xff757570),
                    size: 16,
                    onPressed: () => ref
                        .read(createContentControllerProvider.notifier)
                        .setDiscardingDraftId(draft.id),
                  ),
                const SizedBox(width: 8),
                const Icon(
                  LucideIcons.arrowRight,
                  size: 18,
                  color: Color(0xff757570),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _generationCard(
    BuildContext context,
    ContentGeneration item, {
    bool calendar = false,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final title = item.title;
    final dateStr = _relativeDate(item.data['createdAt']);
    final meta =
        '${item.format.label} • ${item.frames.length} visuals${dateStr.isNotEmpty ? ' • $dateStr' : ''}';
    final imageUrl = item.frames.firstOrNull?.imageUrl;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.line),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go(
            '${AppRoutes.createContent}/item/${Uri.encodeComponent(item.id)}',
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? (debugNetworkImageHttpClientProvider != null
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  color: AppColors.soft,
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    LucideIcons.image,
                                    size: 20,
                                    color: AppColors.muted,
                                  ),
                                ),
                              )
                            : AppImage(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorWidget: Container(
                                  color: AppColors.soft,
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    LucideIcons.image,
                                    size: 20,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ))
                      : Container(
                          color: AppColors.soft,
                          alignment: Alignment.center,
                          child: const Icon(
                            LucideIcons.image,
                            size: 20,
                            color: AppColors.muted,
                          ),
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleSmall?.copyWith(
                          fontSize: 15,
                          fontWeight: AppTypography.bold,
                          color: AppColors.ink,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          color: const Color(0xff757570),
                        ),
                      ),
                    ],
                  ),
                ),
                if (calendar) ...[
                  const SizedBox(width: 8),
                  Container(
                    color: AppColors.soft,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    child: Text(
                      'Calendar',
                      style: textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        fontWeight: AppTypography.medium,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                const Icon(
                  LucideIcons.arrowRight,
                  size: 18,
                  color: Color(0xff757570),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _discardDraft(
    BuildContext context,
    WidgetRef ref,
    ContentDraft draft,
  ) async {
    ref
        .read(createContentControllerProvider.notifier)
        .setDiscardingDraftId(null);
    try {
      await ref.read(contentRepositoryProvider).deleteDraft(draft.id);
    } on Object {
      /* Ignored if network issue or already removed */
    }
    final userId = ref.read(authRepositoryProvider).currentUser?.id;
    if (userId != null) {
      final key = 'content-recovery-v1:$userId:${draft.format.name}';
      await ref.read(sharedPreferencesProvider).remove(key);
    }
    ref.invalidate(contentHistoryProvider);
    if (context.mounted) {
      AppSnackBar.show(context, 'Draft discarded.');
    }
  }

  String _relativeDate(Object? raw) {
    final date = DateTime.tryParse(raw as String? ?? '')?.toLocal();
    if (date == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final itemDate = DateTime(date.year, date.month, date.day);
    final days = today.difference(itemDate).inDays;
    if (days == 0) {
      return 'Today';
    } else if (days == 1) {
      return 'Yesterday';
    } else if (days < 30) {
      return '$days days ago';
    } else {
      return DateFormat.MMMd().format(date);
    }
  }

  Widget _learning(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    color: const Color(0xfff5f3ec),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        contentEyebrow('Learn'),
        const SizedBox(height: 5),
        _hubDisplay(context, 'The five-frame product story', 27),
        const SizedBox(height: 8),
        contentBody(
          'A simple structure for turning one product into a clear, connected narrative.',
        ),
        const SizedBox(height: 22),
        FittedBox(
          child: Text(
            'HOOK   •   CONTEXT   •   PRODUCT   •   DETAIL   •   FINISH',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: 11,
              color: AppColors.muted,
              fontWeight: AppTypography.bold,
            ),
          ),
        ),
        const SizedBox(height: 22),
        contentAction(
          'Use this structure',
          () => _choose(context, ContentFormat.slideshow),
          dark: false,
          icon: LucideIcons.arrowRight,
        ),
      ],
    ),
  );
}
