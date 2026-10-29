import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:bayfay_merchant_flutter/features/dashboard/model/store_model.dart';
import 'package:bayfay_merchant_flutter/features/store/view/widgets/store_tab_app_bar.dart';
import '../controller/delivery_setting_controller.dart';
import '../model/delivery_setting_model.dart';

class StoreDeliverySettingView extends ConsumerStatefulWidget {
  final StoreModel store;

  const StoreDeliverySettingView({super.key, required this.store});

  @override
  ConsumerState<StoreDeliverySettingView> createState() =>
      _StoreDeliverySettingViewState();
}

class _StoreDeliverySettingViewState
    extends ConsumerState<StoreDeliverySettingView> {
  late TextEditingController _deliveryFeeController;
  late TextEditingController _minPurchaseLimitController;
  late TextEditingController _perKmFeeController;
  late TextEditingController _codLimitController;
  late TextEditingController _otherFeeController;
  late TextEditingController _otherLimitController;

  @override
  void initState() {
    super.initState();
    _deliveryFeeController = TextEditingController();
    _minPurchaseLimitController = TextEditingController();
    _perKmFeeController = TextEditingController();
    _codLimitController = TextEditingController();
    _otherFeeController = TextEditingController();
    _otherLimitController = TextEditingController();
  }

  @override
  void dispose() {
    _deliveryFeeController.dispose();
    _minPurchaseLimitController.dispose();
    _perKmFeeController.dispose();
    _codLimitController.dispose();
    _otherFeeController.dispose();
    _otherLimitController.dispose();
    super.dispose();
  }

  void _syncControllers(StoreDeliverySettingState state) {
    if (_deliveryFeeController.text.isEmpty && state.deliveryFee > 0) {
      _deliveryFeeController.text = state.deliveryFee.toString();
    }
    if (_minPurchaseLimitController.text.isEmpty &&
        state.deliveryFeeLimit > 0) {
      _minPurchaseLimitController.text = state.deliveryFeeLimit.toString();
    }
    if (_perKmFeeController.text.isEmpty && state.perKmFee > 0) {
      _perKmFeeController.text = state.perKmFee.toString();
    }
    if (_codLimitController.text.isEmpty && state.codLimit > 0) {
      _codLimitController.text = state.codLimit.toString();
    }
    if (_otherFeeController.text.isEmpty && state.otherDeliveryFee > 0) {
      _otherFeeController.text = state.otherDeliveryFee.toString();
    }
    if (_otherLimitController.text.isEmpty &&
        state.otherDeliveryFeeLimit > 0) {
      _otherLimitController.text = state.otherDeliveryFeeLimit.toString();
    }
  }

  String _formatTo12Hour(String time) {
    final clean = time.trim();
    if (clean.isEmpty) return '00:00';
    final upper = clean.toUpperCase();
    if (upper.contains('AM') || upper.contains('PM')) return clean;

    try {
      if (clean.contains('T')) {
        final dt = DateTime.parse(clean).toLocal();
        return DateFormat('hh:mm a').format(dt);
      }
    } catch (_) {}

    try {
      final parts = clean.split(':');
      if (parts.isNotEmpty) {
        final hour = int.parse(parts[0]);
        final minute = parts.length > 1 ? int.parse(parts[1].split('.')[0]) : 0;
        final period = hour >= 12 ? 'PM' : 'AM';
        final h12 = hour % 12 == 0 ? 12 : hour % 12;
        return '${h12.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
      }
    } catch (_) {}

    return clean;
  }

  Future<void> _pickTime({
    required BuildContext context,
    required String currentTime,
    required ValueChanged<String> onSelected,
  }) async {
    int initialHour = 9;
    int initialMinute = 0;

    try {
      final clean = currentTime.trim();
      if (clean.contains(':')) {
        final parts = clean.split(':');
        initialHour = int.tryParse(parts[0]) ?? 9;
        final minutePart = parts.length > 1 ? parts[1].split(' ')[0] : '0';
        initialMinute = int.tryParse(minutePart) ?? 0;
        if (clean.toUpperCase().contains('PM') && initialHour < 12) {
          initialHour += 12;
        } else if (clean.toUpperCase().contains('AM') && initialHour == 12) {
          initialHour = 0;
        }
      }
    } catch (_) {}

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
    );

    if (!mounted || picked == null) return;

    final period = picked.hour >= 12 ? 'PM' : 'AM';
    final h12 = picked.hour % 12 == 0 ? 12 : picked.hour % 12;
    final formatted12 =
        '${h12.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')} $period';
    onSelected(formatted12);
  }

  Future<void> _handleSave(StoreDeliverySettingController controller) async {
    final res = await controller.saveDeliveryConfig();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res.message),
        backgroundColor: res.success ? Colors.green : Colors.red,
      ),
    );

    if (res.success) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state =
        ref.watch(storeDeliverySettingControllerProvider(widget.store));
    final controller = ref.read(
        storeDeliverySettingControllerProvider(widget.store).notifier);

    _syncControllers(state);

    final isBusy = state.isLoading || state.isSaving;
    final replacementOptions = getDeliveryDaysOptions(state.replacementDays);
    final refundOptions = getDeliveryDaysOptions(state.refundDays);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: StoreTabAppBar(
        title: 'Edit Delivery Config',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF616161)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        trailing: state.hasEditPrivilege
            ? Padding(
                padding: const EdgeInsets.only(right: 8),
                child: SizedBox(
                  width: 76,
                  height: 36,
                  child: ElevatedButton(
                    onPressed: isBusy ? null : () => _handleSave(controller),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: state.isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              )
            : null,
      ),
      body: Column(
        children: [
          const Divider(height: 1, thickness: 1, color: Color(0xFFE3E3E3)),
          if (isBusy)
            const LinearProgressIndicator(
              minHeight: 2.5,
              backgroundColor: Color(0xFFE3F2FD),
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF297BFE)),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Product Replacement Within
                  _buildFieldLabel(
                      'Product replacement within: * (In case any escalation)'),
                  const SizedBox(height: 4),
                  _buildDropdownContainer(
                    child: DropdownButton<int>(
                      value: replacementOptions
                              .any((o) => o.days == state.replacementDays)
                          ? state.replacementDays
                          : replacementOptions.first.days,
                      isExpanded: true,
                      underline: const SizedBox.shrink(),
                      items: replacementOptions
                          .map((opt) => DropdownMenuItem(
                                value: opt.days,
                                child: Text(
                                  opt.label,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF333333),
                                  ),
                                ),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) controller.setReplacementDays(val);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2. Refund Within
                  _buildFieldLabel(
                      'Refund within: * (In case of order cancellation)'),
                  const SizedBox(height: 4),
                  _buildDropdownContainer(
                    child: DropdownButton<int>(
                      value: refundOptions.any((o) => o.days == state.refundDays)
                          ? state.refundDays
                          : refundOptions.first.days,
                      isExpanded: true,
                      underline: const SizedBox.shrink(),
                      items: refundOptions
                          .map((opt) => DropdownMenuItem(
                                value: opt.days,
                                child: Text(
                                  opt.label,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF333333),
                                  ),
                                ),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) controller.setRefundDays(val);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. Separator Line: Nearby Location
                  _buildSeparatorWithChip('Nearby Location'),
                  const SizedBox(height: 14),

                  // 4. Max Delivery Distance
                  _buildFieldLabel('Max delivery distance: *'),
                  const SizedBox(height: 4),
                  _buildDropdownContainer(
                    child: DropdownButton<int>(
                      value: (state.currentRadius <= state.maxRadius &&
                              state.currentRadius > 0)
                          ? state.currentRadius
                          : 1,
                      isExpanded: true,
                      underline: const SizedBox.shrink(),
                      items: List.generate(
                        state.maxRadius,
                        (i) => DropdownMenuItem(
                          value: i + 1,
                          child: Text('${i + 1} km',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF333333),
                              )),
                        ),
                      ),
                      onChanged: (val) {
                        if (val != null) controller.setCurrentRadius(val);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 5. Delivery Time (12h format display matching Android)
                  _buildFieldLabel('Delivery time: *'),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Text(
                        'From:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2196F3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => _pickTime(
                          context: context,
                          currentTime: state.fromTime,
                          onSelected: controller.setFromTime,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F7F7),
                            border: Border.all(
                              color: const Color(0xFFE0E0E0),
                              width: 0.5,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Text(
                                _formatTo12Hour(state.fromTime),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF333333),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.access_time,
                                size: 16,
                                color: Color(0xFF757575),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'To:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2196F3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => _pickTime(
                          context: context,
                          currentTime: state.toTime,
                          onSelected: controller.setToTime,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F7F7),
                            border: Border.all(
                              color: const Color(0xFFE0E0E0),
                              width: 0.5,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Text(
                                _formatTo12Hour(state.toTime),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF333333),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.access_time,
                                size: 16,
                                color: Color(0xFF757575),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 6. Delivery By
                  _buildFieldLabel('Delivery by: *'),
                  Row(
                    children: [
                      _buildCheckboxOption(
                        label: 'Shop',
                        checked: state.localDeliveryTypes.contains(1),
                        onChanged: () => controller.toggleLocalDeliveryType(1),
                      ),
                      const SizedBox(width: 16),
                      _buildCheckboxOption(
                        label: 'Agency',
                        checked: state.localDeliveryTypes.contains(2),
                        onChanged: () => controller.toggleLocalDeliveryType(2),
                      ),
                      const SizedBox(width: 16),
                      _buildCheckboxOption(
                        label: 'Self Pick Up',
                        checked: state.localDeliveryTypes.contains(3),
                        onChanged: () => controller.toggleLocalDeliveryType(3),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 7. Delivery Charge & Min Purchase Limit
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel('Delivery charge: *'),
                            const SizedBox(height: 4),
                            TextField(
                              controller: _deliveryFeeController,
                              keyboardType: TextInputType.number,
                              onChanged: (val) {
                                controller.setDeliveryFee(int.tryParse(val) ?? 0);
                              },
                              style: const TextStyle(fontSize: 13),
                              decoration: _inputDecoration(hintText: '0'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel('Min. purchase limit:'),
                            const SizedBox(height: 4),
                            TextField(
                              controller: _minPurchaseLimitController,
                              keyboardType: TextInputType.number,
                              onChanged: (val) {
                                controller.setDeliveryFeeLimit(
                                    int.tryParse(val) ?? 0);
                              },
                              style: const TextStyle(fontSize: 13),
                              decoration: _inputDecoration(hintText: '0'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 8. Delivery Charge per Km
                  _buildFieldLabel('Delivery charge per km:'),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _perKmFeeController,
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      controller.setPerKmFee(int.tryParse(val) ?? 0);
                    },
                    style: const TextStyle(fontSize: 13),
                    decoration: _inputDecoration(hintText: '0'),
                  ),
                  const SizedBox(height: 12),

                  // 9. Delivery Fee for Subscription Orders Checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: state.deliveryFeeSubscription,
                        activeColor: const Color(0xFF2196F3),
                        onChanged: (val) {
                          if (val != null) {
                            controller.setDeliveryFeeSubscription(val);
                          }
                        },
                      ),
                      const Expanded(
                        child: Text(
                          'Delivery fee for subscription orders',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // 10. Limit Applied Checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: state.isLimitApplied,
                        activeColor: const Color(0xFF2196F3),
                        onChanged: (val) {
                          if (val != null) {
                            controller.setIsLimitApplied(val);
                          }
                        },
                      ),
                      const Expanded(
                        child: Text(
                          'Limit applied only when delivery charge is not 0',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF757575),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 11. Cash on Delivery Row
                  Row(
                    children: [
                      _buildFieldLabel('Cash on delivery: *'),
                      const Spacer(),
                      Switch(
                        value: state.isCodEnabled,
                        activeColor: const Color(0xFF2196F3),
                        onChanged: (val) {
                          final ok = controller.setCodEnabled(val);
                          if (!ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Both cash on delivery and online payment cannot be turned off',
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),

                  if (state.isCodEnabled) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdownContainer(
                            child: DropdownButton<String>(
                              value: state.codLimitType,
                              isExpanded: true,
                              underline: const SizedBox.shrink(),
                              items: const [
                                DropdownMenuItem(
                                  value: 'any',
                                  child: Text('Any',
                                      style: TextStyle(fontSize: 13)),
                                ),
                                DropdownMenuItem(
                                  value: 'limit',
                                  child: Text('Limit',
                                      style: TextStyle(fontSize: 13)),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  controller.setCodLimitType(val);
                                }
                              },
                            ),
                          ),
                        ),
                        if (state.codLimitType == 'limit') ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _codLimitController,
                              keyboardType: TextInputType.number,
                              onChanged: (val) {
                                controller.setCodLimit(int.tryParse(val) ?? 0);
                              },
                              style: const TextStyle(fontSize: 13),
                              decoration: _inputDecoration(hintText: '0'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),

                  // 12. Online Payment Switch
                  Row(
                    children: [
                      _buildFieldLabel('Online payment: *'),
                      const Spacer(),
                      Switch(
                        value: state.isOnlinePaymentEnabled,
                        activeColor: const Color(0xFF2196F3),
                        onChanged: (val) {
                          final ok = controller.setOnlinePaymentEnabled(val);
                          if (!ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Both cash on delivery and online payment cannot be turned off',
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 13. Available Days
                  _buildFieldLabel('Available days: *'),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final day in [
                        'SUN',
                        'MON',
                        'TUE',
                        'WED',
                        'THU',
                        'FRI',
                        'SAT'
                      ])
                        FilterChip(
                          label: Text(day),
                          selected: state.availability.contains(day),
                          selectedColor: const Color(0xFF2196F3),
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: state.availability.contains(day)
                                ? Colors.white
                                : Colors.black87,
                          ),
                          backgroundColor: const Color(0xFFF7F7F7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                            side: BorderSide(
                              color: state.availability.contains(day)
                                  ? const Color(0xFF2196F3)
                                  : const Color(0xFFE0E0E0),
                              width: 0.5,
                            ),
                          ),
                          onSelected: (_) =>
                              controller.toggleAvailabilityDay(day),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 14. Separator Line: Ship To Other Locations
                  _buildSeparatorWithChip('Ship To Other Locations'),
                  const SizedBox(height: 14),

                  // 15. Other Location Switch
                  Row(
                    children: [
                      _buildFieldLabel('Ship to other locations:'),
                      const Spacer(),
                      Switch(
                        value: state.isOtherLocationEnabled,
                        activeColor: const Color(0xFF2196F3),
                        onChanged: state.isOtherLocked
                            ? null
                            : controller.setOtherLocationEnabled,
                      ),
                    ],
                  ),

                  if (state.isOtherLocationEnabled) ...[
                    const SizedBox(height: 8),
                    _buildFieldLabel('Delivery by: *'),
                    Row(
                      children: [
                        _buildCheckboxOption(
                          label: 'Shop',
                          checked: state.otherDeliveryTypes.contains(1),
                          onChanged: () =>
                              controller.toggleOtherDeliveryType(1),
                        ),
                        const SizedBox(width: 16),
                        _buildCheckboxOption(
                          label: 'Agency',
                          checked: state.otherDeliveryTypes.contains(2),
                          onChanged: () =>
                              controller.toggleOtherDeliveryType(2),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('Delivery charge: *'),
                              const SizedBox(height: 4),
                              TextField(
                                controller: _otherFeeController,
                                keyboardType: TextInputType.number,
                                onChanged: (val) {
                                  controller.setOtherDeliveryFee(
                                      int.tryParse(val) ?? 0);
                                },
                                style: const TextStyle(fontSize: 13),
                                decoration: _inputDecoration(hintText: '0'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('Min. purchase limit:'),
                              const SizedBox(height: 4),
                              TextField(
                                controller: _otherLimitController,
                                keyboardType: TextInputType.number,
                                onChanged: (val) {
                                  controller.setOtherDeliveryFeeLimit(
                                      int.tryParse(val) ?? 0);
                                },
                                style: const TextStyle(fontSize: 13),
                                decoration: _inputDecoration(hintText: '0'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: Color(0xFF333333),
      ),
    );
  }

  Widget _buildDropdownContainer({required Widget child}) {
    return Container(
      height: 38,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: child,
    );
  }

  Widget _buildCheckboxOption({
    required String label,
    required bool checked,
    required VoidCallback onChanged,
  }) {
    return InkWell(
      onTap: onChanged,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            value: checked,
            activeColor: const Color(0xFF2196F3),
            onChanged: (_) => onChanged(),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeparatorWithChip(String label) {
    return Row(
      children: [
        const Expanded(
          child: Divider(color: Color(0xFFE0E0E0), thickness: 1),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF2196F3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const Expanded(
          child: Divider(color: Color(0xFFE0E0E0), thickness: 1),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({required String hintText}) {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF7F7F7),
      counterText: '',
      hintText: hintText,
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9E9E9E)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0xFF2196F3), width: 1.2),
      ),
    );
  }
}
