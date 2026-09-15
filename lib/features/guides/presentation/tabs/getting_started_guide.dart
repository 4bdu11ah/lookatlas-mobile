part of '../models/learning_guide_content.dart';

const gettingStartedContent = LearningGuideContent(
  kicker: 'The Look Atlas workflow',
  title: 'From reference photos to approved keepers.',
  intro: 'Build a reusable product library and cast, plan the contact sheet, then review every delivered image in one shoot room.',
  blocks: [
    LearningGuideBlock(
      GuideBlockKind.feature,
      title: 'Reusable products',
      paragraphs: [
        [
          (
            'Save clear reference views, required catalog details, crop choices, angle labels, and calibration in one product record.',
            false,
          ),
        ],
      ],
      iconSvg: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M16.5 9.4 7.55 4.24a1.78 1.78 0 0 0-2.5 1.55v12.42a1.78 1.78 0 0 0 2.5 1.55L16.5 14.6a1.78 1.78 0 0 0 0-3.2z"></path><polyline points="21 16 21 8 16.5 9.4 16.5 14.6 21 16"></polyline><polyline points="3 8 7.55 4.24 7.55 19.76 3 16"></polyline></svg>',
    ),
    LearningGuideBlock(
      GuideBlockKind.feature,
      title: 'A reusable cast',
      paragraphs: [
        [
          (
            'Choose the Look Atlas cast or keep uploaded and AI-created talent private in My models.',
            false,
          ),
        ],
      ],
      iconSvg: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="8" r="5"></circle><path d="M20 21a8 8 0 0 0-16 0"></path></svg>',
    ),
    LearningGuideBlock(
      GuideBlockKind.feature,
      title: 'A review room',
      paragraphs: [
        [
          (
            'Approve keepers, download final images, or refine a result with Edit with AI and Add Variation.',
            false,
          ),
        ],
      ],
      iconSvg: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="m15 4-2 2L9 2 7 4l4 4-8 8v4h4l8-8 4 4 2-2-4-4 2-2Z"></path></svg>',
    ),
    LearningGuideBlock(
      GuideBlockKind.heading,
      title: 'Your first shoot in five steps',
    ),
    LearningGuideBlock(
      GuideBlockKind.step,
      title: 'Add a product',
      number: '1',
      paragraphs: [
        [
          ('Open ', false),
          ('Products', true),
          (', select ', false),
          ('Add a product', true),
          (
            ', and complete Product name, SKU, and Category. SKU is required.',
            false,
          ),
        ],
        [
          (
            'Upload 1–8 reference views, crop them, label their angles, then select ',
            false,
          ),
          ('Add to library', true),
          ('.', false),
        ],
      ],
    ),
    LearningGuideBlock(
      GuideBlockKind.step,
      title: 'Prepare the reference views',
      number: '2',
      paragraphs: [
        [
          (
            "Open the product to review angle labels and reference order. If calibration is recommended, select the calibration status and record the product's true scale. For a placed setup, including one copied from another Product, approve its Fit photo before saving.",
            false,
          ),
        ],
      ],
    ),
    LearningGuideBlock(
      GuideBlockKind.step,
      title: 'Choose or create a model',
      number: '3',
      paragraphs: [
        [
          ('Open ', false),
          ('House Models', true),
          ('. Browse the Look Atlas cast, switch to ', false),
          ('My models', true),
          (', upload private talent, or create an original AI model.', false),
        ],
      ],
    ),
    LearningGuideBlock(
      GuideBlockKind.step,
      title: 'Build the shoot',
      number: '4',
      paragraphs: [
        [
          ('Move through ', false),
          ('Product', true),
          (', ', false),
          ('Model', true),
          (', ', false),
          ('Director', true),
          (', ', false),
          ('Shot Planning', true),
          (', and ', false),
          ('Generate', true),
          ('.', false),
        ],
      ],
    ),
    LearningGuideBlock(
      GuideBlockKind.step,
      title: 'Review the delivery',
      number: '5',
      paragraphs: [
        [
          ('When the shoot moves to Ready for you, select ', false),
          ('Review shoot', true),
          (
            '. Approve keepers, refine individual images, and download the work you need.',
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
            'You can leave while a shoot or AI model is processing. Work continues safely and appears in its library when ready.',
            false,
          ),
        ],
      ],
      iconSvg: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M15 14c.2-1 .7-1.7 1.5-2.5 1-.9 1.5-2.2 1.5-3.5A6 6 0 0 0 6 8c0 1 .2 2.2 1.5 3.5.7.7 1.3 1.5 1.5 2.5"></path><path d="M9 18h6"></path><path d="M10 22h4"></path></svg>',
    ),
    LearningGuideBlock(
      GuideBlockKind.actions,
      actions: [
        ('Open Products', AppRoutes.dashboardProducts),
        ('Open House Models', AppRoutes.dashboardModels),
        ('Create a shoot', AppRoutes.createShoot),
      ],
    ),
  ],
);
