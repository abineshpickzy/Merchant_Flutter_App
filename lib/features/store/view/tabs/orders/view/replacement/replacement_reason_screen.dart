import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayfay_merchant_flutter/core/widgets/widgets.dart';
import '../../controller/orders_controller.dart';
import '../../model/order_model.dart';
import '../widgets/customer_info_dialogs.dart';
import '../widgets/order_card_parts.dart';

/// Product Escalation Correspondence & Action Screen matching Android ReplacementReasonFragment (fragment_replacement_reason.xml)
class ReplacementReasonScreen extends ConsumerStatefulWidget {
  final OrderModel order;
  final OrderProductItem product;
  final String shopId;
  final String categoryId;
  final bool showActionControls;

  const ReplacementReasonScreen({
    super.key,
    required this.order,
    required this.product,
    required this.shopId,
    required this.categoryId,
    this.showActionControls = true,
  });

  @override
  ConsumerState<ReplacementReasonScreen> createState() =>
      _ReplacementReasonScreenState();
}

class _ReplacementReasonScreenState
    extends ConsumerState<ReplacementReasonScreen> {
  final TextEditingController _feedbackCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _feedbackCtrl.dispose();
    super.dispose();
  }

  bool get _canActOnProduct {
    if (!widget.showActionControls) return false;
    final es = widget.product.escalationStatus;
    final vs = widget.product.verifyStatus;
    // ESCALATION_CLIENT = 1 (merchant can act).
    // Already acted: ESCALATION_MERCHANT (2), ACCEPTED_CLIENT (3), ACCEPTED_MERCHANT (4),
    // REFUND_REQUEST (5), REFUND_INITIATE (6), CLOSE (7), TEMPLATE_ACCEPT (8), or VERIFY_STATUS_DELIVERED (4).
    if (es >= 2 || vs == 4) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final chatArg = (
      shopId: widget.shopId,
      categoryId: widget.categoryId,
      orderId: widget.order.id,
      productId: widget.product.id,
    );
    final chatAsync = ref.watch(escalationChatProvider(chatArg));
    final isOnline =
        widget.order.paymentType.toLowerCase().contains('online');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(45),
        child: AppBar(
          backgroundColor: const Color(0xFFF2F2F2),
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF333333)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Replacement/Undelivered',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
        ),
      ),
      body: Container(
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: const Color(0xFFDADADA), width: 1),
        ),
        child: Column(
          children: [
            // Correspondence Chat History
            Expanded(
              child: chatAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Text(
                    'Failed to load correspondence: $err',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
                data: (messages) {
                  if (messages.isEmpty) {
                    return const Center(
                      child: Text(
                        'No correspondence messages found.',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: messages.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final m = messages[index];
                      final isMerchant =
                          m.by.toLowerCase().contains('merchant') ||
                              m.by.toLowerCase().contains('shop') ||
                              m.by.toLowerCase().contains('seller');
                      return Align(
                        alignment: isMerchant
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isMerchant
                                ? const Color(0xFFE3F2FD)
                                : const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isMerchant
                                  ? const Color(0xFF90CAF9)
                                  : const Color(0xFFE0E0E0),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    m.by.isNotEmpty
                                        ? m.by.toUpperCase()
                                        : 'CUSTOMER',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isMerchant
                                          ? const Color(0xFF0275D8)
                                          : const Color(0xFFEE0000),
                                    ),
                                  ),
                                  if (m.atFormatted.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      m.atFormatted,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              if (m.imageName != null &&
                                  m.imageName!.trim().isNotEmpty) ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: OrderProductImageWidget(
                                    imageUrl: m.imageName,
                                    isEscalated: true,
                                    width: 180,
                                    height: 180,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(height: 6),
                              ],
                              if (m.message.isNotEmpty)
                                Text(
                                  m.message,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black87,
                                  ),
                                ),
                              if (m.isTemplate &&
                                  !isMerchant &&
                                  _canActOnProduct) ...[
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    InkWell(
                                      onTap: _submitting
                                          ? null
                                          : () async {
                                              setState(() => _submitting = true);
                                              final res = await ref
                                                  .read(
                                                      orderActionControllerProvider
                                                          .notifier)
                                                  .acceptEscalationTemplate(
                                                    shopId: widget.shopId,
                                                    categoryId:
                                                        widget.categoryId,
                                                    orderId: widget.order.id,
                                                    productId:
                                                        widget.product.id,
                                                    correspondenceId: m.id,
                                                  );
                                              if (mounted) {
                                                setState(
                                                    () => _submitting = false);
                                              }
                                              if (context.mounted) {
                                                if (res.success) {
                                                  AppSnackBar.showSuccess(
                                                    context,
                                                    res.message.isNotEmpty
                                                        ? res.message
                                                        : 'Template accepted',
                                                  );
                                                } else {
                                                  AppSnackBar.showError(
                                                    context,
                                                    res.message.isNotEmpty
                                                        ? res.message
                                                        : 'Failed to accept template',
                                                  );
                                                }
                                              }
                                            },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0275D8),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'Accept',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    InkWell(
                                      onTap: _submitting
                                          ? null
                                          : () async {
                                              setState(() => _submitting = true);
                                              final res = await ref
                                                  .read(
                                                      orderActionControllerProvider
                                                          .notifier)
                                                  .denyEscalationTemplate(
                                                    shopId: widget.shopId,
                                                    categoryId:
                                                        widget.categoryId,
                                                    orderId: widget.order.id,
                                                    productId:
                                                        widget.product.id,
                                                    correspondenceId: m.id,
                                                  );
                                              if (mounted) {
                                                setState(
                                                    () => _submitting = false);
                                              }
                                              if (context.mounted) {
                                                if (res.success) {
                                                  AppSnackBar.showSuccess(
                                                    context,
                                                    res.message.isNotEmpty
                                                        ? res.message
                                                        : 'Template denied',
                                                  );
                                                } else {
                                                  AppSnackBar.showError(
                                                    context,
                                                    res.message.isNotEmpty
                                                        ? res.message
                                                        : 'Failed to deny template',
                                                  );
                                                }
                                              }
                                            },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEE0000),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'Deny',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Bottom Feedback & Action Buttons (Refund / Escalate / Accept)
            if (_canActOnProduct) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: TextField(
                  controller: _feedbackCtrl,
                  minLines: 3,
                  maxLines: 6,
                  style: const TextStyle(fontSize: 12),
                  decoration: const InputDecoration(
                    hintText: 'Enter your feedback/response',
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (isOnline) ...[
                    _ReasonActionBtn(
                      label: 'Refund',
                      color: const Color(0xFFEE0000),
                      onTap: _submitting
                          ? null
                          : () {
                              CustomerInfoDialogs.showRefundDialog(
                                context,
                                refundAmount:
                                    widget.product.escalatedTotalPrice,
                                onConfirm: (initiateAfterReturn) async {
                                  final res = await ref
                                      .read(
                                          orderActionControllerProvider.notifier)
                                      .refundEscalatedProduct(
                                        shopId: widget.shopId,
                                        categoryId: widget.categoryId,
                                        orderId: widget.order.id,
                                        productId: widget.product.id,
                                        isRequest: initiateAfterReturn,
                                      );
                                  if (context.mounted) {
                                    if (res.success) {
                                      AppSnackBar.showSuccess(
                                        context,
                                        res.message.isNotEmpty
                                            ? res.message
                                            : 'Refund processed successfully',
                                      );
                                      Navigator.of(context).pop(true);
                                    } else {
                                      AppSnackBar.showError(
                                        context,
                                        res.message.isNotEmpty
                                            ? res.message
                                            : 'Failed to process refund',
                                      );
                                    }
                                  }
                                  return res.success;
                                },
                              );
                            },
                    ),
                    const SizedBox(width: 24),
                  ],
                  _ReasonActionBtn(
                    label: 'Escalate',
                    color: const Color(0xFFEE0000),
                    onTap: _submitting
                        ? null
                        : () async {
                            final msg = _feedbackCtrl.text.trim();
                            if (msg.isEmpty) {
                              AppSnackBar.showError(
                                context,
                                'Please enter feedback',
                              );
                              return;
                            }
                            setState(() => _submitting = true);
                            final res = await ref
                                .read(orderActionControllerProvider.notifier)
                                .escalateProduct(
                                  shopId: widget.shopId,
                                  categoryId: widget.categoryId,
                                  orderId: widget.order.id,
                                  productId: widget.product.id,
                                  message: msg,
                                );
                            if (context.mounted) {
                              setState(() => _submitting = false);
                              if (res.success) {
                                AppSnackBar.showSuccess(
                                  context,
                                  res.message.isNotEmpty
                                      ? res.message
                                      : 'Product escalated successfully',
                                );
                                Navigator.of(context).pop(true);
                              } else {
                                AppSnackBar.showError(
                                  context,
                                  res.message.isNotEmpty
                                      ? res.message
                                      : 'Failed to escalate product',
                                );
                              }
                            }
                          },
                  ),
                  const SizedBox(width: 24),
                  _ReasonActionBtn(
                    label: 'Accept',
                    color: const Color(0xFF0275D8),
                    onTap: _submitting
                        ? null
                        : () async {
                            setState(() => _submitting = true);
                            final msgs = chatAsync.valueOrNull ?? [];
                            final latestCorrespondenceId =
                                msgs.isNotEmpty ? msgs.last.id : null;
                            final res = await ref
                                .read(orderActionControllerProvider.notifier)
                                .acceptEscalatedProduct(
                                  shopId: widget.shopId,
                                  categoryId: widget.categoryId,
                                  orderId: widget.order.id,
                                  productId: widget.product.id,
                                  correspondenceId: latestCorrespondenceId,
                                );
                            if (context.mounted) {
                              setState(() => _submitting = false);
                              if (res.success) {
                                AppSnackBar.showSuccess(
                                  context,
                                  res.message.isNotEmpty
                                      ? res.message
                                      : 'Product accepted successfully',
                                );
                                Navigator.of(context).pop(true);
                              } else {
                                AppSnackBar.showError(
                                  context,
                                  res.message.isNotEmpty
                                      ? res.message
                                      : 'Failed to accept product',
                                );
                              }
                            }
                          },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReasonActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ReasonActionBtn({
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
