import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayfay_merchant_flutter/core/widgets/app_snackbar.dart';
import '../../controller/orders_controller.dart';
import '../../model/order_model.dart';
import '../../repository/orders_repository.dart';
import '../widgets/assign_associate_dialog.dart';
import '../widgets/customer_info_dialogs.dart';
import '../widgets/mfd_exp_dialog.dart';
import '../widgets/order_card_parts.dart';
import '../widgets/order_info_screen.dart';
import '../widgets/order_product_info_screen.dart';
import 'order_barcode_scanner_screen.dart';

/// Packaging Order Details Screen matching Android PackageDetailsFragment (fragment_package_deatil.xml + PackageDetailAdapter.java)
class PackagingDetailsScreen extends ConsumerStatefulWidget {
  final OrderModel order;
  final String shopId;
  final String categoryId;

  const PackagingDetailsScreen({
    super.key,
    required this.order,
    required this.shopId,
    required this.categoryId,
  });

  @override
  ConsumerState<PackagingDetailsScreen> createState() =>
      _PackagingDetailsScreenState();
}

class _PackagingDetailsScreenState
    extends ConsumerState<PackagingDetailsScreen> {
  // Overrides to track product verification and dates immediately upon user interaction
  final Map<String, bool> _productCheckedOverrides = {};
  final Map<String, MfdExpInfo?> _productMfdExpOverrides = {};
  bool _isAssignedLocally = false;

  bool get _hasNoteOrAttachment => widget.order.hasCustomerNotes;

  bool _isProductVerified(OrderProductItem product) {
    if (_productCheckedOverrides.containsKey(product.id)) {
      return _productCheckedOverrides[product.id]!;
    }
    return product.isChecked || (product.mfdExp?.isVerified ?? false);
  }

  MfdExpInfo? _getProductMfdExp(OrderProductItem product) {
    if (_productCheckedOverrides.containsKey(product.id) &&
        !_productCheckedOverrides[product.id]!) {
      return null;
    }
    if (_productMfdExpOverrides.containsKey(product.id)) {
      return _productMfdExpOverrides[product.id];
    }
    if (!_isProductVerified(product)) {
      return null;
    }
    return product.mfdExp;
  }

  Future<void> _openDateEntry(
    OrderProductItem product, {
    required String packagingType,
    required List<OrderProductItem> allProducts,
  }) async {
    final updatedMfdExp = await MfdExpDialog.openDateEntryDialog(
      context,
      product: product,
      orderId: widget.order.id,
      shopId: widget.shopId,
      categoryId: widget.categoryId,
      isEscalated: widget.order.isEscalatedOrder,
      packagingType: packagingType,
    );

    if (updatedMfdExp != null && mounted) {
      setState(() {
        _productCheckedOverrides[product.id] = true;
        _productMfdExpOverrides[product.id] = updatedMfdExp;
      });

      _checkAllProducts(allProducts);
    }
  }

  void _checkAllProducts(List<OrderProductItem> allProducts) {
    if (allProducts.isEmpty) return;
    final allVerified = allProducts.every((p) => _isProductVerified(p));
    if (allVerified) {
      _showDispatchAlertDialog(context);
    }
  }

  Future<void> _handleBarcodeScan(
    List<OrderProductItem> products,
  ) async {
    final scannedBarcode = await OrderBarcodeScannerScreen.open(context);
    if (scannedBarcode == null || scannedBarcode.trim().isEmpty) return;

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    String? matchedProductId;
    try {
      matchedProductId = await ref
          .read(ordersRepositoryProvider)
          .lookupProductByBarcode(
            categoryId: widget.categoryId,
            shopId: widget.shopId,
            barcode: scannedBarcode.trim(),
          );
    } catch (_) {
      matchedProductId = null;
    } finally {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }

    if (!mounted) return;

    OrderProductItem? matchedProduct;
    if (matchedProductId != null && matchedProductId.isNotEmpty) {
      matchedProduct = products.cast<OrderProductItem?>().firstWhere(
            (p) => p?.id == matchedProductId,
            orElse: () => null,
          );
    }

    // Fallback: match by product ID or name directly
    matchedProduct ??= products.cast<OrderProductItem?>().firstWhere(
          (p) =>
              p?.id == scannedBarcode.trim() ||
              (p?.upc == true &&
                  p?.productName.toLowerCase() ==
                      scannedBarcode.trim().toLowerCase()),
          orElse: () => null,
        );

    if (matchedProduct == null) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text(
            'Info',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text("Product doesn't exist"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Check if product was declined
    if (matchedProduct.escalationStatus >= 3 || matchedProduct.resolute >= 3) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product has declined')),
      );
      return;
    }

    final isAlreadyVerified = _isProductVerified(matchedProduct);

    if (!mounted) return;
    if (isAlreadyVerified) {
      MfdExpDialog.showAlertAlreadyExist(
        context,
        onUpdateAgain: () {
          _openDateEntry(
            matchedProduct!,
            packagingType: 'scan',
            allProducts: products,
          );
        },
      );
    } else {
      _openDateEntry(
        matchedProduct,
        packagingType: 'scan',
        allProducts: products,
      );
    }
  }

  void _handleProductInteraction(
    OrderProductItem product,
    List<OrderProductItem> allProducts,
  ) {
    final verified = _isProductVerified(product);

    if (verified) {
      MfdExpDialog.showAlertAlreadyExist(
        context,
        onUpdateAgain: () {
          _openDateEntry(
            product,
            packagingType: 'manual',
            allProducts: allProducts,
          );
        },
      );
    } else {
      if (product.upc) {
        MfdExpDialog.showAlertUpcDialog(
          context,
          product: product,
          onScan: () => _handleBarcodeScan(allProducts),
          onManual: () {
            _openDateEntry(
              product,
              packagingType: 'manual',
              allProducts: allProducts,
            );
          },
        );
      } else {
        _openDateEntry(
          product,
          packagingType: 'manual',
          allProducts: allProducts,
        );
      }
    }
  }

  void _showAssignConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 45,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: const BoxDecoration(
                color: Color(0xFFF2F2F2),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'BayFay - Alert',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(ctx).pop(),
                    child: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE0E0E0)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              child: Column(
                children: [
                  const Text(
                    'Are you sure you want to manually assign the order to delivery associate?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 100,
                        height: 34,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFBDBDBD)),
                            minimumSize: const Size(0, 34),
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: const Text(
                            'No',
                            style: TextStyle(color: Colors.black, fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 100,
                        height: 34,
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.of(ctx).pop();
                            final assigned = await AssignAssociateDialog.show(
                              context,
                              order: widget.order,
                              shopId: widget.shopId,
                              categoryId: widget.categoryId,
                            );
                            if (assigned == true && mounted) {
                              setState(() {
                                _isAssignedLocally = true;
                              });
                              ref.invalidate(orderInDeliveryQueueProvider(widget.order.id));
                              ref.invalidate(ordersListProvider);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0288D1),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 34),
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: const Text(
                            'Yes',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDispatchAlertDialog(BuildContext context) {
    final parentNavigator = Navigator.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 45,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: const BoxDecoration(
                color: Color(0xFFF2F2F2),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Dispatched',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(ctx).pop(),
                    child: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE0E0E0)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              child: Column(
                children: [
                  const Text(
                    'All products are checked, kindly deliver to the customer,',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 100,
                        height: 34,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFBDBDBD)),
                            minimumSize: const Size(0, 34),
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: const Text(
                            'Close',
                            style: TextStyle(color: Colors.black, fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 110,
                        height: 34,
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.of(ctx).pop();
                            final res = await ref
                                .read(orderActionControllerProvider.notifier)
                                .markReadyToShip(
                                  shopId: widget.shopId,
                                  categoryId: widget.categoryId,
                                  orderId: widget.order.id,
                                  directDispatch: false,
                                );
                            if (context.mounted) {
                              if (res.success) {
                                AppSnackBar.showSuccess(
                                  context,
                                  res.message.isNotEmpty
                                      ? res.message
                                      : 'Order dispatched successfully',
                                );
                                ref.read(orderStatusTabProvider.notifier).state =
                                    OrderStatus.ready;
                                parentNavigator.pop(true);
                              } else {
                                AppSnackBar.showError(
                                  context,
                                  res.message.isNotEmpty
                                      ? res.message
                                      : 'Failed to dispatch order',
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF52B153),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 34),
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: const Text(
                            'Dispatched',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleDispatchClick(
    BuildContext context,
    WidgetRef ref,
    List<OrderProductItem> products,
  ) {
    final allChecked = products.isNotEmpty &&
        products.every((p) => _isProductVerified(p));

    if (allChecked) {
      _showDispatchAlertDialog(context);
    } else {
      CustomerInfoDialogs.showCommonTwoButtonsAlert(
        context,
        title: 'Warning!',
        message:
            'You are not verified/selected all products, are you sure you want to dispatch the order?',
        negativeText: 'No',
        positiveText: 'Continue',
        onConfirm: () async {
          final res = await ref
              .read(orderActionControllerProvider.notifier)
              .markReadyToShip(
                shopId: widget.shopId,
                categoryId: widget.categoryId,
                orderId: widget.order.id,
                directDispatch: true,
              );
          if (context.mounted) {
            if (res.success) {
              AppSnackBar.showSuccess(
                context,
                res.message.isNotEmpty
                    ? res.message
                    : 'Order dispatched successfully',
              );
              ref.read(orderStatusTabProvider.notifier).state =
                  OrderStatus.ready;
              Navigator.of(context).pop(true);
            } else {
              AppSnackBar.showError(
                context,
                res.message.isNotEmpty
                    ? res.message
                    : 'Failed to dispatch order',
              );
            }
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsArg = (
      orderId: widget.order.id,
      shopId: widget.shopId,
      categoryId: widget.categoryId,
      isEscalated: widget.order.isEscalatedOrder,
    );
    final productsAsync = ref.watch(orderProductsProvider(productsArg));
    final inQueueAsync = ref.watch(orderInDeliveryQueueProvider(widget.order.id));
    final inQueue = inQueueAsync.valueOrNull ?? false;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: const Color(0xFFF5F5F5),
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF333333)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            widget.order.isEscalatedOrder
                ? 'Replacement/Undelivered'
                : widget.order.orderId,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: InkWell(
                onTap: () {
                  final prods = productsAsync.valueOrNull ?? const [];
                  _handleBarcodeScan(prods);
                },
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0275D8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    children: [
                      Text(
                        'Scan',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.qr_code_scanner, size: 15, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Top Customer & Action Card (fragment_package_deatil.xml lines 66-224)
          Container(
            margin: const EdgeInsets.fromLTRB(10, 5, 10, 0),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: const Color(0xFFDADADA), width: 1),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OrderAvatar(order: widget.order),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            widget.order.customerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          OrderIdLabel(order: widget.order),
                        ],
                      ),
                    ),
                    if (!widget.order.isSelfPickup)
                      OrderDistanceIndicator(distance: widget.order.distance),
                  ],
                ),
                const SizedBox(height: 10),
                // 3-Button Row: Order Details | Customer Notes | Delivery Info
                Row(
                  children: [
                    Expanded(
                      child: _TopCardSubBtn(
                        label: 'Order Details',
                        onTap: () async {
                          final res = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) => OrderInfoScreen(
                                order: widget.order,
                                shopId: widget.shopId,
                                categoryId: widget.categoryId,
                                statusLabel: 'Packaging',
                              ),
                            ),
                          );
                          if (res == true && context.mounted) {
                            Navigator.of(context).pop(true);
                          }
                        },
                      ),
                    ),
                    if (_hasNoteOrAttachment) ...[
                      const SizedBox(width: 6),
                      Expanded(
                        child: _TopCardSubBtn(
                          label: 'Customer Notes',
                          onTap: () =>
                              CustomerInfoDialogs.showNotes(context, widget.order),
                        ),
                      ),
                    ],
                    if (widget.order.hasAssignedAssistant &&
                        !widget.order.isSelfPickup) ...[
                      const SizedBox(width: 6),
                      Expanded(
                        child: _TopCardSubBtn(
                          label: 'Delivery Info',
                          onTap: () =>
                              CustomerInfoDialogs.showDeliveryPersonInfo(
                            context,
                            order: widget.order,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Product Details List (fragment_package_deatil.xml lines 228-265)
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(10, 5, 10, 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: const Color(0xFFDADADA), width: 1),
              ),
              child: productsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Text(
                    'Failed to load products: $err',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
                data: (products) {
                  final totalProductsCount = products.fold<int>(
                    0,
                    (sum, p) =>
                        sum +
                        (widget.order.isEscalatedOrder && p.escalatedQty > 0
                            ? p.escalatedQty
                            : p.quantity),
                  );

                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Product Details',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            'Total Products : $totalProductsCount',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.separated(
                          itemCount: products.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final p = products[index];
                            final verified = _isProductVerified(p);
                            final effectiveMfdExp = _getProductMfdExp(p);

                            return PackagingProductRowWidget(
                              product: p,
                              orderId: widget.order.id,
                              shopId: widget.shopId,
                              categoryId: widget.categoryId,
                              isEscalatedOrder: widget.order.isEscalatedOrder,
                              isVerifiedOverride: verified,
                              mfdExpOverride: effectiveMfdExp,
                              onTap: () {
                                _handleProductInteraction(
                                  p,
                                  products,
                                );
                              },
                              onCheckboxChanged: (val) {
                                if (verified) {
                                  // Uncheck product locally: clears checked and clears manufacture/expiry dates
                                  setState(() {
                                    _productCheckedOverrides[p.id] = false;
                                    _productMfdExpOverrides[p.id] = null;
                                  });
                                } else {
                                  _handleProductInteraction(
                                    p,
                                    products,
                                  );
                                }
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          // Bottom Action Buttons matching Android ConstraintLayout: Side-by-side in a Row
          // (sample_btn_bg2 for Assign, green_bg for Dispatch)
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: Row(
              children: [
                if (!widget.order.isSelfPickup &&
                    !widget.order.hasAssignedAssistant) ...[
                  Expanded(
                    child: InkWell(
                      onTap: _isAssignedLocally
                          ? null
                          : () => _showAssignConfirmationDialog(context),
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _isAssignedLocally
                              ? const Color(0xFFE0E0E0)
                              : inQueue
                                  ? const Color(0xFF52B153)
                                  : const Color(0xFF0288D1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _isAssignedLocally
                              ? 'Assigned'
                              : inQueue
                                  ? 'Order in the Delivery Queue'
                                  : 'Assign to Associate',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _isAssignedLocally
                                ? Colors.black
                                : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: InkWell(
                    onTap: () => _handleDispatchClick(
                      context,
                      ref,
                      productsAsync.valueOrNull ?? const [],
                    ),
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF52B153), // Green matching Android green_bg
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Click here to Dispatch Order',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopCardSubBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _TopCardSubBtn({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
      ),
    );
  }
}

/// Shared Product Row Widget for Packaging, Dispatched, and On The Way Details Screens
/// Matches Android PackageDetailAdapter / DispatchDetailAdapter / OntheWayDetailsAdapter (adapter_new_order_fagment1.xml)
class PackagingProductRowWidget extends ConsumerWidget {
  final OrderProductItem product;
  final String orderId;
  final String shopId;
  final String categoryId;
  final bool isEscalatedOrder;
  final bool isCancelled;
  final VoidCallback? onTap;
  final bool showCheckIndicator;
  final bool? showInfoButton;
  final bool? isVerifiedOverride;
  final MfdExpInfo? mfdExpOverride;
  final ValueChanged<bool?>? onCheckboxChanged;

  const PackagingProductRowWidget({
    super.key,
    required this.product,
    this.orderId = '',
    this.shopId = '',
    this.categoryId = '',
    this.isEscalatedOrder = false,
    this.isCancelled = false,
    this.onTap,
    this.showCheckIndicator = true,
    this.showInfoButton,
    this.isVerifiedOverride,
    this.mfdExpOverride,
    this.onCheckboxChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVerified = isVerifiedOverride ??
        (!showCheckIndicator || product.isChecked || (product.mfdExp?.isVerified ?? false));
    final mfdExp = isVerified ? (mfdExpOverride ?? product.mfdExp) : null;
    final qtyDisplay = isEscalatedOrder && product.escalatedQty > 0
        ? product.escalatedQty
        : product.quantity;

    final hasMoreDates = isVerified && mfdExp != null && mfdExp.dates.length > 1;
    final showInfo = (showInfoButton ?? showCheckIndicator) && !isEscalatedOrder;

    // Escalation Accepted / Declined switch state in PackageDetailAdapter.java lines 96-123
    final showEscalateSwitch = isEscalatedOrder &&
        showCheckIndicator &&
        (product.verifyStatus == 2 || product.verifyStatus == 3) &&
        (product.escalationStatus == 1 ||
            product.escalationStatus == 2 ||
            product.escalationStatus == 4);
    final isDeclined = product.escalationStatus == 2;
    final isSwitchDisabled = product.escalationStatus == 4;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        margin: const EdgeInsets.only(top: 5),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: isVerified || !showCheckIndicator
                ? const Color(0xFF52B153)
                : const Color(0xFFBCE8F1),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image (60x60 matching adapter_new_order_fagment1.xml)
            OrderProductImageWidget(
              imageUrl: product.image,
              width: 60,
              height: 60,
            ),
            const SizedBox(width: 10),
            // Middle details (weight 0.65)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.productName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  if (product.manufacturer.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      product.manufacturer,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black,
                      ),
                    ),
                  ],
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          product.unit,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 15,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        color: Colors.black,
                      ),
                      Text(
                        'Qty : $qtyDisplay',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  // Net price (hidden when hasEscalate in PackageDetailAdapter.java line 70)
                  if (!isEscalatedOrder) ...[
                    const SizedBox(height: 3),
                    Text(
                      '\u20B9 ${product.netPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black,
                      ),
                    ),
                  ],
                  // 2-column Manufacture & Expiry dates matching adapter_new_order_fagment1.xml lines 107-170
                  OrderMfdExpLabelsRow(mfdExp: mfdExp),
                ],
              ),
            ),
            if (!isCancelled) ...[
              const SizedBox(width: 6),
              // Right column (info button + Escalation switch + Checkbox/Verified tick + More button)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (showInfo)
                    InkWell(
                      onTap: () => OrderProductInfoScreen.open(
                        context,
                        product: product,
                        shopId: shopId,
                        categoryId: categoryId,
                      ),
                      child: Container(
                        width: 48,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'info',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  if (showEscalateSwitch) ...[
                    const SizedBox(height: 4),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          isDeclined ? 'Declined' : 'Accepted',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isDeclined
                                ? const Color(0xFFF23B3B)
                                : const Color(0xFF63C900),
                          ),
                        ),
                        SizedBox(
                          height: 26,
                          child: Transform.scale(
                            scale: 0.75,
                            child: Switch(
                              value: isDeclined,
                              onChanged: isSwitchDisabled || orderId.isEmpty
                                  ? null
                                  : (val) {
                                      if (val) {
                                        ref
                                            .read(orderActionControllerProvider
                                                .notifier)
                                            .escalateProduct(
                                              shopId: shopId,
                                              categoryId: categoryId,
                                              orderId: orderId,
                                              productId: product.id,
                                            )
                                            .then((res) {
                                          if (context.mounted) {
                                            if (res.success) {
                                              AppSnackBar.showSuccess(
                                                context,
                                                res.message.isNotEmpty
                                                    ? res.message
                                                    : 'Product escalated',
                                              );
                                            } else {
                                              AppSnackBar.showError(
                                                context,
                                                res.message.isNotEmpty
                                                    ? res.message
                                                    : 'Failed to escalate product',
                                              );
                                            }
                                          }
                                        });
                                      } else {
                                        ref
                                            .read(orderActionControllerProvider
                                                .notifier)
                                            .acceptEscalatedProduct(
                                              shopId: shopId,
                                              categoryId: categoryId,
                                              orderId: orderId,
                                              productId: product.id,
                                            )
                                            .then((res) {
                                          if (context.mounted) {
                                            if (res.success) {
                                              AppSnackBar.showSuccess(
                                                context,
                                                res.message.isNotEmpty
                                                    ? res.message
                                                    : 'Product accepted',
                                              );
                                            } else {
                                              AppSnackBar.showError(
                                                context,
                                                res.message.isNotEmpty
                                                    ? res.message
                                                    : 'Failed to accept product',
                                              );
                                            }
                                          }
                                        });
                                      }
                                    },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (showCheckIndicator && !isDeclined) ...[
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: isVerified,
                        activeColor: const Color(0xFF52B153),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onChanged: onCheckboxChanged ??
                            (_) {
                              if (onTap != null) {
                                onTap!();
                              }
                            },
                      ),
                    ),
                  ] else if (!showCheckIndicator && !isDeclined) ...[
                    // In Dispatched & On The Way matching Android DispatchDetailAdapter.java line 101/110:
                    // holder.checkbox.setVisibility(View.GONE);
                    // holder.checkboxImg.setVisibility(View.VISIBLE); (drawable/ic_green_checked.webp)
                    const SizedBox(height: 6),
                    Image.asset(
                      'assets/images/ic_green_checked.webp',
                      width: 24,
                      height: 24,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.check_circle,
                        color: Color(0xFF52B153),
                        size: 24,
                      ),
                    ),
                  ],
                  if (hasMoreDates) ...[
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () =>
                          MfdExpDialog.showMoreDatesPopup(context, product),
                      child: Container(
                        width: 48,
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'More',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
