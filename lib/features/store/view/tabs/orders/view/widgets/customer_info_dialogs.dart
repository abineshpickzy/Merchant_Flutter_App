import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:bayfay_merchant_flutter/core/network/api_client.dart';
import 'package:bayfay_merchant_flutter/core/network/api_endpoints.dart';
import 'package:bayfay_merchant_flutter/core/widgets/widgets.dart';
import '../../controller/orders_controller.dart';
import '../../model/order_model.dart';
import 'order_card_parts.dart';
import 'order_product_info_screen.dart';
import 'delivery_person_location_screen.dart';

class CustomerInfoDialogs {
  /// Show Common Single Button Alert Dialog strictly matching Android alert_common_single_button.xml
  static void showCommonSingleButtonAlert(
    BuildContext context, {
    required String title,
    required String message,
    String buttonText = 'OK',
    VoidCallback? onDismiss,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 5,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            width: 280,
            decoration: BoxDecoration(
              color: const Color(0xFFF9F6F6),
              borderRadius: BorderRadius.circular(6),
            ),
            padding: const EdgeInsets.all(1),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 10, left: 10, right: 10),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black,
                    ),
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFDBDBDE)),
                InkWell(
                  onTap: () {
                    Navigator.of(ctx).pop();
                    onDismiss?.call();
                  },
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(6),
                    bottomRight: Radius.circular(6),
                  ),
                  child: Container(
                    height: 45,
                    alignment: Alignment.center,
                    child: Text(
                      buttonText,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF007AFF),
                        fontWeight: FontWeight.w500,
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

  /// Show Common Two Buttons Alert Dialog strictly matching Android alert_common_two_buttons.xml
  static void showCommonTwoButtonsAlert(
    BuildContext context, {
    required String title,
    required String message,
    String negativeText = 'No',
    String positiveText = 'Yes',
    required Future<void> Function() onConfirm,
  }) {
    bool isSubmitting = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            elevation: 5,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: 300,
              decoration: BoxDecoration(
                color: const Color(0xFFF9F6F6),
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.all(1),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 10, left: 10, right: 10),
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFDBDBDE)),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: isSubmitting ? null : () => Navigator.of(ctx).pop(),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(6),
                          ),
                          child: Container(
                            height: 45,
                            alignment: Alignment.center,
                            child: Text(
                              negativeText,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF007AFF),
                                fontFamily: 'Roboto',
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(width: 1, height: 45, color: const Color(0xFFDBDBDE)),
                      Expanded(
                        child: InkWell(
                          onTap: isSubmitting
                              ? null
                              : () async {
                                  setState(() => isSubmitting = true);
                                  await onConfirm();
                                  if (ctx.mounted) {
                                    Navigator.of(ctx).pop();
                                  }
                                },
                          borderRadius: const BorderRadius.only(
                            bottomRight: Radius.circular(6),
                          ),
                          child: Container(
                            height: 45,
                            alignment: Alignment.center,
                            child: isSubmitting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF007AFF),
                                    ),
                                  )
                                : Text(
                                    positiveText,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF007AFF),
                                      fontFamily: 'Roboto',
                                    ),
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
        },
      ),
    );
  }

  /// Show Customer Address Dialog matching Android BaseActivity.showAlertCustomerAddressDialog + alert_common_single_button.xml
  static void showAddress(BuildContext context, OrderModel order) {
    if (order.isSelfPickup || order.address == null) {
      showCommonSingleButtonAlert(
        context,
        title: 'Alert',
        message: 'This is self pickup order',
      );
      return;
    }

    final addr = order.address!;
    var data = '${addr.street}, ${addr.area} ${addr.zipcode}'.trim();
    if (addr.landmark.isNotEmpty) {
      data = '$data\nLandmark : ${addr.landmark}';
    }

    showCommonSingleButtonAlert(
      context,
      title: 'Customer Address',
      message: data.isNotEmpty ? data : order.customerAddress,
    );
  }

  /// Show Contact Customer Dialog matching Android contact_to_customer_pop_up.xml
  static void showContact(
    BuildContext context,
    OrderModel order, {
    String shopId = '',
  }) {
    showDialog(
      context: context,
      builder: (ctx) => _ContactCustomerPopupDialog(
        order: order,
        shopId: shopId,
      ),
    );
  }

  /// Show Customer Contact Dialog matching Android BaseActivity.showAlertCustomerContactDialog + alert_order_contact.xml
  static void showSimplePhoneContact(BuildContext context, OrderModel order) {
    final phone = order.customerMobile.trim();
    final message = phone.isNotEmpty ? phone : 'Customer contact number not available';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 5,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            width: 300,
            decoration: BoxDecoration(
              color: const Color(0xFFF9F6F6),
              borderRadius: BorderRadius.circular(6),
            ),
            padding: const EdgeInsets.all(1),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 10, left: 10, right: 10),
                  child: Text(
                    'Customer contact number',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black,
                    ),
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFDBDBDE)),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => Navigator.of(ctx).pop(),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(6),
                        ),
                        child: Container(
                          height: 45,
                          alignment: Alignment.center,
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF007AFF),
                              fontFamily: 'Roboto',
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(width: 1, height: 45, color: const Color(0xFFDBDBDE)),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          Navigator.of(ctx).pop();
                          if (phone.isNotEmpty) {
                            final uri = Uri.parse('tel:$phone');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          }
                        },
                        borderRadius: const BorderRadius.only(
                          bottomRight: Radius.circular(6),
                        ),
                        child: Container(
                          height: 45,
                          alignment: Alignment.center,
                          child: const Text(
                            'Call',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF007AFF),
                              fontFamily: 'Roboto',
                            ),
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
      },
    );
  }

  /// Show Customer Notes & Attachments Dialog matching Android BaseFragment.showAlertNotes + alert_notes.xml
  static void showNotes(BuildContext context, OrderModel order) {
    final hasFile =
        order.notesFile != null && order.notesFile!.trim().isNotEmpty;
    final noteText = order.notes?.trim() ?? '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row (alert_notes.xml lines 16-47)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Notes and Attachments',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        InkWell(
                          onTap: () => Navigator.of(ctx).pop(),
                          child: const Icon(Icons.close, size: 18),
                        ),
                      ],
                    ),
                    const Divider(color: Color(0xFFF2F2F2), height: 16),

                    // Note image immediately visible when notes.image != null (BaseFragment.java lines 242-246)
                    if (hasFile)
                      Center(
                        child: Container(
                          width: 200,
                          height: 200,
                          margin: const EdgeInsets.only(bottom: 10),
                          child: OrderProductImageWidget(
                            imageUrl: order.notesFile,
                            isNote: true,
                            width: 200,
                            height: 200,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),

                    // Note text (alert_notes.xml lines 78-90, minHeight=32dp, 12sp bold black centered)
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 32),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 8,
                      ),
                      child: Text(
                        noteText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const Divider(color: Color(0xFFF2F2F2), height: 16),

                    // Footer row: Close & Attachments buttons ALWAYS visible (alert_notes.xml lines 97-130)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        InkWell(
                          onTap: () => Navigator.of(ctx).pop(),
                          child: Container(
                            width: 80,
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Close',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        InkWell(
                          onTap: () async {
                            if (hasFile) {
                              final fileName = order.notesFile!.trim();
                              Navigator.of(ctx).pop();
                              await _downloadNotesImage(
                                context,
                                ref,
                                fileName: fileName,
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('No attachments'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Attachments',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
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
          },
        );
      },
    );
  }

  /// Download customer note image matching Android BaseFragment.callDownloadNotesImage (GET order/notes/download?file=...)
  static Future<void> _downloadNotesImage(
    BuildContext context,
    WidgetRef ref, {
    required String fileName,
  }) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get<List<int>>(
        'order/notes/download',
        queryParameters: {'file': fileName},
        options: Options(responseType: ResponseType.bytes),
        requiresAuth: true,
      );
      final bytes = response.data;
      if (bytes != null && bytes.isNotEmpty) {
        final safeName = fileName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
        final file = File('${Directory.systemTemp.path}/$safeName');
        await file.writeAsBytes(bytes, flush: true);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File downloaded.'),
              backgroundColor: Color(0xFF4CAF50),
            ),
          );
        }
        return;
      }
    } catch (_) {
      // Fallback to external browser download if direct byte stream fails
      final uri = Uri.tryParse(ApiEndpoints.orderNoteDownloadUrl(fileName));
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File download failed.')),
      );
    }
  }

  /// Show Refund Dialog matching Android alert_refund.xml
  static void showRefundDialog(
    BuildContext context, {
    required double refundAmount,
    required Future<bool> Function(bool initiateAfterReturn) onConfirm,
  }) {
    bool initiateAfterReturn = true;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Refund',
                          style: TextStyle(
                            fontSize: 15,
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
                    const Divider(color: Color(0xFFF2F2F2), height: 16),
                    const Center(
                      child: Text(
                        'Are you sure you want to initiate refund?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        'Refund Amount: ₹${refundAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Checkbox(
                          value: initiateAfterReturn,
                          onChanged: (v) {
                            setState(() {
                              initiateAfterReturn = v ?? true;
                            });
                          },
                        ),
                        const Expanded(
                          child: Text(
                            'Initiate refund after customer returned the product',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Color(0xFFF2F2F2), height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        InkWell(
                          onTap: isSubmitting
                              ? null
                              : () => Navigator.of(ctx).pop(),
                          child: Container(
                            width: 80,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Close',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        InkWell(
                          onTap: isSubmitting
                              ? null
                              : () async {
                                  setState(() => isSubmitting = true);
                                  final ok =
                                      await onConfirm(initiateAfterReturn);
                                  if (ctx.mounted) {
                                    Navigator.of(ctx).pop(ok);
                                  }
                                },
                          child: Container(
                            height: 32,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0275D8),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: isSubmitting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Initiate Refund',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white,
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
          },
        );
      },
    );
  }

  /// Show Escalate Whole Order Confirmation Dialog matching Android NewOrderFragment.showAlertCancelDialog + alert_update_prod.xml
  static void showEscalateWholeOrderDialog(
    BuildContext context, {
    required Future<bool> Function() onConfirm,
  }) {
    showCommonTwoButtonsAlert(
      context,
      title: 'Alert',
      message: 'Do you want to escalate the whole order?',
      negativeText: 'No',
      positiveText: 'Yes',
      onConfirm: () async {
        await onConfirm();
      },
    );
  }

  /// Show Invoice Popup strictly matching Android layout_popup_window.xml
  static void showInvoicePopup(
    BuildContext context, {
    required OrderModel order,
    required WidgetRef ref,
  }) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
            width: 320,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Share Invoice (light blue bg, blue border, blue text)
                _PopupWindowButton(
                  text: 'Share Invoice',
                  backgroundColor: const Color(0xFFE8F4FD),
                  borderColor: const Color(0xFF2196F3),
                  textColor: const Color(0xFF2196F3),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    AppSnackBar.showSuccess(context, 'Generating invoice...');
                    try {
                      final result = await ref
                          .read(orderActionControllerProvider.notifier)
                          .generateInvoice(orderId: order.id, flag: 1);

                      if (result.isSuccess && result.data != null && result.data!.isNotEmpty) {
                        final rawData = result.data!.trim();
                        if (rawData.startsWith('http://') || rawData.startsWith('https://')) {
                          await SharePlus.instance.share(
                            ShareParams(
                              uri: Uri.tryParse(rawData),
                              subject: 'Invoice #${order.orderId}',
                            ),
                          );
                        } else {
                          final tempDir = await getTemporaryDirectory();
                          final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
                          final fileName = '${order.orderId}-$dateStr-Invoice.html';
                          final file = File('${tempDir.path}/$fileName');
                          await file.writeAsString(rawData);
                          await SharePlus.instance.share(
                            ShareParams(
                              files: [XFile(file.path, mimeType: 'text/html', name: fileName)],
                              subject: 'Invoice #${order.orderId}',
                              text: 'Invoice for Order #${order.orderId}',
                            ),
                          );
                        }
                      } else {
                        if (context.mounted) {
                          AppSnackBar.showError(
                            context,
                            result.message ?? 'Failed to generate invoice',
                          );
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        AppSnackBar.showError(context, 'Error sharing invoice: $e');
                      }
                    }
                  },
                ),
                const SizedBox(height: 14),

                // 2. Send to Seller/Customer (light blue bg, blue border, blue text)
                _PopupWindowButton(
                  text: 'Send to Seller/Customer',
                  backgroundColor: const Color(0xFFE8F4FD),
                  borderColor: const Color(0xFF2196F3),
                  textColor: const Color(0xFF2196F3),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    AppSnackBar.showSuccess(context, 'Sending invoice...');
                    try {
                      final result = await ref
                          .read(orderActionControllerProvider.notifier)
                          .generateInvoice(orderId: order.id, flag: 2);

                      if (context.mounted) {
                        if (result.isSuccess) {
                          AppSnackBar.showSuccess(
                            context,
                            result.message ?? 'Sent to seller and customer',
                          );
                        } else {
                          AppSnackBar.showError(
                            context,
                            result.message ?? 'Cannot send to seller and customer',
                          );
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        AppSnackBar.showError(context, 'Error sending invoice: $e');
                      }
                    }
                  },
                ),
                const SizedBox(height: 14),

                // 3. Print Invoice (light blue bg, blue border, blue text)
                _PopupWindowButton(
                  text: 'Print Invoice',
                  backgroundColor: const Color(0xFFE8F4FD),
                  borderColor: const Color(0xFF2196F3),
                  textColor: const Color(0xFF2196F3),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    AppSnackBar.showError(context, 'Coming Soon');
                  },
                ),
                const SizedBox(height: 14),

                // 4. Cancel (solid red bg, white text)
                _PopupWindowButton(
                  text: 'Cancel',
                  backgroundColor: const Color(0xFFE53935),
                  borderColor: Colors.transparent,
                  textColor: Colors.white,
                  onTap: () => Navigator.of(ctx).pop(),
                ),
                const SizedBox(height: 14),

                // 5. Printer Setting (solid blue bg, white text)
                _PopupWindowButton(
                  text: 'Printer Setting',
                  backgroundColor: const Color(0xFF0275D8),
                  borderColor: Colors.transparent,
                  textColor: Colors.white,
                  onTap: () {
                    Navigator.of(ctx).pop();
                    AppSnackBar.showError(context, 'Coming Soon');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Show Delivery Person Info screen matching Android DeliveryPersonCurrentLocationActivity
  static void showDeliveryPersonInfo(
    BuildContext context, {
    required OrderModel order,
  }) {
    DeliveryPersonLocationScreen.open(context, order: order);
  }

  /// Open Product Info Screen matching Android ProductFragment + ProductInfo + ReviewFragment
  static void showProductInfoDialog(
    BuildContext context,
    OrderProductItem product, {
    String shopId = '',
    String categoryId = '',
  }) {
    OrderProductInfoScreen.open(
      context,
      product: product,
      shopId: shopId,
      categoryId: categoryId,
    );
  }
}

class _PopupWindowButton extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final VoidCallback onTap;

  const _PopupWindowButton({
    required this.text,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 38,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(3),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(3),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                color: borderColor,
                width: borderColor == Colors.transparent ? 0 : 1,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: textColor,
                fontFamily: 'Nunito',
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ContactCustomerPopupDialog extends ConsumerStatefulWidget {
  final OrderModel order;
  final String shopId;

  const _ContactCustomerPopupDialog({
    required this.order,
    required this.shopId,
  });

  @override
  ConsumerState<_ContactCustomerPopupDialog> createState() =>
      _ContactCustomerPopupDialogState();
}

class _ContactCustomerPopupDialogState
    extends ConsumerState<_ContactCustomerPopupDialog> {
  final TextEditingController _msgController = TextEditingController();
  String? _selectedTemplate;
  bool _sending = false;

  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(
      contactTemplatesProvider((
        shopId: widget.shopId,
        orderId: widget.order.id,
      )),
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Message to Customer',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF424242),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(Icons.close, size: 20, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE0E0E0)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                templatesAsync.when(
                  loading: () => const SizedBox(
                    height: 35,
                    child: Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (templates) {
                    if (templates.isEmpty) return const SizedBox.shrink();
                    return Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedTemplate,
                          isExpanded: true,
                          hint: const Text(
                            'Select message template',
                            style: TextStyle(fontSize: 12),
                          ),
                          items: templates
                              .map(
                                (t) => DropdownMenuItem<String>(
                                  value: t.message,
                                  child: Text(
                                    t.message,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedTemplate = val;
                              if (val != null) {
                                _msgController.text = val;
                              }
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _msgController,
                  minLines: 5,
                  maxLines: 7,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Write message to customer...',
                    contentPadding: const EdgeInsets.all(8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Note: This will send push and sms to the customer',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF424242),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE0E0E0)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                InkWell(
                  onTap: () async {
                    if (widget.order.customerMobile.isEmpty) {
                      AppSnackBar.showError(
                        context,
                        'Customer mobile number not available',
                      );
                      return;
                    }
                    final uri = Uri.parse('tel:${widget.order.customerMobile}');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                  child: Container(
                    width: 130,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Call',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: _sending
                      ? null
                      : () async {
                          final msg = _msgController.text.trim();
                          if (msg.isEmpty) {
                            AppSnackBar.showError(
                              context,
                              'Please enter a message',
                            );
                            return;
                          }
                          setState(() => _sending = true);
                          final res = await ref
                              .read(orderActionControllerProvider.notifier)
                              .sendCustomerMessage(
                                orderId: widget.order.id,
                                storeId: widget.shopId,
                                message: msg,
                              );
                          if (context.mounted) {
                            Navigator.of(context).pop();
                            if (res.success) {
                              AppSnackBar.showSuccess(
                                context,
                                res.message.isNotEmpty
                                    ? res.message
                                    : 'Message sent to customer',
                              );
                            } else {
                              AppSnackBar.showError(
                                context,
                                res.message.isNotEmpty
                                    ? res.message
                                    : 'Failed to send message',
                              );
                            }
                          }
                        },
                  child: Container(
                    width: 130,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0275D8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: _sending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Send Message',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
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
    );
  }
}
