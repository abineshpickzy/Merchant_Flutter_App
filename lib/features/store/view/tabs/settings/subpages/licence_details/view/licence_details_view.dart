import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayfay_merchant_flutter/features/dashboard/model/store_model.dart';
import 'package:bayfay_merchant_flutter/features/store/view/widgets/store_tab_app_bar.dart';
import '../controller/licence_details_controller.dart';
import '../model/licence_details_model.dart';

class LicenceDetailsView extends ConsumerStatefulWidget {
  final StoreModel store;

  const LicenceDetailsView({super.key, required this.store});

  @override
  ConsumerState<LicenceDetailsView> createState() => _LicenceDetailsViewState();
}

class _LicenceDetailsViewState extends ConsumerState<LicenceDetailsView> {
  late TextEditingController _gstinController;
  late TextEditingController _panController;
  late TextEditingController _fssaiController;

  @override
  void initState() {
    super.initState();
    _gstinController = TextEditingController();
    _panController = TextEditingController();
    _fssaiController = TextEditingController();
  }

  @override
  void dispose() {
    _gstinController.dispose();
    _panController.dispose();
    _fssaiController.dispose();
    super.dispose();
  }

  void _syncControllers(LicenceDetailsState state) {
    if (_gstinController.text.isEmpty && state.gstin.isNotEmpty) {
      _gstinController.text = state.gstin;
    }
    if (_panController.text.isEmpty && state.pan.isNotEmpty) {
      _panController.text = state.pan;
    }
    if (_fssaiController.text.isEmpty && state.fssai.isNotEmpty) {
      _fssaiController.text = state.fssai;
    }
  }

  Future<void> _handleSave(LicenceDetailsController controller) async {
    final res = await controller.saveLicence();
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
    final state = ref.watch(licenceDetailsControllerProvider(widget.store));
    final controller =
        ref.read(licenceDetailsControllerProvider(widget.store).notifier);

    _syncControllers(state);

    final isBusy = state.isLoading || state.isSaving;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: StoreTabAppBar(
        title: 'Licence Details',
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
                  // GSTIN
                  _buildFieldLabel('GSTIN:'),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 40,
                    child: TextField(
                      controller: _gstinController,
                      maxLength: 15,
                      textCapitalization: TextCapitalization.characters,
                      onChanged: controller.setGstin,
                      style:
                          const TextStyle(fontSize: 13, color: Colors.black87),
                      decoration: _inputDecoration(hintText: 'Enter GSTIN'),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // PAN
                  _buildFieldLabel('PAN:'),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 40,
                    child: TextField(
                      controller: _panController,
                      maxLength: 10,
                      textCapitalization: TextCapitalization.characters,
                      onChanged: controller.setPan,
                      style:
                          const TextStyle(fontSize: 13, color: Colors.black87),
                      decoration: _inputDecoration(hintText: 'Enter PAN'),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // FSSAI
                  _buildFieldLabel('FSSAI:'),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 40,
                    child: TextField(
                      controller: _fssaiController,
                      maxLength: 14,
                      keyboardType: TextInputType.number,
                      onChanged: controller.setFssai,
                      style:
                          const TextStyle(fontSize: 13, color: Colors.black87),
                      decoration: _inputDecoration(hintText: 'Enter FSSAI number'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Auto send GST invoice
                  InkWell(
                    onTap: () => controller
                        .setAutoInvoice(!state.isAutoInvoice),
                    child: Row(
                      children: [
                        Checkbox(
                          value: state.isAutoInvoice,
                          activeColor: const Color(0xFF2196F3),
                          onChanged: (val) =>
                              controller.setAutoInvoice(val ?? false),
                        ),
                        const Expanded(
                          child: Text(
                            'Auto send GST invoice to customer',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF333333),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
