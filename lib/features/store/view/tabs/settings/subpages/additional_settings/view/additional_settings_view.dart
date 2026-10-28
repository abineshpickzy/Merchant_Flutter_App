import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayfay_merchant_flutter/features/dashboard/model/store_model.dart';
import 'package:bayfay_merchant_flutter/features/store/view/widgets/store_tab_app_bar.dart';
import '../controller/additional_settings_controller.dart';
import '../model/additional_settings_model.dart';

class AdditionalSettingsView extends ConsumerStatefulWidget {
  final StoreModel store;

  const AdditionalSettingsView({super.key, required this.store});

  @override
  ConsumerState<AdditionalSettingsView> createState() =>
      _AdditionalSettingsViewState();
}

class _AdditionalSettingsViewState
    extends ConsumerState<AdditionalSettingsView> {
  late TextEditingController _priceController;
  late TextEditingController _minLimitController;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController();
    _minLimitController = TextEditingController();
  }

  @override
  void dispose() {
    _priceController.dispose();
    _minLimitController.dispose();
    super.dispose();
  }

  void _syncControllers(AdditionalSettingsState state) {
    if (_priceController.text.isEmpty && state.packagePrice > 0) {
      _priceController.text = state.packagePrice % 1 == 0
          ? state.packagePrice.toInt().toString()
          : state.packagePrice.toString();
    }
    if (_minLimitController.text.isEmpty &&
        state.minLimit != null &&
        state.minLimit! > 0) {
      _minLimitController.text = state.minLimit.toString();
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

  Future<void> _handleAgencyDialog(
    AdditionalSettingsController controller,
    bool currentValue,
  ) async {
    if (!currentValue) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Info', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text(
            'By accepting this, the agency will provide you the packaging materials and control the packaging charges!',
            style: TextStyle(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Accept', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (ok == true) {
        controller.setAgencyResponsibility(true);
      }
    } else {
      controller.setAgencyResponsibility(false);
    }
  }

  Future<void> _handleSave(AdditionalSettingsController controller) async {
    final res = await controller.saveSettings();
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
        ref.watch(additionalSettingsControllerProvider(widget.store));
    final controller = ref.read(
        additionalSettingsControllerProvider(widget.store).notifier);

    _syncControllers(state);

    final isBusy = state.isLoading || state.isSaving;
    final isLocked = state.agencyResponsibility;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: StoreTabAppBar(
        title: 'Additional Settings',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF616161)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        trailing: Padding(
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
        ),
      ),
      body: Column(
        children: [
          if (isBusy)
            const LinearProgressIndicator(
              minHeight: 2.5,
              backgroundColor: Color(0xFFE3F2FD),
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF297BFE)),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Packaging Pricing Type
                  _buildFieldLabel('Packaging Price Type: *'),
                  const SizedBox(height: 4),
                  Container(
                    height: 40,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isLocked ? Colors.grey.shade100 : Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: state.pricingType,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(
                            value: 1,
                            child: Text('Price (INR )',
                                style: TextStyle(fontSize: 13)),
                          ),
                          DropdownMenuItem(
                            value: 2,
                            child: Text('% (Percentage)',
                                style: TextStyle(fontSize: 13)),
                          ),
                        ],
                        onChanged: isLocked
                            ? null
                            : (val) {
                                if (val != null) {
                                  controller.setPricingType(val);
                                }
                              },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 2. Package Price
                  _buildFieldLabel('Package Price: *'),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 40,
                    child: TextField(
                      controller: _priceController,
                      enabled: !isLocked,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      onChanged: (val) {
                        controller.setPackagePrice(
                            double.tryParse(val) ?? 0.0);
                      },
                      style:
                          const TextStyle(fontSize: 13, color: Colors.black87),
                      decoration: _inputDecoration(
                        hintText: 'Enter package price',
                        isLocked: isLocked,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 3. Minimum Purchase Limit
                  Row(
                    children: [
                      _buildFieldLabel('Minimum Purchase Limit (Optional):'),
                      const SizedBox(width: 6),
                      Tooltip(
                        message:
                            'Applicable only when purchase amount is more than the limit',
                        child: Icon(
                          Icons.help_outline,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 40,
                    child: TextField(
                      controller: _minLimitController,
                      enabled: !isLocked,
                      keyboardType: TextInputType.number,
                      onChanged: (val) {
                        controller.setMinLimit(int.tryParse(val));
                      },
                      style:
                          const TextStyle(fontSize: 13, color: Colors.black87),
                      decoration: _inputDecoration(
                        hintText: 'Enter minimum purchase limit',
                        isLocked: isLocked,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 4. Agency Responsibility Checkbox
                  InkWell(
                    onTap: () =>
                        _handleAgencyDialog(controller, isLocked),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: state.agencyResponsibility,
                            activeColor: const Color(0xFF2196F3),
                            onChanged: (_) =>
                                _handleAgencyDialog(controller, isLocked),
                          ),
                          Expanded(
                            child: Text(
                              'Agency Responsibility for Packaging',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                          Icon(
                            isLocked ? Icons.lock : Icons.lock_open,
                            size: 18,
                            color: isLocked
                                ? const Color(0xFF2196F3)
                                : Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 5. Automatic Shop Open / Close
                  if (state.allowAutoOpenClose) ...[
                    const Divider(color: Color(0xFFE0E0E0), thickness: 1),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Automatic Shop Open / Close:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                        Switch(
                          value: state.isAutomaticShopTiming,
                          activeColor: const Color(0xFF2196F3),
                          onChanged: controller.setAutomaticShopTiming,
                        ),
                      ],
                    ),

                    if (state.isAutomaticShopTiming) ...[
                      const SizedBox(height: 10),
                      const Text(
                        'Shop Timings:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // List of time slots
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: state.timingSlots.length,
                        itemBuilder: (ctx, i) {
                          final slot = state.timingSlots[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Text('From: ',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2196F3))),
                                InkWell(
                                  onTap: () => _pickTime(
                                    context: context,
                                    currentTime: slot.startTime,
                                    onSelected: (time) => controller
                                        .updateTimeSlot(i, startTime: time),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      slot.startTime.isNotEmpty
                                          ? slot.startTime
                                          : '00:00',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text('To: ',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2196F3))),
                                InkWell(
                                  onTap: () => _pickTime(
                                    context: context,
                                    currentTime: slot.endTime,
                                    onSelected: (time) => controller
                                        .updateTimeSlot(i, endTime: time),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      slot.endTime.isNotEmpty
                                          ? slot.endTime
                                          : '00:00',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                if (state.timingSlots.length > 1)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        size: 18, color: Colors.red),
                                    onPressed: () =>
                                        controller.removeTimeSlot(i),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () {
                            final ok = controller.addTimeSlot();
                            if (!ok) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Enter Shop Open and Close time before adding another'),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text(
                            'Add another time slot',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
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

  InputDecoration _inputDecoration({
    required String hintText,
    bool isLocked = false,
  }) {
    return InputDecoration(
      filled: isLocked,
      fillColor: isLocked ? Colors.grey.shade100 : null,
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
