import 'package:flutter/material.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/features/studio_school/domain/lesson_definition.dart';
import 'package:look_atlas/features/studio_school/domain/welcome_lesson.dart';

const studioSchoolLessons = <LessonDefinition>[
  LessonDefinition(
    id: WelcomeLessonId.credits,
    title: 'How credits work',
    tagline: 'Your shoot fuel, explained in a minute',
    icon: Icons.toll_outlined,
    cards: [
      LessonCardDefinition(
        title: 'Credits are your shoot fuel',
        body:
            'On Business, photos are unlimited and cost no credits there — '
            'credits pay for video and AI models. On Starter and Pro, photos '
            'use credits, and your plan refills them every month.',
      ),
      LessonCardDefinition(
        title: 'Quick math',
        body:
            'Shots times variations is your image count. On Business that '
            'count is free. On Starter and Pro a standard photo is 1 credit '
            'and a 2K photo is 2.',
        hasCalculator: true,
      ),
      LessonCardDefinition(
        title: 'Always visible',
        body:
            'Your balance sits on the Billing page and on your dashboard. '
            'No surprises.',
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
    icon: Icons.auto_fix_high_outlined,
    cards: [
      LessonCardDefinition(
        title: 'Almost right is fixable',
        body: "A shot with one small flaw doesn't need a reshoot.",
      ),
      LessonCardDefinition(
        title: 'Workshop edits one image',
        body:
            'Fix hands, straps, logos, stray props. Point at the flaw, say '
            'the fix in plain words, run it.',
      ),
      LessonCardDefinition(
        title: 'Cheaper than a new shot',
        body:
            'A fix costs less than generating a fresh image. Keep the shot '
            'you almost love.',
      ),
    ],
    tryLink: SchoolLink(
      label: 'Open Workshop',
      location: AppRoutes.workshop,
    ),
  ),
  LessonDefinition(
    id: WelcomeLessonId.directors,
    title: 'Pick a direction',
    tagline: 'Same product, very different photos',
    icon: Icons.movie_creation_outlined,
    cards: [
      LessonCardDefinition(
        title: 'Directors set the look',
        body:
            'Clean, editorial, bold, street. A director shapes light, pose '
            'and mood for the whole shoot.',
      ),
      LessonCardDefinition(
        title: 'One product, many moods',
        body:
            'Same product, same model, very different photos. Direction is '
            'the difference.',
      ),
      LessonCardDefinition(
        title: 'A safe starting point',
        body:
            'Clean Pro fits almost every catalog. Try bolder directors for '
            'ads and socials.',
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
    tagline: 'You never pay for errors',
    icon: Icons.rotate_left_outlined,
    cards: [
      LessonCardDefinition(
        title: 'Misses happen',
        body:
            "Sometimes a shot comes out wrong. That's normal, and it never "
            'costs you.',
      ),
      LessonCardDefinition(
        title: 'Failed shots refund themselves',
        body:
            'If an image fails to generate, the credits come back on their '
            'own. No ticket needed.',
      ),
      LessonCardDefinition(
        title: 'Unhappy with a result?',
        body: "Tell support from the shoot page. We'll make it right.",
      ),
    ],
    tryLink: SchoolLink(
      label: 'Contact support',
      location: AppRoutes.dashboardSupport,
    ),
  ),
  LessonDefinition(
    id: WelcomeLessonId.imageRights,
    title: 'The images are yours',
    tagline: 'Full commercial rights, forever',
    icon: Icons.verified_outlined,
    cards: [
      LessonCardDefinition(
        title: 'Yours, fully',
        body: 'Every image you make here is yours. Full commercial rights.',
      ),
      LessonCardDefinition(
        title: 'Use them anywhere',
        body:
            'Store, ads, socials, packaging, marketplaces. No credit line, '
            'no license fee, no expiry.',
      ),
      LessonCardDefinition(
        title: 'Your models too',
        body:
            'Models you create belong to your brand. Reuse them on every '
            'product, forever.',
      ),
    ],
  ),
  LessonDefinition(
    id: WelcomeLessonId.rollover,
    title: 'Credits that roll over',
    tagline: 'Unused credits are not lost',
    icon: Icons.savings_outlined,
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
    description: 'From empty account to first shoot.',
    icon: Icons.rocket_launch_outlined,
    tabId: 'getting-started',
  ),
  DeepGuideDefinition(
    title: 'Product photos',
    description: 'What to upload for the truest results.',
    icon: Icons.camera_alt_outlined,
    tabId: 'product-photos',
  ),
  DeepGuideDefinition(
    title: 'Models',
    description: 'Build and reuse the face of your brand.',
    icon: Icons.groups_outlined,
    tabId: 'models',
  ),
  DeepGuideDefinition(
    title: 'Shoots',
    description: 'Plan, run and keep your best shots.',
    icon: Icons.play_arrow_outlined,
    tabId: 'jobs',
  ),
];
