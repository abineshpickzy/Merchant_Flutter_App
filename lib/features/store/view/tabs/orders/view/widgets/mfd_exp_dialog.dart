import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:bayfay_merchant_flutter/core/widgets/app_snackbar.dart';
import '../../controller/orders_controller.dart';
import '../../model/order_model.dart';

/// Manufacture & Expiry verification dialog matching Android PackageDetailsFragment
/// (scan_upc_sku_alert.xml + activity_translucent_add_expire_manufa_dt.xml + alert_update_prod.xml)
class MfdExpDialog {
  /// Entry point when clicking a product row or checkbox in PackagingDetailsScreen
  static void showForProduct(
    BuildContext context, {
    required WidgetRef ref,
    required OrderProductItem product,
    required String orderId,
    required String shopId,
    required String categoryId,
    required bool isEscalated,
    required Function(String barcode) onScanRequested,
    VoidCallback? onUnchecked,
  }) {
    // If product is already checked/verified, clicking gives the option to uncheck or update again
    if (product.isChecked || (product.mfdExp?.isVerified ?? false)) {
      showAlertAlreadyExist(
        context,
        onUpdateAgain: () {
          if (onUnchecked != null) {
            onUnchecked();
          }
          openDateEntryDialog(
            context,
            product: product,
            orderId: orderId,
            shopId: shopId,
            categoryId: categoryId,
            isEscalated: isEscalated,
            packagingType: 'manual',
          );
        },
      );
      return;
    }

    if (product.upc) {
      showAlertUpcDialog(
        context,
        product: product,
        onScan: () => onScanRequested(''),
        onManual: () {
          openDateEntryDialog(
            context,
            product: product,
            orderId: orderId,
            shopId: shopId,
            categoryId: categoryId,
            isEscalated: isEscalated,
            packagingType: 'manual',
          );
        },
      );
    } else {
      openDateEntryDialog(
        context,
        product: product,
        orderId: orderId,
        shopId: shopId,
        categoryId: categoryId,
        isEscalated: isEscalated,
        packagingType: 'manual',
      );
    }
  }

  /// Alert for UPC products matching Android scan_upc_sku_alert.xml
  static void showAlertUpcDialog(
    BuildContext context, {
    required OrderProductItem product,
    required VoidCallback onScan,
    required VoidCallback onManual,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Scan EAN/UPC',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(ctx).pop(),
                    child: const Icon(Icons.close, size: 20, color: Colors.black54),
                  ),
                ],
              ),
              const Divider(height: 20, color: Color(0xFFE0E0E0)),
              const Text(
                'By scanning the EAN/UPC products, BayFay can track and show it on the customers order details screen, it will confirm the product delivery from the merchant end. This will avoid any future escalation from the customers.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF424242),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Still if you want to go with manual update kindly click on the manual update button.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF424242),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const Divider(height: 24, color: Color(0xFFE0E0E0)),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        onScan();
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFBDBDBD)),
                        minimumSize: const Size(0, 38),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text(
                        'Scan',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        onManual();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0288D1),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 38),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text(
                        'Manual Update',
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
      ),
    );
  }

  /// Alert when product was already updated matching Android showAlertAlreadyExist (alert_update_prod.xml)
  static void showAlertAlreadyExist(
    BuildContext context, {
    required VoidCallback onUpdateAgain,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Alert',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Already updated, Do you want update again?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      onUpdateAgain();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0288D1),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(60, 34),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Text('OK', style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Date entry dialog matching Android activity_translucent_add_expire_manufa_dt.xml
  static Future<MfdExpInfo?> openDateEntryDialog(
    BuildContext context, {
    required OrderProductItem product,
    required String orderId,
    required String shopId,
    required String categoryId,
    required bool isEscalated,
    required String packagingType,
  }) {
    return showDialog<MfdExpInfo>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _MfdExpDateEntryDialog(
        product: product,
        orderId: orderId,
        shopId: shopId,
        categoryId: categoryId,
        isEscalated: isEscalated,
        packagingType: packagingType,
      ),
    );
  }

  /// Popup showing list of dates when clicking "More"
  static void showMoreDatesPopup(
    BuildContext context,
    OrderProductItem product,
  ) {
    final dates = product.mfdExp?.dates ?? const [];
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      product.productName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(ctx).pop(),
                    child: const Icon(Icons.close, size: 18),
                  ),
                ],
              ),
              const Divider(height: 16),
              const Row(
                children: [
                  Expanded(
                    child: Text(
                      'Manufacture Date',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Expiry Date',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ...dates.map(
                (d) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          d.mfgDateFormatted.isNotEmpty
                              ? d.mfgDateFormatted
                              : '-',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          d.expDateFormatted.isNotEmpty
                              ? d.expDateFormatted
                              : '-',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MfdExpDateEntryDialog extends ConsumerStatefulWidget {
  final OrderProductItem product;
  final String orderId;
  final String shopId;
  final String categoryId;
  final bool isEscalated;
  final String packagingType;

  const _MfdExpDateEntryDialog({
    required this.product,
    required this.orderId,
    required this.shopId,
    required this.categoryId,
    required this.isEscalated,
    required this.packagingType,
  });

  @override
  ConsumerState<_MfdExpDateEntryDialog> createState() =>
      _MfdExpDateEntryDialogState();
}

class _MfdExpDateEntryDialogState
    extends ConsumerState<_MfdExpDateEntryDialog> {
  final DateFormat _displayFormatter = DateFormat('dd-MM-yyyy');
  final TextEditingController _mfgController = TextEditingController();
  final TextEditingController _expController = TextEditingController();
  final TextEditingController _monthsController = TextEditingController();

  DateTime? _manufactureCalendar;
  DateTime? _expiryCalendar;
  final List<MfdExpDate> _accumulatedDates = [];
  bool _submitting = false;

  int get _requiredQty => widget.isEscalated && widget.product.escalatedQty > 0
      ? widget.product.escalatedQty
      : widget.product.quantity;

  @override
  void dispose() {
    _mfgController.dispose();
    _expController.dispose();
    _monthsController.dispose();
    super.dispose();
  }

  String _toIsoUtcString(DateTime dt) {
    final utc = DateTime.utc(dt.year, dt.month, dt.day, 0, 0, 0);
    final iso = utc.toIso8601String();
    return iso.replaceAll('Z', '+00:00');
  }

  Future<void> _pickMfgDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _manufactureCalendar ?? now,
      firstDate: DateTime(2015),
      lastDate: now,
    );
    if (!mounted) return;
    if (picked != null) {
      setState(() {
        _manufactureCalendar = picked;
        _mfgController.text = _displayFormatter.format(picked);
      });
    }
  }

  Future<void> _pickExpDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryCalendar ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: DateTime(2035),
    );
    if (!mounted) return;
    if (picked != null) {
      setState(() {
        _expiryCalendar = picked;
        _expController.text = _displayFormatter.format(picked);
        _monthsController.clear();
      });
    }
  }

  DateTime _calculateExpDateFromMonths(int months) {
    final base = _manufactureCalendar ?? DateTime.now();
    return DateTime(base.year, base.month + months, base.day);
  }

  Future<void> _handleChecked() async {
    final monthsText = _monthsController.text.trim();

    if (_expiryCalendar == null && monthsText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose expiry date / Months')),
      );
      return;
    }

    final DateTime expDateToUse;
    if (_expiryCalendar != null) {
      expDateToUse = _expiryCalendar!;
    } else {
      final months = int.tryParse(monthsText) ?? 0;
      if (months <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter valid expiry months')),
        );
        return;
      }
      expDateToUse = _calculateExpDateFromMonths(months);
    }

    if (_manufactureCalendar != null &&
        _manufactureCalendar!.year == expDateToUse.year &&
        _manufactureCalendar!.month == expDateToUse.month &&
        _manufactureCalendar!.day == expDateToUse.day) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please choose manufacture date and expiry date are not equal',
          ),
        ),
      );
      return;
    }

    final String mfgIso = _manufactureCalendar != null
        ? _toIsoUtcString(_manufactureCalendar!)
        : '';
    final String expIso = _toIsoUtcString(expDateToUse);

    _accumulatedDates.add(
      MfdExpDate(
        mfgDate: mfgIso,
        expDate: expIso,
      ),
    );

    // If all dates for the quantity have been entered
    if (_accumulatedDates.length >= _requiredQty) {
      setState(() => _submitting = true);
      final res = await ref
          .read(orderActionControllerProvider.notifier)
          .updateProductMfdExp(
            shopId: widget.shopId,
            categoryId: widget.categoryId,
            orderId: widget.orderId,
            productId: widget.product.id,
            type: 1,
            dates: _accumulatedDates,
            packagingType: widget.packagingType,
            isEscalated: widget.isEscalated,
          );
      if (mounted) {
        if (res.success) {
          AppSnackBar.showSuccess(
            context,
            res.message.isNotEmpty
                ? res.message
                : 'MFD/EXP dates updated successfully',
          );
          Navigator.of(context).pop(
            MfdExpInfo(
              type: 1,
              dates: List<MfdExpDate>.from(_accumulatedDates),
            ),
          );
        } else {
          setState(() => _submitting = false);
          AppSnackBar.showError(
            context,
            res.message.isNotEmpty
                ? res.message
                : 'Failed to update MFD/EXP dates',
          );
        }
      }
    } else {
      // Need more dates for quantity > 1
      setState(() {
        _mfgController.clear();
        _expController.clear();
        _monthsController.clear();
        _manufactureCalendar = null;
        _expiryCalendar = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Recorded ${_accumulatedDates.length} of $_requiredQty. Please enter next date.',
          ),
        ),
      );
    }
  }

  Future<void> _handleSpecialType(int type) async {
    setState(() => _submitting = true);
    final res = await ref
        .read(orderActionControllerProvider.notifier)
        .updateProductMfdExp(
          shopId: widget.shopId,
          categoryId: widget.categoryId,
          orderId: widget.orderId,
          productId: widget.product.id,
          type: type, // 2 = Not Applicable, 3 = unknown
          dates: const [],
          packagingType: 'manual',
          isEscalated: widget.isEscalated,
        );
    if (mounted) {
      if (res.success) {
        AppSnackBar.showSuccess(
          context,
          res.message.isNotEmpty
              ? res.message
              : 'Product verification updated',
        );
        Navigator.of(context).pop(
          MfdExpInfo(
            type: type,
            dates: const [],
          ),
        );
      } else {
        setState(() => _submitting = false);
        AppSnackBar.showError(
          context,
          res.message.isNotEmpty
              ? res.message
              : 'Failed to update MFD/EXP details',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.product.imageUrl;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: _submitting
          ? const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top close button
                  Align(
                    alignment: Alignment.topRight,
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(Icons.close, size: 22),
                    ),
                  ),

                  // Product image (matching img_product 200x200)
                  if (imageUrl != null && imageUrl.isNotEmpty)
                    Container(
                      width: 140,
                      height: 140,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: Colors.grey.shade100,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.inventory_2_outlined,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),

                  Text(
                    widget.product.productName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Qty: $_requiredQty  (${_accumulatedDates.length}/$_requiredQty added)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _accumulatedDates.isNotEmpty
                          ? const Color(0xFF0288D1)
                          : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Manufacture date row
                  Row(
                    children: [
                      const SizedBox(
                        width: 120,
                        child: Text(
                          'Manufacture date :',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: _pickMfgDate,
                          child: Container(
                            height: 36,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            alignment: Alignment.centerLeft,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.grey.shade400),
                            ),
                            child: Text(
                              _mfgController.text.isNotEmpty
                                  ? _mfgController.text
                                  : 'Manufacture Date',
                              style: TextStyle(
                                fontSize: 12,
                                color: _mfgController.text.isNotEmpty
                                    ? Colors.black
                                    : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        ' (Optional)',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Expiry date row (or months)
                  Row(
                    children: [
                      const SizedBox(
                        width: 120,
                        child: Text(
                          'Expiry date :',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: InkWell(
                          onTap: _pickExpDate,
                          child: Container(
                            height: 36,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            alignment: Alignment.centerLeft,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.grey.shade400),
                            ),
                            child: Text(
                              _expController.text.isNotEmpty
                                  ? _expController.text
                                  : 'Expiry Date',
                              style: TextStyle(
                                fontSize: 12,
                                color: _expController.text.isNotEmpty
                                    ? Colors.black
                                    : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          '(or)',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 36,
                          child: TextField(
                            controller: _monthsController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(fontSize: 12),
                            onChanged: (val) {
                              if (val.isNotEmpty) {
                                setState(() {
                                  _expController.clear();
                                  _expiryCalendar = null;
                                });
                              }
                            },
                            decoration: InputDecoration(
                              hintText: 'Months',
                              hintStyle: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // "Checked" button matching Android btn_checked
                  SizedBox(
                    width: 150,
                    height: 38,
                    child: ElevatedButton(
                      onPressed: _handleChecked,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0288D1),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(150, 38),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: const Text(
                        'Checked',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // "unknown" and "Not Applicable" buttons matching Android btn_unknown & btn_not_applicable
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _handleSpecialType(3), // unknown = 3
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade400),
                            backgroundColor: const Color(0xFFF7F7F7),
                            minimumSize: const Size(0, 36),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: const Text(
                            'unknown',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              _handleSpecialType(2), // not applicable = 2
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade400),
                            backgroundColor: const Color(0xFFF7F7F7),
                            minimumSize: const Size(0, 36),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: const Text(
                            'Not Applicable',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
