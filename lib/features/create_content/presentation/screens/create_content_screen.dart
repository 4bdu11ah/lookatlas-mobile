import 'package:flutter/material.dart';
import 'package:look_atlas/features/create_content/domain/entities/content_models.dart';
import 'package:look_atlas/features/create_content/presentation/screens/content_brief_screen.dart';
import 'package:look_atlas/features/create_content/presentation/screens/content_hub_screen.dart';
import 'package:look_atlas/features/create_content/presentation/screens/content_review_screen.dart';

export 'package:look_atlas/features/create_content/presentation/screens/content_brief_screen.dart';
export 'package:look_atlas/features/create_content/presentation/screens/content_hub_screen.dart';
export 'package:look_atlas/features/create_content/presentation/screens/content_review_screen.dart';

class CreateContentScreen extends StatelessWidget {
  const CreateContentScreen({
    super.key,
    this.initialFormat,
    this.contentId,
    this.previewImageUrl,
    this.openCaptionPanel = false,
  });

  final String? initialFormat;
  final String? contentId;
  final String? previewImageUrl;
  final bool openCaptionPanel;

  @override
  Widget build(BuildContext context) {
    if (contentId != null && contentId!.isNotEmpty) {
      return ContentReviewScreen(
        contentId: contentId!,
        previewImageUrl: previewImageUrl,
        openCaptionPanel: openCaptionPanel,
        format: initialFormat != null
            ? ContentFormat.parse(initialFormat!)
            : null,
      );
    }
    if (initialFormat != null && initialFormat!.isNotEmpty) {
      return ContentBriefScreen(
        format: ContentFormat.parse(initialFormat!),
      );
    }
    return const ContentHubScreen();
  }
}
