part of '../screens/shoots_page.dart';

class _ShootsLoading extends StatelessWidget {
  const _ShootsLoading();

  @override
  Widget build(BuildContext context) => const Column(
    key: ValueKey('shoots-overview-shimmer'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _LoadingMasthead(),
      SizedBox(height: 28),
      _LoadingSearch(),
      SizedBox(height: 28),
      _LoadingSectionHeader(
        indexWidth: 20,
        eyebrowWidth: 82,
        titleWidth: 246,
      ),
      _LoadingReadyCard(),
      SizedBox(height: 28),
      _LoadingSectionHeader(
        indexWidth: 20,
        eyebrowWidth: 122,
        titleWidth: 178,
      ),
      _LoadingActiveRow(),
      SizedBox(height: 28),
      _LoadingSectionHeader(
        indexWidth: 20,
        eyebrowWidth: 74,
        titleWidth: 220,
      ),
      _LoadingArchiveGrid(),
    ],
  );
}

class _LoadingMasthead extends StatelessWidget {
  const _LoadingMasthead();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(width: 112, height: 8, child: ShimmerBox()),
      ),
      SizedBox(height: 7),
      Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(width: 104, height: 34, child: ShimmerBox()),
      ),
      SizedBox(height: 10),
      FractionallySizedBox(
        widthFactor: .9,
        alignment: Alignment.centerLeft,
        child: SizedBox(height: 10, child: ShimmerBox()),
      ),
      SizedBox(height: 7),
      FractionallySizedBox(
        widthFactor: .56,
        alignment: Alignment.centerLeft,
        child: SizedBox(height: 10, child: ShimmerBox()),
      ),
      SizedBox(height: 14),
      SizedBox(height: 48, child: ShimmerBox()),
    ],
  );
}

class _LoadingSearch extends StatelessWidget {
  const _LoadingSearch();

  @override
  Widget build(BuildContext context) => Container(
    height: 44,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: const BoxDecoration(
      border: Border(
        top: BorderSide(color: _shootLine),
        bottom: BorderSide(color: _shootLine),
      ),
    ),
    child: const Row(
      children: [
        SizedBox(width: 17, height: 17, child: ShimmerBox()),
        SizedBox(width: 12),
        Expanded(
          child: FractionallySizedBox(
            widthFactor: .72,
            alignment: Alignment.centerLeft,
            child: SizedBox(height: 9, child: ShimmerBox()),
          ),
        ),
      ],
    ),
  );
}

class _LoadingSectionHeader extends StatelessWidget {
  const _LoadingSectionHeader({
    required this.indexWidth,
    required this.eyebrowWidth,
    required this.titleWidth,
  });

  final double indexWidth;
  final double eyebrowWidth;
  final double titleWidth;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.only(top: 12, bottom: 16),
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: _shootLine)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: indexWidth, height: 17, child: const ShimmerBox()),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: eyebrowWidth,
                height: 8,
                child: const ShimmerBox(),
              ),
              const SizedBox(height: 7),
              SizedBox(
                width: titleWidth,
                height: 23,
                child: const ShimmerBox(),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        const SizedBox(width: 54, height: 8, child: ShimmerBox()),
      ],
    ),
  );
}

class _LoadingReadyCard extends StatelessWidget {
  const _LoadingReadyCard();

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: _shootPaper,
      border: Border.all(color: _shootLine),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 200, child: ShimmerBox()),
        Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 116, height: 10, child: ShimmerBox()),
              SizedBox(height: 12),
              SizedBox(width: 224, height: 24, child: ShimmerBox()),
              SizedBox(height: 12),
              FractionallySizedBox(
                widthFactor: .92,
                alignment: Alignment.centerLeft,
                child: SizedBox(height: 9, child: ShimmerBox()),
              ),
              SizedBox(height: 7),
              FractionallySizedBox(
                widthFactor: .64,
                alignment: Alignment.centerLeft,
                child: SizedBox(height: 9, child: ShimmerBox()),
              ),
              SizedBox(height: 14),
              _LoadingFacts(),
              SizedBox(height: 14),
              SizedBox(height: 44, child: ShimmerBox()),
            ],
          ),
        ),
      ],
    ),
  );
}

class _LoadingFacts extends StatelessWidget {
  const _LoadingFacts();

  @override
  Widget build(BuildContext context) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: 4,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      childAspectRatio: 3.3,
    ),
    itemBuilder: (_, _) => const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 52, height: 7, child: ShimmerBox()),
          SizedBox(height: 5),
          SizedBox(width: 92, height: 9, child: ShimmerBox()),
        ],
      ),
    ),
  );
}

class _LoadingActiveRow extends StatelessWidget {
  const _LoadingActiveRow();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _shootPaper,
      border: Border.all(color: _shootLine),
    ),
    child: const Row(
      children: [
        SizedBox(width: 60, height: 76, child: ShimmerBox()),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 78, height: 8, child: ShimmerBox()),
              SizedBox(height: 8),
              SizedBox(width: 172, height: 18, child: ShimmerBox()),
              SizedBox(height: 8),
              SizedBox(width: 124, height: 8, child: ShimmerBox()),
              SizedBox(height: 10),
              SizedBox(height: 3, child: ShimmerBox()),
            ],
          ),
        ),
      ],
    ),
  );
}

class _LoadingArchiveGrid extends StatelessWidget {
  const _LoadingArchiveGrid();

  @override
  Widget build(BuildContext context) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: 2,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      childAspectRatio: .7,
    ),
    itemBuilder: (_, _) => const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: ShimmerBox()),
        SizedBox(height: 8),
        SizedBox(width: 126, height: 10, child: ShimmerBox()),
        SizedBox(height: 6),
        SizedBox(width: 88, height: 8, child: ShimmerBox()),
      ],
    ),
  );
}
