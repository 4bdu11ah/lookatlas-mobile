import 'package:look_atlas/features/dashboard/domain/entities/dashboard_data.dart';

enum DashboardActivationStage { setup, generating, ready, active }

class DashboardActivation {
  const DashboardActivation({
    this.stage = DashboardActivationStage.setup,
    this.firstShootId,
    this.currentStep,
    this.completedStepCount = 0,
    this.activatedAt,
  });

  final DashboardActivationStage stage;
  final String? firstShootId;
  final int? currentStep;
  final int completedStepCount;
  final DateTime? activatedAt;

  String get intro => switch (stage) {
    DashboardActivationStage.setup => 'Start with one product. We’ll guide it from your library to a finished campaign.',
    DashboardActivationStage.generating => 'Your first campaign is in production. You can leave the studio while it keeps moving.',
    DashboardActivationStage.ready => 'Your first campaign is ready. Review the final images to complete your studio setup.',
    DashboardActivationStage.active => 'A clear view of what is moving, what is ready, and what you can create next.',
  };

  String get actionLabel => switch (stage) {
    DashboardActivationStage.setup => 'Add your first product',
    DashboardActivationStage.generating => 'View shoot progress',
    DashboardActivationStage.ready => 'Review final images',
    DashboardActivationStage.active => 'Create a shoot',
  };
}

class DashboardActivity {
  const DashboardActivity({
    this.activeCount = 0,
    this.readyCount = 0,
    this.active = const [],
    this.ready = const [],
    this.recentCompleted = const [],
  });

  final int activeCount;
  final int readyCount;
  final List<DashboardRecentJob> active;
  final List<DashboardRecentJob> ready;
  final List<DashboardRecentJob> recentCompleted;

  String get attentionLabel =>
      (activeCount + readyCount).toString().padLeft(2, '0');
}

class DashboardCollectionItem {
  const DashboardCollectionItem({
    required this.id,
    required this.name,
    this.thumbnail = '',
    this.description = '',
    this.featured = false,
  });

  final String id;
  final String name;
  final String thumbnail;
  final String description;
  final bool featured;
}

class DashboardCollection {
  const DashboardCollection({
    this.title = '',
    this.total = 0,
    this.items = const [],
  });

  final String title;
  final int total;
  final List<DashboardCollectionItem> items;
}

class DashboardPanelStatus {
  const DashboardPanelStatus({
    this.activityError = false,
    this.productsError = false,
    this.modelsError = false,
  });

  final bool activityError;
  final bool productsError;
  final bool modelsError;
}

class DashboardOverview {
  const DashboardOverview({
    required this.credits,
    this.activity = const DashboardActivity(),
    this.activation = const DashboardActivation(),
    this.products = const DashboardCollection(),
    this.models = const DashboardCollection(title: 'Your models'),
    this.panelStatus = const DashboardPanelStatus(),
    this.ownedShootId,
  });

  final DashboardStats credits;
  final DashboardActivity activity;
  final DashboardActivation activation;
  final DashboardCollection products;
  final DashboardCollection models;
  final DashboardPanelStatus panelStatus;
  final String? ownedShootId;

  DashboardRecentJob? get ownedShoot {
    final id = ownedShootId;
    if (id == null) return null;
    return [
          ...activity.ready,
          ...activity.recentCompleted,
          ...activity.active,
        ].where((job) => job.id == id).firstOrNull ??
        DashboardRecentJob(
          id: id,
          name: 'Your shoot',
          status: 'completed',
          renders: 0,
          productThumbnail: '',
          modelThumbnail: '',
        );
  }
}
