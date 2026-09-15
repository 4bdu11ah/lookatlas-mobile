import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/features/studio_school/domain/entities/welcome_lesson.dart';
import 'package:look_atlas/features/studio_school/presentation/models/lesson_definition.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const studioSchoolLessons = <LessonDefinition>[
  LessonDefinition(
    id: WelcomeLessonId.credits,
    title: 'How credits work',
    tagline: 'Your shoot fuel, explained in a minute',
    icon: LucideIcons.coins,
    cards: [
      LessonCardDefinition(
        title: 'Credits are your shoot fuel',
        body: 'Business includes Unlimited photos in its paced Shoots lane; credits there pay for Instant Generate, Create Content, Calendar, AI video, edits, and custom AI models. On Starter and Pro, photos use credits, and your plan refills them every month.',
      ),
      LessonCardDefinition(
        title: 'Quick math',
        body: 'Shots times variations is your image count. On Business, paced-lane photos are included with Unlimited photos. On Starter and Pro a standard photo is 1 credit and a 2K photo is 2.',
        hasCalculator: true,
      ),
      LessonCardDefinition(
        title: 'Always visible',
        body: 'Your balance sits on the Billing page and on your dashboard. No surprises.',
      ),
      LessonCardDefinition(
        title: 'Running low mid-month?',
        body: 'Add a credit pack. Your plan and price stay the same.',
      ),
    ],
    tryLink: SchoolLink(
      label: 'See my balance',
      location: AppRoutes.dashboardBilling,
    ),
  ),
  LessonDefinition(
    id: WelcomeLessonId.workshop,
    title: "Fix it, don't reshoot",
    tagline: 'Small flaws have a one-minute fix',
    icon: LucideIcons.wand2,
    cards: [
      LessonCardDefinition(
        title: 'Almost right is fixable',
        body: "A shot with one small flaw doesn't need a reshoot.",
      ),
      LessonCardDefinition(
        title: 'Workshop edits one image',
        body: 'Fix hands, straps, logos, stray props. Point at the flaw, say the fix in plain words, run it.',
      ),
      LessonCardDefinition(
        title: 'Keep the frame you almost love',
        body: 'Workshop costs 2 credits with Standard or 4 with Premium. If a failed run was charged, its refund is tracked until confirmed. It lets you preserve the composition that already works.',
      ),
    ],
    tryLink: SchoolLink(label: 'Open Workshop', location: AppRoutes.workshop),
  ),
  LessonDefinition(
    id: WelcomeLessonId.directors,
    title: 'Pick a direction',
    tagline: 'Same product, very different photos',
    icon: LucideIcons.clapperboard,
    cards: [
      LessonCardDefinition(
        title: 'Directors set the look',
        body: 'Clean, editorial, bold, street. A director shapes light, pose and mood for the whole shoot.',
      ),
      LessonCardDefinition(
        title: 'One product, many moods',
        body: 'Same product, same model, very different photos. Direction is the difference.',
      ),
      LessonCardDefinition(
        title: 'A safe starting point',
        body: 'Clean Pro fits almost every catalog. Try bolder directors for ads and socials.',
      ),
    ],
    tryLink: SchoolLink(
      label: 'Start a shoot',
      location: AppRoutes.dashboardShoots,
    ),
  ),
  LessonDefinition(
    id: WelcomeLessonId.refunds,
    title: 'When a shot misses',
    tagline: 'Failures refund themselves; defects can be reported',
    icon: LucideIcons.rotateCcw,
    cards: [
      LessonCardDefinition(
        title: 'Misses happen',
        body: 'Sometimes a generation fails or a finished result has a genuine defect. The two paths are handled differently.',
      ),
      LessonCardDefinition(
        title: 'Failed shots refund themselves',
        body: 'If an image fails to generate, the credits come back on their own. No ticket needed.',
      ),
      LessonCardDefinition(
        title: 'See a genuine defect?',
        body: 'Report it from the shoot image. Our team reviews product or model defects and returns that image’s credits when the issue is confirmed.',
      ),
    ],
    tryLink: SchoolLink(
      label: 'Review my shoots',
      location: AppRoutes.dashboardShoots,
    ),
  ),
  LessonDefinition(
    id: WelcomeLessonId.imageRights,
    title: 'The images are yours',
    tagline: 'Use every finished photo across your brand',
    icon: LucideIcons.badgeCheck,
    cards: [
      LessonCardDefinition(
        title: 'Yours, fully',
        body: 'Finished photos include commercial use across your store, ads, social channels, and print.',
      ),
      LessonCardDefinition(
        title: 'Use them anywhere',
        body: 'Store, ads, socials, packaging, marketplaces. No credit line, no license fee, no expiry.',
      ),
      LessonCardDefinition(
        title: 'Your models too',
        body: 'Reuse a custom model across products and campaigns to keep the cast consistent.',
      ),
    ],
  ),
  LessonDefinition(
    id: WelcomeLessonId.rollover,
    title: 'Credits that roll over',
    tagline: 'Unused credits are not lost',
    icon: LucideIcons.piggyBank,
    cards: [
      LessonCardDefinition(
        title: 'Nothing vanishes',
        body: "Unused credits don't disappear when the month ends.",
      ),
      LessonCardDefinition(
        title: 'They roll forward',
        body: 'Leftover credits roll into your next month on their own.',
      ),
      LessonCardDefinition(
        title: 'Save for the big one',
        body: 'Planning a big drop? Let credits stack up for it.',
      ),
    ],
    tryLink: SchoolLink(
      label: 'Check my credits',
      location: AppRoutes.dashboardBilling,
    ),
  ),
];

const studioSchoolGuides = <DeepGuideDefinition>[
  DeepGuideDefinition(
    title: 'Getting started',
    description: 'Go from an empty account to a finished first shoot.',
    icon: LucideIcons.rocket,
    tabId: 'getting-started',
    kicker: 'Start here',
  ),
  DeepGuideDefinition(
    title: 'Prepare product photos',
    description: 'Give the AI cleaner source images and get truer results.',
    icon: LucideIcons.camera,
    tabId: 'product-photos',
    kicker: 'Better inputs',
  ),
  DeepGuideDefinition(
    title: 'Build your model roster',
    description: 'Choose, create, and reuse the right faces for your brand.',
    icon: LucideIcons.users,
    tabId: 'models',
    kicker: 'Brand consistency',
  ),
  DeepGuideDefinition(
    title: 'Plan stronger shoots',
    description: 'Choose products, models, direction, shots, and variations.',
    icon: LucideIcons.play,
    tabId: 'jobs',
    kicker: 'Production',
  ),
];
