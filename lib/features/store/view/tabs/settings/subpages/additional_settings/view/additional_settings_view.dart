import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
      final parts = clean.split(' ');
      final timePart = parts.isNotEmpty ? parts.last : clean;
      final timeTokens = timePart.split(':');
      if (timeTokens.isNotEmpty) {
        final hour = int.parse(timeTokens[0]);
        final minute =
            timeTokens.length > 1 ? int.parse(timeTokens[1].split('.')[0]) : 0;
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

  Future<void> _handleAgencyDialog(
    AdditionalSettingsController controller,
    bool currentValue,
  ) async {
    if (!currentValue) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: const Text('Info',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: const Text(
            'By accepting this, the agency will provide you the packaging materials and control the packaging charges!',
            style: TextStyle(fontSize: 13, color: Color(0xFF333333)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Accept', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (ok == true) {
        controller.setAgencyResponsibility(true);
      }
    } else {
      controller.setAgencyResponsibility(false);
    }
  }

  Future<void> _handleRemoveSlot(
    AdditionalSettingsController controller,
    int index,
    int totalSlots,
  ) async {
    if (totalSlots <= 1) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: const Text('Info',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: const Text(
            'At least one shop time required when select Automatic Shop open /close',
            style: TextStyle(fontSize: 13, color: Color(0xFF333333)),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Okay', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: const Text('BayFay',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Text(
          'Do you want to remove the selected shop open & close timing?',
          style: TextStyle(fontSize: 13, color: Color(0xFF333333)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Yes', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      controller.removeTimeSlot(index);
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
        ),
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SECTION 1: PACKAGING (Group Box with Overlapping Badge matching merchant_border_replacement)
                  _buildSectionCard(
                    title: 'Packaging',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Pricing Type Row
                        Row(
                          children: [
                            const SizedBox(
                              width: 110,
                              child: Text(
                                'Pricing Type :',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF616161),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 36,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: isLocked
                                      ? const Color(0xFFF0F0F0)
                                      : const Color(0xFFF7F7F7),
                                  border: Border.all(
                                      color: const Color(0xFFE0E0E0),
                                      width: 0.5),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    value: state.pricingType,
                                    isExpanded: true,
                                    items: const [
                                      DropdownMenuItem(
                                        value: 1,
                                        child: Text('Price (INR )',
                                            style: TextStyle(fontSize: 12)),
                                      ),
                                      DropdownMenuItem(
                                        value: 2,
                                        child: Text('% (Percentage)',
                                            style: TextStyle(fontSize: 12)),
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
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Packaging Price & Min Limit Row
                        Row(
                          children: [
                            const SizedBox(
                              width: 110,
                              child: Text(
                                'Packaging Price :',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF616161),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: SizedBox(
                                      height: 36,
                                      child: TextField(
                                        controller: _priceController,
                                        enabled: !isLocked,
                                        textAlign: TextAlign.center,
                                        keyboardType: const TextInputType
                                            .numberWithOptions(decimal: true),
                                        onChanged: (val) {
                                          controller.setPackagePrice(
                                              double.tryParse(val) ?? 0.0);
                                        },
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black87,
                                        ),
                                        decoration: _inputDecoration(
                                          hintText: '0.00',
                                          isLocked: isLocked,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 5,
                                    child: SizedBox(
                                      height: 36,
                                      child: TextField(
                                        controller: _minLimitController,
                                        enabled: !isLocked,
                                        textAlign: TextAlign.center,
                                        keyboardType: TextInputType.number,
                                        onChanged: (val) {
                                          controller
                                              .setMinLimit(int.tryParse(val));
                                        },
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black87,
                                        ),
                                        decoration: _inputDecoration(
                                          hintText: 'Min. Limit',
                                          isLocked: isLocked,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Tooltip(
                                    message:
                                        'Applicable only when purchase amount is more than the limit',
                                    child: const Icon(
                                      Icons.help_outline,
                                      size: 18,
                                      color: Color(0xFF2196F3),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Agency Responsibility Checkbox Row matching Android agency_responsible_lay
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Checkbox(
                              value: state.agencyResponsibility,
                              activeColor: const Color(0xFF2196F3),
                              onChanged: (_) =>
                                  _handleAgencyDialog(controller, isLocked),
                            ),
                            InkWell(
                              onTap: () =>
                                  _handleAgencyDialog(controller, isLocked),
                              child: const Text(
                                'Agency',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF333333),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Icon(
                              isLocked ? Icons.lock : Icons.lock_open,
                              size: 18,
                              color: isLocked
                                  ? const Color(0xFF2196F3)
                                  : const Color(0xFF9E9E9E),
                            ),
                            const SizedBox(width: 10),
                            Tooltip(
                              message:
                                  'The agency will provide you the packaging materials and control the packaging charges!',
                              child: const Icon(
                                Icons.help_outline,
                                size: 18,
                                color: Color(0xFF2196F3),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // SECTION 2: SHOP TIMING
                  if (state.allowAutoOpenClose)
                    _buildSectionCard(
                      title: 'Shop Timing',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Automatic Shop Open & Close:',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF616161),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Switch(
                                value: state.isAutomaticShopTiming,
                                activeColor: const Color(0xFF2196F3),
                                onChanged: controller.setAutomaticShopTiming,
                              ),
                            ],
                          ),

                          if (state.isAutomaticShopTiming) ...[
                            const SizedBox(height: 10),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: state.timingSlots.length,
                              itemBuilder: (ctx, i) {
                                final slot = state.timingSlots[i];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 6),
                                  child: Row(
                                    children: [
                                      // Opening:
                                      const Text(
                                        'Opening:',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF333333),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: InkWell(
                                          onTap: () => _pickTime(
                                            context: context,
                                            currentTime: slot.startTime,
                                            onSelected: (time) => controller
                                                .updateTimeSlot(i,
                                                    startTime: time),
                                          ),
                                          child: Container(
                                            height: 34,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              border: Border.all(
                                                color: const Color(0xFFBDBDBD),
                                                width: 0.6,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              _formatTo12Hour(slot.startTime),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFFE91E63),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),

                                      // Closing:
                                      const Text(
                                        'Closing:',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF333333),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: InkWell(
                                          onTap: () => _pickTime(
                                            context: context,
                                            currentTime: slot.endTime,
                                            onSelected: (time) => controller
                                                .updateTimeSlot(i,
                                                    endTime: time),
                                          ),
                                          child: Container(
                                            height: 34,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              border: Border.all(
                                                color: const Color(0xFFBDBDBD),
                                                width: 0.6,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              _formatTo12Hour(slot.endTime),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF03A9F4),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),

                                      // Trash Clear Button matching ic_delete_icon
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Color(0xFFE53935),
                                          size: 20,
                                        ),
                                        onPressed: () => _handleRemoveSlot(
                                          controller,
                                          i,
                                          state.timingSlots.length,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 8),

                            // Add Another Time Slot Button matching Android add_time_bg
                            OutlinedButton(
                              onPressed: () {
                                final added = controller.addTimeSlot();
                                if (!added) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Enter Shop Open and Close time before adding another slot',
                                      ),
                                    ),
                                  );
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                    color: Color(0xFF2196F3), width: 1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                              ),
                              child: const Text(
                                'Add Another Time Slot',
                                style: TextStyle(
                                  color: Color(0xFF2196F3),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Widget child,
  }) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.fromLTRB(12, 18, 12, 12),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF4CAF50), width: 1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: child,
        ),
        Positioned(
          left: 20,
          top: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            color: Colors.white,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6F6F6F),
              ),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required bool isLocked,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: isLocked ? const Color(0xFFF0F0F0) : const Color(0xFFF7F7F7),
      counterText: '',
      hintText: hintText,
      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
      ),
      disabledBorder: OutlineInputBorder(
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
