import 'dart:typed_data';

import 'package:look_atlas/core/result/result.dart';
import 'package:look_atlas/features/shoots/domain/entities/shoot_create.dart';
import 'package:look_atlas/features/shoots/domain/entities/shoot_job.dart';
import 'package:look_atlas/features/shoots/domain/repositories/shoots_repository.dart';

class FakeShootsRepository implements ShootsRepository {
  FakeShootsRepository({
    ShootCreateCatalog catalog = _catalog,
    List<Result<String>> createResults = const [],
  }) : _createCatalog = catalog,
       createResults = [...createResults];

  final ShootCreateCatalog _createCatalog;
  final List<Result<String>> createResults;

  final List<ShootJob> jobs = [
    _job(
      id: 'job-bag',
      name: 'Tan Leather Bag',
      status: 'completed',
      product: 'assets/images/onboarding/showcase-bag-before.jpg',
      model: 'assets/images/onboarding/showcase-dress-after.jpg',
      renders: 15,
      images: _images,
    ),
    _job(
      id: 'job-heels-processing',
      name: 'Gold Evening Heels',
      status: 'processing',
      product: 'assets/images/onboarding/showcase-shoes-before.jpg',
      model: 'assets/images/onboarding/showcase-tshirt-after.jpg',
      renders: 6,
      progress: 0.64,
    ),
    _job(
      id: 'job-heels-failed',
      name: 'Gold Evening Heels',
      status: 'failed',
      product: 'assets/images/onboarding/showcase-shoes-before.jpg',
      model: 'assets/images/onboarding/showcase-dress-after.jpg',
      supportTicketId: 'job_7f2a9c13',
    ),
  ];

  int getJobsCalls = 0;
  int getJobCalls = 0;
  int getJobStatusCalls = 0;
  int planShotsCalls = 0;
  int createShootCalls = 0;
  final List<ShootSelection> plannedSelections = [];
  final List<CreateShootRequest> createRequests = [];
  String lastStatus = '';
  String lastSearch = '';
  String? lastJobId;
  String? lastApprovedImageId;
  bool? lastApprovedValue;
  String? lastEditPrompt;
  String? lastReportReason;
  String? lastReportComment;
  int? lastVariationShotIndex;
  ShootVideoRequest? lastVideoRequest;

  @override
  Future<Result<ShootPage>> getJobs({
    String status = '',
    int page = 1,
    int limit = 20,
    String search = '',
  }) async {
    getJobsCalls++;
    lastStatus = status;
    lastSearch = search;
    final normalized = search.trim().toLowerCase();
    final visible = [
      for (final job in jobs)
        if ((status.isEmpty || job.status == status) &&
            (normalized.isEmpty || job.name.toLowerCase().contains(normalized)))
          job,
    ];
    return Result.ok(
      ShootPage(
        jobs: visible,
        page: page,
        totalPages: 1,
        total: visible.length,
      ),
    );
  }

  @override
  Future<Result<ShootJob>> getJob(String jobId) async {
    getJobCalls++;
    lastJobId = jobId;
    return Result.ok(jobs.firstWhere((job) => job.id == jobId));
  }

  @override
  Future<Result<ShootProgressStatus>> getJobStatus(String jobId) async {
    getJobStatusCalls++;
    final job = jobs.firstWhere((item) => item.id == jobId);
    return Result.ok(
      ShootProgressStatus(status: job.status, progress: job.progress),
    );
  }

  @override
  Future<Result<void>> rerunJob(String jobId) async => const Result.ok(null);

  @override
  Future<Result<void>> cancelJob(String jobId) async => const Result.ok(null);

  @override
  Future<Result<void>> setImageApproval(
    String jobId,
    String imageId, {
    required bool approved,
  }) async {
    lastApprovedImageId = imageId;
    lastApprovedValue = approved;
    return const Result.ok(null);
  }

  @override
  Future<Result<Uint8List>> downloadImage(
    String jobId,
    String imageId,
  ) async => Result.ok(Uint8List.fromList([1, 2, 3]));

  @override
  Future<Result<void>> requestVideo(
    String jobId,
    ShootVideoRequest request,
  ) async {
    lastVideoRequest = request;
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> editImage(
    String jobId,
    String imageId,
    String prompt,
  ) async {
    lastEditPrompt = prompt;
    return const Result.ok(null);
  }

  @override
  Future<Result<ShootImageEditState>> getImageEditStatus(
    String jobId,
    String imageId,
  ) async => const Result.ok(ShootImageEditState.completed);

  @override
  Future<Result<void>> reportImage(
    String jobId,
    String imageId, {
    required String reason,
    required String comment,
  }) async {
    lastReportReason = reason;
    lastReportComment = comment;
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> addVariation(
    String jobId,
    int shotIndex,
    String remarks,
  ) async {
    lastVariationShotIndex = shotIndex;
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> redoHandShots(String jobId) async =>
      const Result.ok(null);

  @override
  Future<Result<List<ShootImageVersion>>> getImageVersions(
    String jobId,
    String imageId,
  ) async => const Result.ok([
    ShootImageVersion(
      id: 'version-2',
      url: 'assets/images/onboarding/showcase-tshirt-after.jpg',
      label: 'Version 2',
      description: 'Warmer lighting',
    ),
    ShootImageVersion(
      id: 'version-1',
      url: 'assets/images/onboarding/showcase-bag-after.jpg',
      label: 'Version 1',
      description: 'Original image',
      isActive: true,
    ),
  ]);

  @override
  Future<Result<void>> setActiveImageVersion(
    String jobId,
    String imageId,
    String versionId,
  ) async => const Result.ok(null);

  @override
  Future<Result<ShootCreateCatalog>> loadCreateCatalog() async =>
      Result.ok(_createCatalog);

  @override
  Future<Result<List<PlannedShootShot>>> planShots(
    ShootSelection selection,
  ) async {
    planShotsCalls++;
    plannedSelections.add(selection);
    return const Result.ok(_plannedShots);
  }

  @override
  Future<Result<PlannedShootShot>> createCustomShot(
    CustomShootShotRequest request,
  ) async => Result.ok(
    PlannedShootShot(
      title: request.shotIdea,
      description: request.poseDirection,
    ),
  );

  @override
  Future<Result<String>> createShoot(CreateShootRequest request) async {
    createShootCalls++;
    createRequests.add(request);
    if (createResults.isNotEmpty) {
      final result = createResults.removeAt(0);
      if (result.isErr) return result;
    }
    jobs.add(
      _job(
        id: 'job-created',
        name: request.selection.product.name,
        status: 'processing',
        product: request.selection.product.imageUrl,
        model: request.selection.model.imageUrl,
      ),
    );
    return const Result.ok('job-created');
  }

  @override
  Future<Result<void>> updateProductSubCategory(
    String productId,
    String subCategory,
  ) async => const Result.ok(null);

  @override
  Future<Result<void>> savePreset({
    required String name,
    required Map<String, dynamic> settings,
    String? basedOnLookId,
    String? heroImageUrl,
    bool isDefault = false,
  }) async => const Result.ok(null);

  @override
  Future<Result<void>> deletePreset(String presetId) async =>
      const Result.ok(null);
}

ShootJob _job({
  required String id,
  required String name,
  required String status,
  required String product,
  required String model,
  int renders = 0,
  double progress = 0,
  String? supportTicketId,
  List<ShootImage> images = const [],
}) => ShootJob(
  id: id,
  name: name,
  status: status,
  renders: renders,
  date: DateTime.utc(2026, 7, 17),
  productThumbnail: product,
  modelThumbnail: model,
  modelName: 'Mila',
  progress: progress,
  supportTicketId: supportTicketId,
  productId: 'product-1',
  images: images,
  shots: images.isEmpty
      ? const []
      : [
          ShootShot(
            index: 0,
            title: 'Cafe Arrival',
            description: 'Natural walking shot',
            images: images.take(2).toList(),
          ),
          ShootShot(
            index: 1,
            title: 'Detail Moment',
            description: 'Product close-up',
            images: images.skip(2).toList(),
          ),
        ],
);

const _images = [
  ShootImage(
    id: 'image-1',
    url: 'assets/images/onboarding/showcase-bag-after.jpg',
    approved: true,
  ),
  ShootImage(
    id: 'image-2',
    url: 'assets/images/onboarding/showcase-tshirt-after.jpg',
    variationIndex: 1,
  ),
  ShootImage(
    id: 'image-3',
    url: 'assets/images/onboarding/showcase-dress-after.jpg',
    shotIndex: 1,
  ),
  ShootImage(
    id: 'image-4',
    url: 'assets/images/onboarding/showcase-shoes-after.jpg',
    shotIndex: 1,
    variationIndex: 1,
  ),
];

const _catalog = ShootCreateCatalog(
  products: [
    ShootCatalogItem(
      id: 'product-1',
      name: 'Tan Leather Bag',
      subtitle: 'BAG-104',
      imageUrl: 'assets/images/onboarding/showcase-bag-before.jpg',
    ),
    ShootCatalogItem(
      id: 'product-2',
      name: 'Gold Heels',
      subtitle: 'SH-302',
      imageUrl: 'assets/images/onboarding/showcase-shoes-before.jpg',
    ),
    ShootCatalogItem(
      id: 'product-3',
      name: 'Classic Frames',
      subtitle: 'SG-228',
      imageUrl: 'assets/images/onboarding/showcase-sunglasses-before.jpg',
    ),
    ShootCatalogItem(
      id: 'product-4',
      name: 'Silk Dress',
      subtitle: 'DR-880',
      imageUrl: 'assets/images/onboarding/showcase-dress-before.jpg',
    ),
    ShootCatalogItem(
      id: 'product-5',
      name: 'Silver Necklace',
      subtitle: 'NK-415',
      imageUrl: 'assets/images/onboarding/showcase-necklace-before.jpg',
    ),
  ],
  userModels: [
    ShootCatalogItem(
      id: 'model-1',
      name: 'Mila',
      subtitle: 'Female',
      imageUrl: 'assets/images/onboarding/showcase-dress-after.jpg',
      source: 'user',
    ),
  ],
  libraryModels: [
    ShootCatalogItem(
      id: 'library-1',
      name: 'Kai',
      subtitle: 'Male',
      imageUrl: 'assets/images/onboarding/showcase-tshirt-after.jpg',
      source: 'lookatlas',
    ),
  ],
  looks: defaultShootDirectors,
  lookFilters: {},
  presets: [],
  availableCredits: 124,
  relaxEnabled: true,
  plan: 'pro',
  isUnlimitedEligible: true,
);

const _plannedShots = [
  PlannedShootShot(
    title: 'Cafe Arrival',
    description: 'Natural walking shot entering a bright cafe.',
  ),
  PlannedShootShot(
    title: 'Table Detail',
    description: 'Close framing on the bag hardware and stitching.',
  ),
  PlannedShootShot(
    title: 'Window Portrait',
    description: 'Waist-up portrait in soft window light.',
  ),
  PlannedShootShot(
    title: 'Street Crossing',
    description: 'Confident full-body movement shot.',
  ),
  PlannedShootShot(
    title: 'Quiet Product Moment',
    description: 'Seated composition with product foregrounded.',
  ),
];
