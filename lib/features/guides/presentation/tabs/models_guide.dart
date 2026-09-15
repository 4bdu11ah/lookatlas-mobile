part of '../models/learning_guide_content.dart';

const modelsContent = LearningGuideContent(
  kicker: 'Casting library',
  title: 'Choose the Look Atlas cast or build your own roster.',
  intro: 'House Models separates ready-to-use Look Atlas profiles from private talent saved only in your workspace.',
  blocks: [
    LearningGuideBlock(
      GuideBlockKind.feature,
      title: 'Look Atlas cast',
      paragraphs: [
        [
          (
            "Browse current profiles, filter the roster, open a model's full profile, and select Use in a shoot.",
            false,
          ),
        ],
      ],
      iconSvg: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"></path><circle cx="9" cy="7" r="4"></circle><path d="M22 21v-2a4 4 0 0 0-3-3.87"></path><path d="M16 3.13a4 4 0 0 1 0 7.75"></path></svg>',
    ),
    LearningGuideBlock(
      GuideBlockKind.feature,
      title: 'My models',
      paragraphs: [
        [
          (
            'Upload someone you work with or create an original AI identity. Private profiles remain in your workspace for future shoots.',
            false,
          ),
        ],
      ],
      iconSvg: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="8" r="5"></circle><path d="M20 21a8 8 0 0 0-16 0"></path></svg>',
    ),
    LearningGuideBlock(
      GuideBlockKind.heading,
      title: 'Upload a model you work with',
    ),
    LearningGuideBlock(
      GuideBlockKind.step,
      title: 'Choose the upload method',
      number: '1',
      paragraphs: [
        [
          ('Select ', false),
          ('Add a house model', true),
          (', then ', false),
          ('Upload a model', true),
          ('.', false),
        ],
      ],
    ),
    LearningGuideBlock(
      GuideBlockKind.step,
      title: 'Add references and profile details',
      number: '2',
      paragraphs: [
        [
          ('Upload 1–4 clear JPG, PNG, or WebP references. Complete ', false),
          ('Model name', true),
          (', ', false),
          ('Profile', true),
          (', and ', false),
          ('Height (cm)', true),
          ('. Mark the height as approximate when needed.', false),
        ],
      ],
    ),
    LearningGuideBlock(
      GuideBlockKind.step,
      title: 'Save the private profile',
      number: '3',
      paragraphs: [
        [
          ('Select ', false),
          ('Add to roster', true),
          (
            '. The model appears under My models and stays private to your workspace.',
            false,
          ),
        ],
      ],
    ),
    LearningGuideBlock(GuideBlockKind.heading, title: 'Create an AI model'),
    LearningGuideBlock(
      GuideBlockKind.checklist,
      paragraphs: [
        [
          ('Select ', false),
          ('Add a house model', true),
          (', then ', false),
          ('Create an AI model', true),
          ('.', false),
        ],
        [
          (
            'Model name is optional. Choose Profile, enter an age from 18–100, and write a 10–600 character Creative brief.',
            false,
          ),
        ],
        [
          ('Review the 20-credit cost and select ', false),
          ('Create model', true),
          ('.', false),
        ],
        [
          (
            'The generation continues safely if you close the page. Its status and roster-confirmation recovery remain available on House Models.',
            false,
          ),
        ],
      ],
    ),
    LearningGuideBlock(
      GuideBlockKind.tip,
      paragraphs: [
        [
          (
            'For an uploaded person, use clear references that show a consistent identity from useful angles. For an AI model, describe stable physical traits rather than a full shoot scene.',
            false,
          ),
        ],
      ],
      iconSvg: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M15 14c.2-1 .7-1.7 1.5-2.5 1-.9 1.5-2.2 1.5-3.5A6 6 0 0 0 6 8c0 1 .2 2.2 1.5 3.5.7.7 1.3 1.5 1.5 2.5"></path><path d="M9 18h6"></path><path d="M10 22h4"></path></svg>',
    ),
    LearningGuideBlock(
      GuideBlockKind.actions,
      actions: [('Open House Models', AppRoutes.dashboardModels)],
    ),
  ],
);
