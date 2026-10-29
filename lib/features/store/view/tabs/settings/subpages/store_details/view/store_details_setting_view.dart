import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayfay_merchant_flutter/features/dashboard/model/store_model.dart';
import 'package:bayfay_merchant_flutter/features/store/view/widgets/store_tab_app_bar.dart';
import '../controller/store_details_setting_controller.dart';
import '../model/store_details_setting_model.dart';
import 'widgets/store_details_otp_dialog.dart';
import 'widgets/store_location_pin_icon.dart';

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
          // Nav underline matching Android
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Store Name - STRICTLY NON-EDITABLE MANUALLY (android:focusable="false")
                  _buildFieldLabel('Store Name'),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _nameController,
                    readOnly: true,
                    canRequestFocus: false,
                    enableInteractiveSelection: false,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF333333),
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: _inputDecoration(
                      hintText: 'Enter store/business name',
                      isReadOnly: true,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2. Primary Mobile Number (Editable + Verify)
                  _buildFieldLabel('Primary Mobile Number *'),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F7F7),
                            border: Border.all(color: const Color(0xFFE0E0E0)),
                            borderRadius: BorderRadius.circular(4),
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
                              Container(
                                width: 0.5,
                                height: 24,
                                color: const Color(0xFFE0E0E0),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _primaryMobileController,
                                  keyboardType: TextInputType.phone,
                                  maxLength: 10,
                                  onChanged: controller.onPrimaryMobileChanged,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                  decoration: const InputDecoration(
                                    counterText: '',
                                    hintText: 'Enter mobile number',
                                    hintStyle: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF9E9E9E),
                                    ),
                                    border: InputBorder.none,
                                    contentPadding:
                                        EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Verify button or Verified checkmark matching Android edt_card_single_blue_bg
                      if (state.isPrimaryVerified)
                        Container(
                          width: 80,
                          height: 38,
                          alignment: Alignment.center,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Color(0xFF4CAF50),
                                size: 18,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Verified',
                                style: TextStyle(
                                  color: Color(0xFF4CAF50),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        SizedBox(
                          width: 80,
                          height: 38,
                          child: OutlinedButton(
                            onPressed: isBusy
                                ? null
                                : () => _handleVerifyPrimary(controller),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: Color(0xFF2196F3),
                                width: 1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
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
                  const SizedBox(height: 12),

                  // 3. Secondary Number (Optional)
                  _buildFieldLabel('Secondary Number (Optional)'),
                  const SizedBox(height: 4),
                  Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F7F7),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                      borderRadius: BorderRadius.circular(4),
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
                  const SizedBox(height: 6),

                  // Secondary input based on type
                  if (state.secondaryType == SecondaryNumberType.mobile)
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F7F7),
                              border: Border.all(color: const Color(0xFFE0E0E0)),
                              borderRadius: BorderRadius.circular(4),
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
                                Container(
                                  width: 0.5,
                                  height: 24,
                                  color: const Color(0xFFE0E0E0),
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: _secMobileController,
                                    keyboardType: TextInputType.phone,
                                    maxLength: 10,
                                    onChanged: controller.onSecondaryMobileChanged,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black87,
                                    ),
                                    decoration: const InputDecoration(
                                      counterText: '',
                                      hintText: 'Enter secondary number',
                                      hintStyle: TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF9E9E9E),
                                      ),
                                      border: InputBorder.none,
                                      contentPadding:
                                          EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                            height: 38,
                            alignment: Alignment.center,
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF4CAF50),
                                  size: 18,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Verified',
                                  style: TextStyle(
                                    color: Color(0xFF4CAF50),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          SizedBox(
                            width: 80,
                            height: 38,
                            child: OutlinedButton(
                              onPressed: isBusy
                                  ? null
                                  : () => _handleVerifySecondary(controller),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color(0xFF2196F3),
                                  width: 1,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
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
                          height: 38,
                          child: TextField(
                            controller: _secStdController,
                            keyboardType: TextInputType.number,
                            maxLength: 5,
                            onChanged: controller.onSecondaryLandlineStdChanged,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                            decoration: _inputDecoration(
                              hintText: 'STD Code',
                              isReadOnly: false,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SizedBox(
                            height: 38,
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
                                isReadOnly: false,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),

                  // 4. Store Address - STRICTLY NON-EDITABLE MANUALLY (android:focusable="false")
                  // Auto fetch only triggered when user taps the location pin button!
                  _buildFieldLabel('Store Address *'),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _addressController,
                          maxLines: 4,
                          readOnly: true,
                          canRequestFocus: false,
                          enableInteractiveSelection: false,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF333333),
                            fontWeight: FontWeight.w400,
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF7F7F7),
                            hintText: 'Select store location',
                            hintStyle: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF9E9E9E),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: const BorderSide(
                                color: Color(0xFFE0E0E0),
                                width: 0.5,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: const BorderSide(
                                color: Color(0xFFE0E0E0),
                                width: 0.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: const BorderSide(
                                color: Color(0xFFE0E0E0),
                                width: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Location Pin icon matching Android ic_location_current_m (static icon)
                      Image.asset(
                        'assets/images/location_pin.png',
                        width: 28,
                        height: 28,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 5. Country (Disabled/Read-only in Android)
                  _buildFieldLabel('Country *'),
                  const SizedBox(height: 4),
                  _buildDisabledSpinner(state.country ?? 'India'),
                  const SizedBox(height: 12),

                  // 6. State (Disabled/Read-only in Android)
                  _buildFieldLabel('State *'),
                  const SizedBox(height: 4),
                  _buildDisabledSpinner(state.state ?? 'Select State'),
                  const SizedBox(height: 12),

                  // 7. City (Disabled/Read-only in Android)
                  _buildFieldLabel('City *'),
                  const SizedBox(height: 4),
                  _buildDisabledSpinner(state.city ?? 'Select City'),
                  const SizedBox(height: 12),

                  // 8. Pincode - STRICTLY NON-EDITABLE MANUALLY (android:focusable="false")
                  _buildFieldLabel('Pincode *'),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 38,
                    child: TextField(
                      controller: _pincodeController,
                      readOnly: true,
                      canRequestFocus: false,
                      enableInteractiveSelection: false,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF333333),
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: _inputDecoration(
                        hintText: 'Pincode',
                        isReadOnly: true,
                      ),
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
        fontWeight: FontWeight.w500,
        color: Color(0xFF333333),
      ),
    );
  }

  Widget _buildDisabledSpinner(String text) {
    return Container(
      height: 38,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF333333),
                fontWeight: FontWeight.w400,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(
            Icons.arrow_drop_down,
            color: Color(0xFF9E9E9E),
            size: 20,
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required bool isReadOnly,
  }) {
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
        borderSide: BorderSide(
          color: isReadOnly ? const Color(0xFFE0E0E0) : const Color(0xFF2196F3),
          width: isReadOnly ? 0.5 : 1.2,
        ),
      ),
    );
  }
}
