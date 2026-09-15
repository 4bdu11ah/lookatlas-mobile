part of '../models/learning_guide_content.dart';

const shootsContent = LearningGuideContent(
  kicker: 'Shoot builder',
  title: 'Plan the contact sheet before generation starts.',
  intro: 'The builder separates product, cast, creative direction, shot planning, and the final generation review into five clear steps.',
  blocks: [
    LearningGuideBlock(GuideBlockKind.heading, title: 'Create a shoot'),
    LearningGuideBlock(
      GuideBlockKind.step,
      title: 'Product',
      number: '1',
      paragraphs: [
        [
          ('Under ', false),
          ('Choose what enters the frame.', true),
          (', select the product or products for the shoot. Use ', false),
          ('Add New Product', true),
          (' if the library is missing one.', false),
        ],
        [
          (
            "When more than one product is selected, choose how they should share the frame. Check the primary product's calibration before continuing when scale matters.",
            false,
          ),
        ],
      ],
    ),
    LearningGuideBlock(
      GuideBlockKind.step,
      title: 'Model',
      number: '2',
      paragraphs: [
        [
          ('Under ', false),
          ('Cast the face of this story.', true),
          (', choose from ', false),
          ('My Models', true),
          (
            ' or Look Atlas talent. A mixed cast can include up to three models.',
            false,
          ),
        ],
      ],
    ),
    LearningGuideBlock(
      GuideBlockKind.step,
      title: 'Director',
      number: '3',
      paragraphs: [
        [
          ('Under ', false),
          ('Set the visual point of view.', true),
          (
            ', choose the destination or use case, select a Director, and add an optional brief.',
            false,
          ),
        ],
        [
          (
            'Set the resolution and the number of shots and variations. These settings determine the final image count shown before generation.',
            false,
          ),
        ],
      ],
    ),
    LearningGuideBlock(
      GuideBlockKind.step,
      title: 'Shot Planning',
      number: '4',
      paragraphs: [
        [
          ('Under ', false),
          ('Build the contact sheet before the camera rolls.', true),
          (', select ', false),
          ('Plan My Shoot', true),
          ('.', false),
        ],
        [
          (
            'Review the proposed shots, keep the ones you want, re-plan if needed, or select ',
            false,
          ),
          ('Add a shot of your own', true),
          ('.', false),
        ],
      ],
    ),
    LearningGuideBlock(
      GuideBlockKind.step,
      title: 'Generate',
      number: '5',
      paragraphs: [
        [
          ('Under ', false),
          ('Everything is ready for set.', true),
          (
            ', review products, models, shots, resolution, and image count before starting.',
            false,
          ),
        ],
        [
          (
            'Use the Generate option offered by your plan. Business workspaces may choose the included paced allowance or ',
            false,
          ),
          ('Generate Instant', true),
          (' with the displayed credit cost.', false),
        ],
      ],
    ),
    LearningGuideBlock(
      GuideBlockKind.feature,
      title: 'In production now',
      paragraphs: [
        [
          (
            'Track work that is queued or rendering. You can leave the page while production continues.',
            false,
          ),
        ],
      ],
      iconSvg: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20.2 6 3 11l-.9-2.4c-.4-1.1.2-2.4 1.3-2.8l3.4-1.2c1.1-.4 2.4.2 2.8 1.3L10.5 8"></path><path d="m6.2 5.3 3.1 4.7"></path><path d="m16 8 3.1 4.7"></path><rect x="2" y="11" width="20" height="10" rx="2"></rect></svg>',
    ),
    LearningGuideBlock(
      GuideBlockKind.feature,
      title: 'Ready for you',
      paragraphs: [
        [
          (
            'Select Review shoot to enter the delivery room and make keeper decisions.',
            false,
          ),
        ],
      ],
      iconSvg: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="m12 3-1.9 5.8a2 2 0 0 1-1.3 1.3L3 12l5.8 1.9a2 2 0 0 1 1.3 1.3L12 21l1.9-5.8a2 2 0 0 1 1.3-1.3L21 12l-5.8-1.9a2 2 0 0 1-1.3-1.3Z"></path></svg>',
    ),
    LearningGuideBlock(
      GuideBlockKind.feature,
      title: 'Your archive',
      paragraphs: [
        [
          (
            'Return to completed work and its approved images without rebuilding the shoot.',
            false,
          ),
        ],
      ],
      iconSvg: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="3" width="18" height="18" rx="2"></rect><circle cx="8.5" cy="8.5" r="1.5"></circle><polyline points="21 15 16 10 5 21"></polyline></svg>',
    ),
    LearningGuideBlock(GuideBlockKind.heading, title: 'Inside the review room'),
    LearningGuideBlock(
      GuideBlockKind.checklist,
      paragraphs: [
        [
          ('Use ', false),
          ('Approve variation', true),
          (' or ', false),
          ('Approve all', true),
          (' to mark keepers.', false),
        ],
        [
          ('Use ', false),
          ('Edit with AI', true),
          (' for a targeted refinement.', false),
        ],
        [
          ('Use ', false),
          ('Add Variation', true),
          (' when you want another result for the same shot.', false),
        ],
        [
          (
            'Open Version History to return to an earlier result, then download individual images or a set.',
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
            'Product, model, direction, and planned-shot choices are saved in a shoot draft. Browser-selected files inside an unfinished Add Product or Add Model form are not saved, so finish those forms before leaving.',
            false,
          ),
        ],
      ],
      iconSvg: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M15 14c.2-1 .7-1.7 1.5-2.5 1-.9 1.5-2.2 1.5-3.5A6 6 0 0 0 6 8c0 1 .2 2.2 1.5 3.5.7.7 1.3 1.5 1.5 2.5"></path><path d="M9 18h6"></path><path d="M10 22h4"></path></svg>',
    ),
    LearningGuideBlock(
      GuideBlockKind.actions,
      actions: [('Create a shoot', AppRoutes.createShoot)],
    ),
  ],
);
