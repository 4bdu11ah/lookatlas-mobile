part of '../models/learning_guide_content.dart';

const productPhotosContent = LearningGuideContent(
  kicker: 'Product library',
  title: 'Give the planner a clean, truthful reference set.',
  intro: 'A product record keeps the source views and catalog details that every future shoot will reuse.',
  blocks: [
    LearningGuideBlock(
      GuideBlockKind.feature,
      title: 'Use clear source photos',
      paragraphs: [
        [
          (
            'Photograph the real product in sharp focus with even light. A simple background makes edges and materials easier to read.',
            false,
          ),
        ],
      ],
      iconSvg: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z"></path><circle cx="12" cy="13" r="4"></circle></svg>',
    ),
    LearningGuideBlock(
      GuideBlockKind.feature,
      title: 'Crop around the product',
      paragraphs: [
        [
          (
            'Use Crop reference photo after upload. Keep the full object visible and remove unnecessary empty space.',
            false,
          ),
        ],
      ],
      iconSvg: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M6 2v14a2 2 0 0 0 2 2h14"></path><path d="M18 22V8a2 2 0 0 0-2-2H2"></path></svg>',
    ),
    LearningGuideBlock(
      GuideBlockKind.feature,
      title: 'Record scale when useful',
      paragraphs: [
        [
          (
            'Calibration is especially useful for jewelry, bags, watches, eyewear, and shoes where size changes the fit.',
            false,
          ),
        ],
      ],
      iconSvg: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21.3 15.3a2.4 2.4 0 0 1 0 3.4l-2.6 2.6a2.4 2.4 0 0 1-3.4 0L2.7 8.7a2.41 2.41 0 0 1 0-3.4l2.6-2.6a2.41 2.41 0 0 1 3.4 0Z"></path><path d="m14.5 12.5 2-2"></path><path d="m11.5 9.5 2-2"></path><path d="m8.5 6.5 2-2"></path></svg>',
    ),
    LearningGuideBlock(GuideBlockKind.heading, title: 'Add a product'),
    LearningGuideBlock(
      GuideBlockKind.step,
      title: 'Open the form',
      number: '1',
      paragraphs: [
        [
          ('Go to ', false),
          ('Products', true),
          (' and select ', false),
          ('Add a product', true),
          ('.', false),
        ],
      ],
    ),
    LearningGuideBlock(
      GuideBlockKind.step,
      title: 'Complete the catalog details',
      number: '2',
      paragraphs: [
        [
          ('Product name, SKU, and Category are required.', true),
          (
            ' Some categories also require a Sub-type. Description is optional and stays with the library record.',
            false,
          ),
        ],
      ],
    ),
    LearningGuideBlock(
      GuideBlockKind.step,
      title: 'Add and prepare reference views',
      number: '3',
      paragraphs: [
        [
          ('Select ', false),
          ('Upload 1–8 reference views', true),
          ('. JPG, PNG, and WebP files up to 20MB each are accepted.', false),
        ],
        [
          (
            'Crop each view, choose its angle, and use the move controls to put the clearest identity views first. Order, angles, and crop choices are saved with the product.',
            false,
          ),
        ],
      ],
    ),
    LearningGuideBlock(
      GuideBlockKind.step,
      title: 'Save to the library',
      number: '4',
      paragraphs: [
        [
          ('Select ', false),
          ('Add to library', true),
          (
            '. Open the product afterward to edit details, manage reference views, calibrate, or select ',
            false,
          ),
          ('Start a shoot', true),
          ('.', false),
        ],
      ],
    ),
    LearningGuideBlock(
      GuideBlockKind.figure,
      title: 'Products Screen & Add Form Capture',
      paragraphs: [
        [('Products screen and Add a product workflow', false)],
      ],
      iconSvg: '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="3" width="18" height="18" rx="2"></rect><circle cx="8.5" cy="8.5" r="1.5"></circle><polyline points="21 15 16 10 5 21"></polyline></svg>',
    ),
    LearningGuideBlock(GuideBlockKind.heading, title: 'Set product size'),
    LearningGuideBlock(
      GuideBlockKind.step,
      title: 'Open calibration',
      number: '1',
      paragraphs: [
        [
          (
            'Open the product and select its size status. Use a clear product photo, a worn photo, or a saved size from a similar product.',
            false,
          ),
        ],
      ],
    ),
    LearningGuideBlock(
      GuideBlockKind.step,
      title: 'Check and size the product',
      number: '2',
      paragraphs: [
        [
          (
            'Confirm the background removal, using Crop or Fix cutout only when needed. We pick a sensible body guide automatically; select Change if another view makes the size easier to judge. Position and resize the product until its scale looks natural.',
            false,
          ),
        ],
      ],
    ),
    LearningGuideBlock(
      GuideBlockKind.step,
      title: 'Approve Fit',
      number: '3',
      paragraphs: [
        [
          ('For a placed setup, select ', false),
          ('Continue', true),
          (', choose the preview body, and select ', false),
          ('Generate (1 credit)', true),
          ('. Inspect the real-body result and choose ', false),
          ('Approve & use', true),
          (', or regenerate with specific size feedback.', false),
        ],
      ],
    ),
    LearningGuideBlock(
      GuideBlockKind.step,
      title: 'Finish calibration',
      number: '4',
      paragraphs: [
        [
          ('Approve & use', true),
          (' activates the Fit immediately. The final step confirms ', false),
          ('Size is set', true),
          ('; choose ', false),
          ('Done', true),
          (
            ' to close. You can reopen the Product at any time to adjust it.',
            false,
          ),
        ],
      ],
    ),
    LearningGuideBlock(
      GuideBlockKind.figure,
      title: '3-Step Size Calibration Flow Capture',
      paragraphs: [
        [
          (
            'Three-step product size flow with Product, Size, and Finish',
            false,
          ),
        ],
      ],
      iconSvg: '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="3" width="18" height="18" rx="2"></rect><circle cx="8.5" cy="8.5" r="1.5"></circle><polyline points="21 15 16 10 5 21"></polyline></svg>',
    ),
    LearningGuideBlock(
      GuideBlockKind.tip,
      paragraphs: [
        [
          (
            'Include views that reveal construction, branding, texture, and any detail the generated image must preserve. Do not upload several near-identical frames in place of useful angles.',
            false,
          ),
        ],
      ],
      iconSvg: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M15 14c.2-1 .7-1.7 1.5-2.5 1-.9 1.5-2.2 1.5-3.5A6 6 0 0 0 6 8c0 1 .2 2.2 1.5 3.5.7.7 1.3 1.5 1.5 2.5"></path><path d="M9 18h6"></path><path d="M10 22h4"></path></svg>',
    ),
    LearningGuideBlock(
      GuideBlockKind.actions,
      actions: [('Open Products', AppRoutes.dashboardProducts)],
    ),
  ],
);
