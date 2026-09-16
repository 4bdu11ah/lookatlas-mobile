import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:look_atlas/core/router/app_routes.dart';
import 'package:look_atlas/features/dashboard/domain/entities/dashboard_overview.dart';
import 'package:look_atlas/features/dashboard/presentation/controllers/dashboard_overview_controller.dart';
import 'package:look_atlas/features/dashboard/presentation/widgets/overview_style.dart';
import 'package:look_atlas/shared/widgets/app_bottom_sheet.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class OverviewCollection extends StatelessWidget {
  const OverviewCollection({super.key});
  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      OverviewSectionHeading(
        index: '03',
        label: 'Your collection',
        title: 'The people and pieces in your studio.',
      ),
      SizedBox(height: 14),
      _CollectionPanel(products: true),
      SizedBox(height: 16),
      _CollectionPanel(products: false),
    ],
  );
}

class _CollectionPanel extends ConsumerWidget {
  const _CollectionPanel({required this.products});
  final bool products;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final panel = ref.watch(
      dashboardOverviewControllerProvider.select((state) {
        final data = state.value?.overview;
        return (
          collection: products ? data?.products : data?.models,
          error: products
              ? data?.panelStatus.productsError
              : data?.panelStatus.modelsError,
        );
      }),
    );
    final collection = panel.collection ?? const DashboardCollection();
    final route = products
        ? AppRoutes.dashboardProducts
        : AppRoutes.dashboardModels;
    return Container(
      key: ValueKey(
        products ? 'dashboard-products-panel' : 'dashboard-models-panel',
      ),
      decoration: BoxDecoration(border: Border.all(color: OverviewStyle.line)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: OverviewStyle.line)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      OverviewLabel(products ? 'Products' : 'Models'),
                      const SizedBox(height: 4),
                      Text(
                        products
                            ? 'Your product library'
                            : collection.title.isEmpty
                            ? 'Your models'
                            : collection.title,
                        style: OverviewStyle.serif(22),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                OverviewLink(
                  '${collection.total} ${products ? 'total' : 'available'}',
                  onTap: () => context.push(route),
                ),
              ],
            ),
          ),
          if (panel.error ?? false)
            OverviewPanelState(
              title: products
                  ? 'Product previews are temporarily unavailable.'
                  : 'Model previews are temporarily unavailable.',
              body: products
                  ? 'Your products are still in the library. Try loading this preview again.'
                  : 'Your roster is unchanged. Reload this preview to see your models.',
              error: true,
              action: OverviewLink(
                'Try again',
                onTap: () => ref
                    .read(dashboardOverviewControllerProvider.notifier)
                    .refresh(),
              ),
            )
          else
            _CollectionGrid(collection: collection, products: products),
        ],
      ),
    );
  }
}

class _CollectionGrid extends StatelessWidget {
  const _CollectionGrid({required this.collection, required this.products});
  final DashboardCollection collection;
  final bool products;

  @override
  Widget build(BuildContext context) {
    if (!products && collection.items.isEmpty) {
      return OverviewPanelState(
        title: 'Your model roster starts here.',
        body: 'Choose a house model or add your own talent.',
        action: OverviewLink(
          'Explore models',
          onTap: () => context.push(AppRoutes.dashboardModels),
        ),
      );
    }
    final count = collection.items.length + (products ? 1 : 0);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 1) / 2;
        final height = collection.items.isEmpty
            ? 110.0
            : width +
                  10 +
                  (MediaQuery.textScalerOf(context).scale(11) * 1.2).ceil() +
                  (MediaQuery.textScalerOf(context).scale(9) * 1.2).ceil();
        return ColoredBox(
          color: OverviewStyle.line,
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: count,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: height,
              mainAxisSpacing: 1,
              crossAxisSpacing: 1,
            ),
            itemBuilder: (context, index) => index == collection.items.length
                ? InkWell(
                    key: const ValueKey('dashboard-add-product'),
                    onTap: () =>
                        context.push('${AppRoutes.dashboardProducts}?create=1'),
                    child: ColoredBox(
                      color: OverviewStyle.paper,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            LucideIcons.plus,
                            size: 20,
                            color: OverviewStyle.muted,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add product',
                            style: OverviewStyle.body(10, bold: true),
                          ),
                        ],
                      ),
                    ),
                  )
                : _CollectionTile(
                    item: collection.items[index],
                    products: products,
                  ),
          ),
        );
      },
    );
  }
}

class _CollectionTile extends StatelessWidget {
  const _CollectionTile({required this.item, required this.products});
  final DashboardCollectionItem item;
  final bool products;
  @override
  Widget build(BuildContext context) => InkWell(
    key: ValueKey('dashboard-${products ? 'product' : 'model'}-${item.id}'),
    onTap: () => products
        ? context.push(
            '${AppRoutes.dashboardProducts}?product=${Uri.encodeQueryComponent(item.id)}',
          )
        : _showModelPreview(context, item),
    child: Container(
      color: OverviewStyle.paper,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Stack(
              fit: StackFit.expand,
              children: [
                OverviewImage(item.thumbnail, label: item.name),
                if (item.featured)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      color: OverviewStyle.ink,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: Text(
                        'FEATURED',
                        style: OverviewStyle.body(
                          8,
                          bold: true,
                          color: OverviewStyle.paper,
                        ).copyWith(letterSpacing: .64),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: OverviewStyle.body(
              11,
              height: 1.2,
              bold: true,
              color: OverviewStyle.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: OverviewStyle.body(9, height: 1.2),
          ),
        ],
      ),
    ),
  );
}

Future<void> _showModelPreview(
  BuildContext context,
  DashboardCollectionItem item,
) => showAppBottomSheet<void>(
  context,
  backgroundColor: OverviewStyle.paper,
  isScrollControlled: true,
  builder: (sheetContext) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(item.name, style: OverviewStyle.serif(28))),
              IconButton(
                tooltip: 'Close model preview',
                onPressed: () => Navigator.pop(sheetContext),
                icon: const Icon(LucideIcons.x),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 1,
            child: OverviewImage(item.thumbnail, label: item.name),
          ),
          const SizedBox(height: 12),
          Text(item.description, style: OverviewStyle.body(13)),
          const SizedBox(height: 16),
          OverviewButton(
            'Explore house models',
            onPressed: () {
              Navigator.pop(sheetContext);
              unawaited(context.push(AppRoutes.dashboardModels));
            },
          ),
        ],
      ),
    ),
  ),
);
