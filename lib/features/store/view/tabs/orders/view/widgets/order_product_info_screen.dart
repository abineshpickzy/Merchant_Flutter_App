import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayfay_merchant_flutter/app/theme/app_colors.dart';
import 'package:bayfay_merchant_flutter/core/widgets/widgets.dart';
import '../../controller/orders_controller.dart';
import '../../model/order_model.dart';
import 'order_card_parts.dart';

/// Product Info & Reviews Screen matching Android ProductFragment.java + ProductInfo.java + ReviewFragment.java
/// (product_fragment.xml, fragment_product_info.xml, single_text_textview.xml, fragment_review.xml, alert_zoom.xml)
class OrderProductInfoScreen extends ConsumerStatefulWidget {
  final OrderProductItem product;
  final String shopId;
  final String categoryId;

  const OrderProductInfoScreen({
    super.key,
    required this.product,
    required this.shopId,
    required this.categoryId,
  });

  static Future<void> open(
    BuildContext context, {
    required OrderProductItem product,
    required String shopId,
    required String categoryId,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderProductInfoScreen(
          product: product,
          shopId: shopId,
          categoryId: categoryId,
        ),
      ),
    );
  }

  @override
  ConsumerState<OrderProductInfoScreen> createState() =>
      _OrderProductInfoScreenState();
}

class _OrderProductInfoScreenState
    extends ConsumerState<OrderProductInfoScreen> {
  int _selectedTabIndex = 0; // 0 = Product Info, 1 = Reviews

  OrderProductInfoArg get _infoArg => (
        categoryId: widget.categoryId,
        storeId: widget.shopId,
        productId: widget.product.id,
        type: widget.product.upc ? 'upc' : 'sku',
      );

  void _showZoomDialog(List<String> images, int initialIndex) {
    if (images.isEmpty) return;
    final pageController = PageController(initialPage: initialIndex);
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          child: SizedBox(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.65,
            child: Stack(
              children: [
                PageView.builder(
                  controller: pageController,
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    return InteractiveViewer(
                      minScale: 0.8,
                      maxScale: 4.0,
                      child: Center(
                        child: OrderProductImageWidget(
                          imageUrl: images[index],
                          isInventory: true,
                          width: 320,
                          height: 320,
                          fit: BoxFit.contain,
                        ),
                      ),
                    );
                  },
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: InkWell(
                    onTap: () => Navigator.of(ctx).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0x22000000),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 20,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(orderProductFullDetailProvider(_infoArg));
    final detailData = detailAsync.valueOrNull;

    final resolvedName =
        (detailData != null && detailData.productName.trim().isNotEmpty)
            ? detailData.productName
            : widget.product.productName;

    final images = <String>[
      if (detailData != null && detailData.images.isNotEmpty)
        ...detailData.images
      else if (widget.product.image != null &&
          widget.product.image!.trim().isNotEmpty)
        widget.product.image!,
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Text(
          'Product - $resolvedName',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          // Top 6-image strip matching product_fragment.xml (height: 85dp, bg: #FAFAFA)
          Container(
            height: 85,
            width: double.infinity,
            color: const Color(0xFFFAFAFA),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Row(
              children: List.generate(6, (index) {
                final hasImg = index < images.length;
                return Expanded(
                  child: GestureDetector(
                    onTap:
                        hasImg ? () => _showZoomDialog(images, index) : null,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(
                          color: hasImg
                              ? const Color(0xFFE0E0E0)
                              : const Color(0xFFF0F0F0),
                        ),
                      ),
                      child: hasImg
                          ? Padding(
                              padding: const EdgeInsets.all(3),
                              child: OrderProductImageWidget(
                                imageUrl: images[index],
                                isInventory: true,
                                width: 50,
                                height: 65,
                                fit: BoxFit.contain,
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                );
              }),
            ),
          ),

          // 2-Tab Selector matching product_fragment.xml (height: 42dp, Product Info | Reviews)
          Container(
            height: 42,
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFFE0E0E0), width: 1),
                bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedTabIndex = 0),
                    child: Container(
                      alignment: Alignment.center,
                      color: _selectedTabIndex == 0
                          ? Colors.white
                          : const Color(0xFFE0E0E0),
                      child: const Text(
                        'Product Info',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF424242),
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: double.infinity,
                  color: const Color(0xFFBDBDBD),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedTabIndex = 1),
                    child: Container(
                      alignment: Alignment.center,
                      color: _selectedTabIndex == 1
                          ? Colors.white
                          : const Color(0xFFE0E0E0),
                      child: const Text(
                        'Reviews',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF424242),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tab Body
          Expanded(
            child: _selectedTabIndex == 0
                ? _ProductInfoTabView(
                    product: widget.product,
                    infoArg: _infoArg,
                  )
                : _ProductReviewsTabView(
                    infoArg: _infoArg,
                  ),
          ),
        ],
      ),
    );
  }
}

/// Matches Android ProductInfo.java (fragment_product_info.xml + single_text_textview.xml)
class _ProductInfoTabView extends ConsumerWidget {
  final OrderProductItem product;
  final OrderProductInfoArg infoArg;

  const _ProductInfoTabView({
    required this.product,
    required this.infoArg,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(orderProductFullDetailProvider(infoArg));
    final avgAsync = ref.watch(orderProductAvgStatsProvider(infoArg));

    final avgData = avgAsync.valueOrNull ?? const OrderProductAvgData();
    final avgPriceStr = avgData.avgSellingPrice > 0
        ? 'Average price : \u20B9${avgData.avgSellingPrice.toStringAsFixed(2)}'
        : 'Average price: \u20B90.0';

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          // Top bordered box with 3 pills (fragment_product_info.xml lines 16-86)
          Container(
            margin: const EdgeInsets.fromLTRB(15, 15, 15, 0),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFBDBDBD)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              children: [
                // Pill 1: Average price
                Container(
                  width: double.infinity,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F2),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Text(
                    avgPriceStr,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF616161),
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                // Pill 2: Total product sold
                Container(
                  width: double.infinity,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F2),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Text(
                    'Total product sold: Not Applicable',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF616161),
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                // Pill 3: Avg. Rating + 5-star RatingBar
                Container(
                  width: double.infinity,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F2),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Avg. Rating : ',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF616161),
                        ),
                      ),
                      ...List.generate(5, (index) {
                        final rating = avgData.averageCustomerRating;
                        IconData icon;
                        if (rating >= index + 1) {
                          icon = Icons.star;
                        } else if (rating > index && rating < index + 1) {
                          icon = Icons.star_half;
                        } else {
                          icon = Icons.star_border;
                        }
                        return Icon(
                          icon,
                          size: 15,
                          color: const Color(0xFFFFB300),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 15),

          // Dynamic columns & UPC pill
          detailAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => _buildFallbackProductTable(context),
            data: (detail) {
              if (detail.columns.isEmpty) {
                return _buildFallbackProductTable(context);
              }

              final firstCol = detail.columns.first;
              final firstVal = detail.attributes[firstCol.keyName] ?? '';
              final upcText = '${firstCol.displayName} : $firstVal';

              final remainingCols = detail.columns.skip(1).where((col) {
                final val = detail.attributes[col.keyName];
                return val != null && val.trim().isNotEmpty;
              }).toList();

              return Column(
                children: [
                  // UPC / SKU pill with copy button (fragment_product_info.xml lines 89-121)
                  _UpcCopyPill(
                    label: upcText,
                    rawValue: firstVal,
                  ),
                  const SizedBox(height: 15),
                  // Key-Value attribute rows (single_text_textview.xml)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Column(
                      children: remainingCols.map((col) {
                        return _ProductAttributeRow(
                          label: col.displayName,
                          value: detail.attributes[col.keyName] ?? '',
                        );
                      }).toList(),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// Fallback table using known OrderProductItem fields when inventory view endpoint returns empty
  Widget _buildFallbackProductTable(BuildContext context) {
    final codeType = product.upc ? 'UPC' : 'SKU';
    final mfdExp = product.mfdExp;
    String mfgText = '';
    String expText = '';
    if (mfdExp != null) {
      if (mfdExp.type == 3) {
        mfgText = 'Unknown';
        expText = 'Unknown';
      } else if (mfdExp.type == 2) {
        mfgText = 'Not Applicable';
        expText = 'Not Applicable';
      } else if (mfdExp.dates.isNotEmpty) {
        mfgText = mfdExp.dates.map((e) => e.mfgDateFormatted).join(', ');
        expText = mfdExp.dates.map((e) => e.expDateFormatted).join(', ');
      }
    }

    return Column(
      children: [
        _UpcCopyPill(
          label: '$codeType : ${product.id}',
          rawValue: product.id,
        ),
        const SizedBox(height: 15),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            children: [
              _ProductAttributeRow(
                label: 'Product Name',
                value: product.productName,
              ),
              if (product.manufacturer.isNotEmpty)
                _ProductAttributeRow(
                  label: 'Brand / Manufacturer',
                  value: product.manufacturer,
                ),
              _ProductAttributeRow(
                label: 'Unit',
                value: product.unit,
              ),
              _ProductAttributeRow(
                label: 'Net Price',
                value: '\u20B9${product.netPrice.toStringAsFixed(2)}',
              ),
              if (product.offer > 0)
                _ProductAttributeRow(
                  label: 'Offer',
                  value: '${product.offer}%',
                ),
              _ProductAttributeRow(
                label: 'Order Quantity',
                value: '${product.quantity}',
              ),
              if (mfgText.isNotEmpty)
                _ProductAttributeRow(
                  label: 'Manufacture Date',
                  value: mfgText,
                ),
              if (expText.isNotEmpty)
                _ProductAttributeRow(
                  label: 'Expiry Date',
                  value: expText,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _UpcCopyPill extends StatelessWidget {
  final String label;
  final String rawValue;

  const _UpcCopyPill({
    required this.label,
    required this.rawValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 240, minHeight: 30),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF616161),
              ),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: () {
              final textToCopy = rawValue.isNotEmpty
                  ? rawValue
                  : (label.contains(':')
                      ? label.split(':').last.trim()
                      : label);
              Clipboard.setData(ClipboardData(text: textToCopy));
              AppSnackBar.showSuccess(context, 'UPC Copied');
            },
            child: const Icon(
              Icons.copy,
              size: 15,
              color: Color(0xFF616161),
            ),
          ),
        ],
      ),
    );
  }
}

/// Key-value row matching single_text_textview.xml (0.34 left bold label : 0.66 right value)
class _ProductAttributeRow extends StatelessWidget {
  final String label;
  final String value;

  const _ProductAttributeRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 34,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF616161),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              ':',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF616161),
              ),
            ),
          ),
          Expanded(
            flex: 66,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF616161),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Matches Android ReviewFragment.java (fragment_review.xml)
class _ProductReviewsTabView extends ConsumerWidget {
  final OrderProductInfoArg infoArg;

  const _ProductReviewsTabView({required this.infoArg});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(orderProductReviewsProvider(infoArg));

    return reviewsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Center(
        child: Text(
          'No Reviews',
          style: TextStyle(fontSize: 15, color: Color(0xFF616161)),
        ),
      ),
      data: (reviewData) {
        if (reviewData.reviews.isEmpty && reviewData.totalCount == 0) {
          return const Center(
            child: Text(
              'No Reviews',
              style: TextStyle(fontSize: 15, color: Color(0xFF616161)),
            ),
          );
        }

        final total = reviewData.totalCount > 0 ? reviewData.totalCount : 1;
        final c5 = reviewData.starCounts[5] ?? 0;
        final c4 = reviewData.starCounts[4] ?? 0;
        final c3 = reviewData.starCounts[3] ?? 0;
        final c2 = reviewData.starCounts[2] ?? 0;
        final c1 = reviewData.starCounts[1] ?? 0;

        return Column(
          children: [
            // Top 160dp rating breakdown header (fragment_review.xml lines 16-247)
            SizedBox(
              height: 160,
              child: Row(
                children: [
                  // Left half: overall score + stars + total count
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          reviewData.averageRating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 34,
                            color: Color(0xFF424242),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(5, (i) {
                            final r = reviewData.averageRating;
                            IconData icon;
                            if (r >= i + 1) {
                              icon = Icons.star;
                            } else if (r > i && r < i + 1) {
                              icon = Icons.star_half;
                            } else {
                              icon = Icons.star_border;
                            }
                            return Icon(
                              icon,
                              size: 16,
                              color: const Color(0xFFFFB300),
                            );
                          }),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${reviewData.totalCount} total',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF616161),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Right half: 5 star to 1 star progress bars
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _StarProgressBarRow(
                            star: 5,
                            count: c5,
                            fraction: c5 / total,
                            color: const Color(0xFF66BB6A),
                          ),
                          const SizedBox(height: 4),
                          _StarProgressBarRow(
                            star: 4,
                            count: c4,
                            fraction: c4 / total,
                            color: const Color(0xFF9CCC65),
                          ),
                          const SizedBox(height: 4),
                          _StarProgressBarRow(
                            star: 3,
                            count: c3,
                            fraction: c3 / total,
                            color: const Color(0xFFFFCA28),
                          ),
                          const SizedBox(height: 4),
                          _StarProgressBarRow(
                            star: 2,
                            count: c2,
                            fraction: c2 / total,
                            color: const Color(0xFFFFA726),
                          ),
                          const SizedBox(height: 4),
                          _StarProgressBarRow(
                            star: 1,
                            count: c1,
                            fraction: c1 / total,
                            color: const Color(0xFFEF5350),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(
              height: 1,
              thickness: 1,
              indent: 10,
              endIndent: 10,
              color: Color(0xFFBDBDBD),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: reviewData.reviews.length,
                separatorBuilder: (_, _) => const Divider(height: 16),
                itemBuilder: (context, index) {
                  final item = reviewData.reviews[index];
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      OrderAvatarWidget(
                        imageUrl: item.customerImage,
                        size: 40,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    item.customerName,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                if (item.createdAtFormatted.isNotEmpty)
                                  Text(
                                    item.createdAtFormatted,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF757575),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: List.generate(5, (i) {
                                return Icon(
                                  i < item.rating.round()
                                      ? Icons.star
                                      : Icons.star_border,
                                  size: 14,
                                  color: const Color(0xFFFFB300),
                                );
                              }),
                            ),
                            if (item.title.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                item.title,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                            if (item.review.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                item.review,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF616161),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StarProgressBarRow extends StatelessWidget {
  final int star;
  final int count;
  final double fraction;
  final Color color;

  const _StarProgressBarRow({
    required this.star,
    required this.count,
    required this.fraction,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.star, size: 12, color: Color(0xFF757575)),
        const SizedBox(width: 2),
        SizedBox(
          width: 12,
          child: Text(
            '$star',
            style: const TextStyle(fontSize: 12, color: Color(0xFF424242)),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: fraction.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: const Color(0xFFE0E0E0),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 24,
          child: Text(
            '$count',
            style: const TextStyle(fontSize: 11, color: Color(0xFF616161)),
          ),
        ),
      ],
    );
  }
}
