import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:bayfay_merchant_flutter/app/theme/app_colors.dart';
import 'package:bayfay_merchant_flutter/core/widgets/widgets.dart';
import '../../controller/orders_controller.dart';
import '../../model/order_model.dart';

/// Accept Order Dialog strictly matching Android assignee_alert_dialog.xml
class AcceptOrderDialog extends ConsumerStatefulWidget {
  final OrderModel order;
  final String shopId;
  final String categoryId;
  final String? productId;
  final String? correspondenceId;

  const AcceptOrderDialog({
    super.key,
    required this.order,
    required this.shopId,
    required this.categoryId,
    this.productId,
    this.correspondenceId,
  });

  static Future<bool?> show(
    BuildContext context, {
    required OrderModel order,
    required String shopId,
    required String categoryId,
    String? productId,
    String? correspondenceId,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AcceptOrderDialog(
        order: order,
        shopId: shopId,
        categoryId: categoryId,
        productId: productId,
        correspondenceId: correspondenceId,
      ),
    );
  }

  @override
  ConsumerState<AcceptOrderDialog> createState() => _AcceptOrderDialogState();
}

class _AcceptOrderDialogState extends ConsumerState<AcceptOrderDialog> {
  late DateTime _expectedDateTime;
  bool _isManualAssign = false;
  String? _selectedAssistantId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Default expected delivery time to now + 45 minutes
    _expectedDateTime = DateTime.now().add(const Duration(minutes: 45));
  }

  String get _formattedExpectedTime {
    return DateFormat('yyyy-MM-dd HH:mm').format(_expectedDateTime);
  }

  String get _displayExpectedTime {
    return DateFormat('dd MMM yyyy, hh:mm a').format(_expectedDateTime);
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _expectedDateTime.isAfter(now) ? _expectedDateTime : now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_expectedDateTime),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime == null || !mounted) return;

    setState(() {
      _expectedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _handleConfirm() async {
    if (_isSubmitting) return;

    if (_isManualAssign && (_selectedAssistantId == null || _selectedAssistantId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a delivery assistant or switch to Auto Assign'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final res = await ref
        .read(orderActionControllerProvider.notifier)
        .acceptOrder(
          shopId: widget.shopId,
          categoryId: widget.categoryId,
          orderId: widget.order.id,
          expectedTime: _formattedExpectedTime,
          assistantId: _isManualAssign ? _selectedAssistantId : null,
          autoAssign: !_isManualAssign,
          isEscalated: widget.order.isEscalatedOrder || widget.order.hasEscalation,
          isSelfPickup: widget.order.isSelfPickup,
          productId: widget.productId,
          correspondenceId: widget.correspondenceId,
        );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (res.success) {
        AppSnackBar.showSuccess(
          context,
          res.message.isNotEmpty ? res.message : 'Order accepted successfully',
        );
        Navigator.of(context).pop(true);
      } else {
        AppSnackBar.showError(
          context,
          res.message.isNotEmpty ? res.message : 'Failed to accept order',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSelfPickup = widget.order.isSelfPickup;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.white,
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Toolbar matching Android toolBarprofile
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFF7F8FA),
                border: Border(bottom: BorderSide(color: AppColors.divider)),
              ),
              child: Row(
                children: [
                  const Text(
                    'Accept Order',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black87),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
            ),

            // 2. Split section: Customer Preferred Time & Expected Delivery Time
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    // Left: Customer Preferred Time
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            'Customer Preferred Time:',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.order.preferredTime.isNotEmpty
                                ? widget.order.preferredTime
                                : 'Immediate',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFF4040),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Container(
                      height: 48,
                      width: 1,
                      color: AppColors.border,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                    ),

                    // Right: Expected Delivery Time picker
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            'Expected Delivery Time:',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: _pickDateTime,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: Text(
                                      _displayExpectedTime,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.calendar_today,
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Divider(height: 1, color: AppColors.divider),

            // 3. Assign Mode: Auto Assign vs Manual Assign (if not Self Pickup)
            if (isSelfPickup) ...[
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.storefront, color: AppColors.warning, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Self Pickup Order: Customer will collect order from store.',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Auto Assign',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: !_isManualAssign ? AppColors.primary : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: _isManualAssign,
                      activeColor: AppColors.primary,
                      onChanged: (val) {
                        setState(() {
                          _isManualAssign = val;
                          if (!val) _selectedAssistantId = null;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Manual Assign',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _isManualAssign ? AppColors.primary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // 4. Delivery Associate List (when Manual Assign is ON)
              if (_isManualAssign) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                  child: Text(
                    'Select Delivery Assistant',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Expanded(
                  child: Consumer(
                    builder: (context, ref, _) {
                      final assistantsAsync = ref.watch(
                        activeDeliveryAssistantsProvider((
                          orderId: widget.order.id,
                          expectedDeliveryTime: _formattedExpectedTime,
                        )),
                      );

                      return assistantsAsync.when(
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: LoadingIndicator(size: 32),
                          ),
                        ),
                        error: (_, __) => _buildNoAssociates(),
                        data: (assistants) {
                          if (assistants.isEmpty) {
                            return _buildNoAssociates();
                          }

                          return ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            itemCount: assistants.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final assistant = assistants[index];
                              final isSelected = _selectedAssistantId == assistant.id;

                              return InkWell(
                                onTap: () => setState(() => _selectedAssistantId = assistant.id),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primaryLight.withValues(alpha: 0.25)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected ? AppColors.primary : AppColors.border,
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Radio<String>(
                                        value: assistant.id,
                                        groupValue: _selectedAssistantId,
                                        activeColor: AppColors.primary,
                                        onChanged: (val) =>
                                            setState(() => _selectedAssistantId = val),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              assistant.fullName,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${assistant.distance.toStringAsFixed(2)} km from Shop | ${assistant.orders} orders',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: assistant.isInService
                                              ? AppColors.success.withValues(alpha: 0.15)
                                              : AppColors.error.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          assistant.isInService ? 'In Service' : 'Idle',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: assistant.isInService
                                                ? AppColors.success
                                                : AppColors.error,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ],

            // 5. Bottom Buttons matching Android close_btn / save_btn / assign_btn (assignee_alert_dialog.xml)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 130,
                    height: 34,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        side: const BorderSide(color: Color(0xFFD1D1D1), width: 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'ProductSans',
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 140,
                    height: 34,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _handleConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0275D8),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _isManualAssign ? 'Accept & Assign' : 'Accept',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'ProductSans',
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoAssociates() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delivery_dining_outlined, size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            const Text(
              'Currently No Delivery Associate Available',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
