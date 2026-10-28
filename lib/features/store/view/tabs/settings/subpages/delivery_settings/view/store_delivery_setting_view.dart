import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  static const List<DeliverySettingOption> _daysOptions = [
    DeliverySettingOption(days: 7, label: '7 Days'),
    DeliverySettingOption(days: 14, label: '14 Days'),
    DeliverySettingOption(days: 21, label: '21 Days'),
    DeliverySettingOption(days: 30, label: '1 Month'),
    DeliverySettingOption(days: 90, label: '3 Month'),
    DeliverySettingOption(days: 180, label: '6 Month'),
    DeliverySettingOption(days: 365, label: '1 Year'),
  ];

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

  Future<void> _pickTime({
    required BuildContext context,
    required String currentTime,
    required ValueChanged<String> onSelected,
  }) async {
    final parts = currentTime.split(':');
    final initialHour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 9 : 9;
    final initialMinute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
    );

    if (picked != null) {
      final hourStr = picked.hour.toString().padLeft(2, '0');
      final minuteStr = picked.minute.toString().padLeft(2, '0');
      onSelected('$hourStr:$minuteStr');
    }
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
                        borderRadius: BorderRadius.circular(6),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Product Replacement Within
                  _buildFieldLabel(
                      'Product replacement within: * (In case any escalation)'),
                  const SizedBox(height: 4),
                  _buildDropdownContainer(
                    child: DropdownButton<int>(
                      value: _daysOptions
                              .any((o) => o.days == state.replacementDays)
                          ? state.replacementDays
                          : _daysOptions.first.days,
                      isExpanded: true,
                      underline: const SizedBox.shrink(),
                      items: _daysOptions
                          .map((opt) => DropdownMenuItem(
                                value: opt.days,
                                child: Text(opt.label,
                                    style: const TextStyle(fontSize: 13)),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) controller.setReplacementDays(val);
                      },
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 2. Refund Within
                  _buildFieldLabel('Refund within: * (In case any escalation)'),
                  const SizedBox(height: 4),
                  _buildDropdownContainer(
                    child: DropdownButton<int>(
                      value: _daysOptions.any((o) => o.days == state.refundDays)
                          ? state.refundDays
                          : _daysOptions.first.days,
                      isExpanded: true,
                      underline: const SizedBox.shrink(),
                      items: _daysOptions
                          .map((opt) => DropdownMenuItem(
                                value: opt.days,
                                child: Text(opt.label,
                                    style: const TextStyle(fontSize: 13)),
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
                              style: const TextStyle(fontSize: 13)),
                        ),
                      ),
                      onChanged: (val) {
                        if (val != null) controller.setCurrentRadius(val);
                      },
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 5. Delivery Time
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
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Text(state.fromTime,
                                  style: const TextStyle(fontSize: 13)),
                              const SizedBox(width: 6),
                              const Icon(Icons.access_time,
                                  size: 16, color: Colors.grey),
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
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Text(state.toTime,
                                  style: const TextStyle(fontSize: 13)),
                              const SizedBox(width: 6),
                              const Icon(Icons.access_time,
                                  size: 16, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

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
                        label: 'Self pickup',
                        checked: state.localDeliveryTypes.contains(3),
                        onChanged: () => controller.toggleLocalDeliveryType(3),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 7. Delivery charges up to 2km
                  _buildFieldLabel('Delivery charges up to 2km:'),
                  const Text(
                    'Applicable for lessthan minimum purchase limit',
                    style: TextStyle(fontSize: 11, color: Colors.red),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 40,
                    child: TextField(
                      controller: _deliveryFeeController,
                      keyboardType: TextInputType.number,
                      onChanged: (val) {
                        controller.setDeliveryFee(int.tryParse(val) ?? 0);
                      },
                      style:
                          const TextStyle(fontSize: 13, color: Colors.black87),
                      decoration: _inputDecoration(hintText: 'Amount'),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 8. Minimum purchase limit
                  _buildFieldLabel('Minimum purchase limit:'),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 40,
                    child: TextField(
                      controller: _minPurchaseLimitController,
                      keyboardType: TextInputType.number,
                      onChanged: (val) {
                        controller
                            .setDeliveryFeeLimit(int.tryParse(val) ?? 0);
                      },
                      style:
                          const TextStyle(fontSize: 13, color: Colors.black87),
                      decoration:
                          _inputDecoration(hintText: 'Minimum Purchase Amount'),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 9. Delivery charge per km
                  _buildFieldLabel('Delivery charge per km:'),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 40,
                        child: TextField(
                          controller: _perKmFeeController,
                          keyboardType: TextInputType.number,
                          onChanged: (val) {
                            controller.setPerKmFee(int.tryParse(val) ?? 0);
                          },
                          style: const TextStyle(
                              fontSize: 13, color: Colors.black87),
                          decoration: _inputDecoration(hintText: 'Amount'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Applicable for orders beyond 2km',
                          style: TextStyle(fontSize: 11, color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Subscription toggle
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Delivery charge applicable for subscription order?',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF555555),
                          ),
                        ),
                      ),
                      Switch(
                        value: state.deliveryFeeSubscription,
                        activeColor: const Color(0xFF2196F3),
                        onChanged: controller.setDeliveryFeeSubscription,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 10. Cash on delivery
                  _buildFieldLabel('Cash on delivery: *'),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: state.codLimitType == 'limit'
                                ? 'Limit'
                                : 'Any',
                            items: const [
                              DropdownMenuItem(
                                  value: 'Any',
                                  child: Text('Any',
                                      style: TextStyle(fontSize: 13))),
                              DropdownMenuItem(
                                  value: 'Limit',
                                  child: Text('Limit',
                                      style: TextStyle(fontSize: 13))),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                controller
                                    .setCodLimitType(val.toLowerCase());
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: TextField(
                            controller: _codLimitController,
                            keyboardType: TextInputType.number,
                            enabled: state.isCodEnabled &&
                                state.codLimitType == 'limit',
                            onChanged: (val) {
                              controller.setCodLimit(int.tryParse(val) ?? 0);
                            },
                            style: const TextStyle(
                                fontSize: 13, color: Colors.black87),
                            decoration: _inputDecoration(hintText: 'Amount'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: state.isCodEnabled,
                        activeColor: const Color(0xFF2196F3),
                        onChanged: (val) {
                          final ok = controller.setCodEnabled(val);
                          if (!ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Both cash on delivery and online payment cannot be turned off'),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 11. Online Payment
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildFieldLabel('Online Payment: *'),
                      Switch(
                        value: state.isOnlinePaymentEnabled,
                        activeColor: const Color(0xFF2196F3),
                        onChanged: (val) {
                          final ok = controller.setOnlinePaymentEnabled(val);
                          if (!ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Both cash on delivery and online payment cannot be turned off'),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 12. Store Availability
                  _buildFieldLabel('Store Availability: *'),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      _buildDayCheck('Sunday', 'SUN', state, controller),
                      _buildDayCheck('Monday', 'MON', state, controller),
                      _buildDayCheck('Tuesday', 'TUE', state, controller),
                      _buildDayCheck('Wednesday', 'WED', state, controller),
                      _buildDayCheck('Thursday', 'THU', state, controller),
                      _buildDayCheck('Friday', 'FRI', state, controller),
                      _buildDayCheck('Saturday', 'SAT', state, controller),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 13. Separator Line: Ship To Other Locations
                  _buildSeparatorWithChip('Ship To Other Locations'),
                  const SizedBox(height: 14),

                  // Enable Other Locations
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Enable Other locations:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
                        ),
                      ),
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
                    const SizedBox(height: 12),
                    _buildFieldLabel('Select Target Countries: *'),
                    const SizedBox(height: 4),
                    _buildDropdownContainer(
                      child: const Text('India',
                          style: TextStyle(fontSize: 13, color: Colors.black87)),
                    ),
                    const SizedBox(height: 14),

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
                    const SizedBox(height: 14),

                    _buildFieldLabel('Delivery charge:'),
                    const Text(
                      'Applicable for lessthan minimum purchase limit',
                      style: TextStyle(fontSize: 11, color: Colors.red),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 40,
                      child: TextField(
                        controller: _otherFeeController,
                        keyboardType: TextInputType.number,
                        onChanged: (val) {
                          controller
                              .setOtherDeliveryFee(int.tryParse(val) ?? 0);
                        },
                        style: const TextStyle(
                            fontSize: 13, color: Colors.black87),
                        decoration: _inputDecoration(hintText: 'Amount'),
                      ),
                    ),
                    const SizedBox(height: 14),

                    _buildFieldLabel('Minimum purchase limit:'),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 40,
                      child: TextField(
                        controller: _otherLimitController,
                        keyboardType: TextInputType.number,
                        onChanged: (val) {
                          controller.setOtherDeliveryFeeLimit(
                              int.tryParse(val) ?? 0);
                        },
                        style: const TextStyle(
                            fontSize: 13, color: Colors.black87),
                        decoration: _inputDecoration(
                            hintText: 'Minimum Purchase Amount'),
                      ),
                    ),
                  ],

                  const SizedBox(height: 30),
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
        fontWeight: FontWeight.w600,
        color: Color(0xFF333333),
      ),
    );
  }

  Widget _buildDropdownContainer({required Widget child}) {
    return Container(
      height: 40,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
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
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildDayCheck(
    String label,
    String code,
    StoreDeliverySettingState state,
    StoreDeliverySettingController controller,
  ) {
    final checked = state.availability.contains(code);
    return InkWell(
      onTap: () => controller.toggleAvailabilityDay(code),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            value: checked,
            activeColor: const Color(0xFF2196F3),
            onChanged: (_) => controller.toggleAvailabilityDay(code),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSeparatorWithChip(String label) {
    return Stack(
      alignment: Alignment.center,
      children: [
        const Divider(color: Color(0xFF81C784), thickness: 1),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF388E3C),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({required String hintText}) {
    return InputDecoration(
      counterText: '',
      hintText: hintText,
      hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFF2196F3), width: 1.5),
      ),
    );
  }
}
