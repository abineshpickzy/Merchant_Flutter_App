import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayfay_merchant_flutter/features/dashboard/model/store_model.dart';
import 'package:bayfay_merchant_flutter/features/store/view/widgets/store_tab_app_bar.dart';
import '../controller/store_details_setting_controller.dart';
import '../model/store_details_setting_model.dart';
import 'widgets/store_details_otp_dialog.dart';

class StoreDetailsSettingView extends ConsumerStatefulWidget {
  final StoreModel store;

  const StoreDetailsSettingView({super.key, required this.store});

  @override
  ConsumerState<StoreDetailsSettingView> createState() =>
      _StoreDetailsSettingViewState();
}

class _StoreDetailsSettingViewState
    extends ConsumerState<StoreDetailsSettingView> {
  late TextEditingController _nameController;
  late TextEditingController _primaryMobileController;
  late TextEditingController _secMobileController;
  late TextEditingController _secStdController;
  late TextEditingController _secLandlineController;
  late TextEditingController _addressController;
  late TextEditingController _pincodeController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.store.displayName);
    _primaryMobileController = TextEditingController();
    _secMobileController = TextEditingController();
    _secStdController = TextEditingController();
    _secLandlineController = TextEditingController();
    _addressController = TextEditingController();
    _pincodeController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _primaryMobileController.dispose();
    _secMobileController.dispose();
    _secStdController.dispose();
    _secLandlineController.dispose();
    _addressController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  void _syncControllers(StoreDetailsSettingState state) {
    if (_nameController.text != state.displayName &&
        state.displayName.isNotEmpty) {
      _nameController.text = state.displayName;
    }
    if (_primaryMobileController.text != state.primaryMobile &&
        _primaryMobileController.text.isEmpty &&
        state.primaryMobile.isNotEmpty) {
      _primaryMobileController.text = state.primaryMobile;
    }
    if (_secMobileController.text != state.secondaryMobile &&
        _secMobileController.text.isEmpty &&
        state.secondaryMobile.isNotEmpty) {
      _secMobileController.text = state.secondaryMobile;
    }
    if (_secStdController.text != state.secondaryLandlineStd &&
        _secStdController.text.isEmpty &&
        state.secondaryLandlineStd.isNotEmpty) {
      _secStdController.text = state.secondaryLandlineStd;
    }
    if (_secLandlineController.text != state.secondaryLandlineNum &&
        _secLandlineController.text.isEmpty &&
        state.secondaryLandlineNum.isNotEmpty) {
      _secLandlineController.text = state.secondaryLandlineNum;
    }
    if (_addressController.text != state.streetAddress &&
        _addressController.text.isEmpty &&
        state.streetAddress.isNotEmpty) {
      _addressController.text = state.streetAddress;
    }
    if (_pincodeController.text != state.pincode &&
        _pincodeController.text.isEmpty &&
        state.pincode.isNotEmpty) {
      _pincodeController.text = state.pincode;
    }
  }

  Future<void> _handleVerifyPrimary(
    StoreDetailsSettingController controller,
  ) async {
    final res = await controller.sendOtpPrimary();
    if (!mounted) return;

    if (!res.openDialog) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message)),
      );
      return;
    }

    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StoreDetailsOtpDialog(
        subtitle:
            'Please enter the OTP sent to primary mobile (+91 ${_primaryMobileController.text})',
        onVerify: (otp) => controller.verifyOtp(otp: otp, isPrimary: true),
        onResend: () => controller.sendOtpPrimary(),
      ),
    );
  }

  Future<void> _handleVerifySecondary(
    StoreDetailsSettingController controller,
  ) async {
    final res = await controller.sendOtpSecondary();
    if (!mounted) return;

    if (!res.openDialog) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message)),
      );
      return;
    }

    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StoreDetailsOtpDialog(
        subtitle:
            'Please enter the OTP sent to secondary mobile (+91 ${_secMobileController.text})',
        onVerify: (otp) => controller.verifyOtp(otp: otp, isPrimary: false),
        onResend: () => controller.sendOtpSecondary(),
      ),
    );
  }

  Future<void> _handleSave(
    StoreDetailsSettingController controller,
  ) async {
    final res = await controller.saveDetails();
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
    final state = ref.watch(storeDetailsSettingControllerProvider(widget.store));
    final controller =
        ref.read(storeDetailsSettingControllerProvider(widget.store).notifier);

    _syncControllers(state);

    final isBusy =
        state.isLoading || state.isSaving || state.isSendingOtp || state.isVerifyingOtp;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: StoreTabAppBar(
        title: state.displayName.isNotEmpty
            ? state.displayName
            : 'Store Details',
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
          // Divider
          const Divider(height: 1, thickness: 1, color: Color(0xFFE3E3E3)),

          // Horizontal Progress Bar matching Android MaterialProgressBar
          if (isBusy)
            const LinearProgressIndicator(
              minHeight: 2.5,
              backgroundColor: Color(0xFFE3F2FD),
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF297BFE)),
            ),

          // Scrollable Form matching settings_store_details.xml
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Store Name
                  _buildFieldLabel('Store Name'),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _nameController,
                    onChanged: controller.onStoreNameChanged,
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                    decoration: _inputDecoration(
                      hintText: 'Enter store/business name',
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 2. Primary Mobile Number
                  _buildFieldLabel('Primary Mobile Number *'),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: const Text(
                                  '+91',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              VerticalDivider(
                                width: 1,
                                thickness: 1,
                                color: Colors.grey.shade300,
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _primaryMobileController,
                                  keyboardType: TextInputType.phone,
                                  maxLength: 10,
                                  onChanged: (val) {
                                    controller.onPrimaryMobileChanged(val);
                                  },
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                  decoration: const InputDecoration(
                                    counterText: '',
                                    hintText: 'Enter mobile number',
                                    hintStyle: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding:
                                        EdgeInsets.symmetric(horizontal: 10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Verify button or Verified checkmark
                      if (state.isPrimaryVerified)
                        Container(
                          width: 80,
                          height: 40,
                          alignment: Alignment.center,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Color(0xFF4CAF50),
                                size: 20,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Verified',
                                style: TextStyle(
                                  color: Color(0xFF4CAF50),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        SizedBox(
                          width: 80,
                          height: 40,
                          child: OutlinedButton(
                            onPressed: isBusy
                                ? null
                                : () => _handleVerifyPrimary(controller),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF2196F3)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text(
                              'Verify',
                              style: TextStyle(
                                color: Color(0xFF2196F3),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 3. Secondary Number (Optional)
                  _buildFieldLabel('Secondary Number (Optional)'),
                  const SizedBox(height: 4),
                  Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<SecondaryNumberType>(
                        value: state.secondaryType,
                        isExpanded: true,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: SecondaryNumberType.mobile,
                            child: Text('Mobile Number'),
                          ),
                          DropdownMenuItem(
                            value: SecondaryNumberType.landline,
                            child: Text('Landline Number'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            controller.onSecondaryTypeChanged(val);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Secondary input based on type
                  if (state.secondaryType == SecondaryNumberType.mobile)
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 10),
                                  child: const Text(
                                    '+91',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                VerticalDivider(
                                  width: 1,
                                  thickness: 1,
                                  color: Colors.grey.shade300,
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: _secMobileController,
                                    keyboardType: TextInputType.phone,
                                    maxLength: 10,
                                    onChanged: (val) {
                                      controller.onSecondaryMobileChanged(val);
                                    },
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black87,
                                    ),
                                    decoration: const InputDecoration(
                                      counterText: '',
                                      hintText: 'Enter secondary number',
                                      hintStyle: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding:
                                          EdgeInsets.symmetric(horizontal: 10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (state.isSecondaryVerified)
                          Container(
                            width: 80,
                            height: 40,
                            alignment: Alignment.center,
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF4CAF50),
                                  size: 20,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Verified',
                                  style: TextStyle(
                                    color: Color(0xFF4CAF50),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          SizedBox(
                            width: 80,
                            height: 40,
                            child: OutlinedButton(
                              onPressed: isBusy
                                  ? null
                                  : () => _handleVerifySecondary(controller),
                              style: OutlinedButton.styleFrom(
                                side:
                                    const BorderSide(color: Color(0xFF2196F3)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                padding: EdgeInsets.zero,
                              ),
                              child: const Text(
                                'Verify',
                                style: TextStyle(
                                  color: Color(0xFF2196F3),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        SizedBox(
                          width: 80,
                          height: 40,
                          child: TextField(
                            controller: _secStdController,
                            keyboardType: TextInputType.number,
                            maxLength: 5,
                            onChanged: controller.onSecondaryLandlineStdChanged,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                            decoration: _inputDecoration(hintText: 'STD Code'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SizedBox(
                            height: 40,
                            child: TextField(
                              controller: _secLandlineController,
                              keyboardType: TextInputType.phone,
                              maxLength: 10,
                              onChanged:
                                  controller.onSecondaryLandlineNumChanged,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                              decoration: _inputDecoration(
                                hintText: 'Enter landline number',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 14),

                  // 4. Store Address
                  _buildFieldLabel('Store Address *'),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _addressController,
                          maxLines: 3,
                          onChanged: controller.onStreetAddressChanged,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Select store location or enter address',
                            hintStyle: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                            contentPadding: const EdgeInsets.all(10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(
                                color: Color(0xFF2196F3),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.my_location,
                            color: Color(0xFF2196F3),
                            size: 22,
                          ),
                          tooltip: 'Current Location',
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Location fetched successfully'),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 5. Country (Disabled)
                  _buildFieldLabel('Country *'),
                  const SizedBox(height: 4),
                  Container(
                    height: 40,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      state.country ?? 'India',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 6. State (Disabled)
                  _buildFieldLabel('State *'),
                  const SizedBox(height: 4),
                  Container(
                    height: 40,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      state.state ?? 'Select State',
                      style: TextStyle(
                        fontSize: 13,
                        color: state.state != null
                            ? Colors.black87
                            : Colors.grey.shade500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 7. City (Disabled)
                  _buildFieldLabel('City *'),
                  const SizedBox(height: 4),
                  Container(
                    height: 40,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      state.city ?? 'Select City',
                      style: TextStyle(
                        fontSize: 13,
                        color: state.city != null
                            ? Colors.black87
                            : Colors.grey.shade500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 8. Pincode
                  _buildFieldLabel('Pincode *'),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 40,
                    child: TextField(
                      controller: _pincodeController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      onChanged: controller.onPincodeChanged,
                      style:
                          const TextStyle(fontSize: 13, color: Colors.black87),
                      decoration: _inputDecoration(hintText: 'Pincode'),
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
