import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_strings.dart';
import '../controller/add_store_controller.dart';
import '../model/location_model.dart';
import '../model/picked_location_data.dart';
import '../model/store_category_model.dart';
import '../model/store_type_model.dart';
import 'location_flow/select_store_location_screen.dart';
import 'terms_condition_screen.dart';
import 'widgets/availability_days_row.dart';
import 'widgets/step_indicator.dart';
import 'widgets/store_image_picker.dart';
import 'widgets/otp_verify_dialog.dart';
import 'others_acknowledgment_screen.dart';
import '../../dashboard/controller/dashboard_controller.dart';

/// 3-Step Wizard for creating a new store.
/// Supports B2C Retail (storeKind = 0), D2C (storeKind = 4), and Wholesale (storeKind = 1).
/// Replicates the native Android Merchant app store creation flow.
class AddStoreFormScreen extends ConsumerStatefulWidget {
  final int storeKind;
  final StoreFlow? storeFlow;

  const AddStoreFormScreen({
    super.key,
    this.storeKind = 0,
    this.storeFlow,
  });

  @override
  ConsumerState<AddStoreFormScreen> createState() => _AddStoreFormScreenState();
}

class _AddStoreFormScreenState extends ConsumerState<AddStoreFormScreen> {
  late final PageController _pageController;

  // Controllers for text inputs
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _categoryDescCtrl = TextEditingController();
  final TextEditingController _contactTimeCtrl = TextEditingController();
  final TextEditingController _primaryMnoCtrl = TextEditingController();
  final TextEditingController _secCodeCtrl = TextEditingController();
  final TextEditingController _secMnoCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _countryCtrl = TextEditingController();
  final TextEditingController _stateCtrl = TextEditingController();
  final TextEditingController _cityCtrl = TextEditingController();
  final TextEditingController _pincodeCtrl = TextEditingController();

  // Step 2 controllers
  final TextEditingController _deliveryFeeCtrl = TextEditingController();
  final TextEditingController _feeLimitCtrl = TextEditingController();
  final TextEditingController _perKmFeeCtrl = TextEditingController();
  final TextEditingController _codLimitCtrl = TextEditingController();
  final TextEditingController _otherFeeCtrl = TextEditingController();
  final TextEditingController _otherLimitCtrl = TextEditingController();
  late final TapGestureRecognizer _termsRecognizer;
  bool _step2Initialized = false;
  bool _step3Initialized = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _termsRecognizer = TapGestureRecognizer()..onTap = _openTermsAndConditions;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(addStoreControllerProvider.notifier)
          .loadInitialData(
            overrideKind: widget.storeKind,
            overrideFlow: widget.storeFlow,
          );
    });
  }

  @override
  void didUpdateWidget(AddStoreFormScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.storeKind != widget.storeKind ||
        oldWidget.storeFlow != widget.storeFlow) {
      ref
          .read(addStoreControllerProvider.notifier)
          .loadInitialData(
            overrideKind: widget.storeKind,
            overrideFlow: widget.storeFlow,
          );
    }
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _pageController.dispose();
    _nameCtrl.dispose();
    _categoryDescCtrl.dispose();
    _contactTimeCtrl.dispose();
    _primaryMnoCtrl.dispose();
    _secCodeCtrl.dispose();
    _secMnoCtrl.dispose();
    _addressCtrl.dispose();
    _countryCtrl.dispose();
    _stateCtrl.dispose();
    _cityCtrl.dispose();
    _pincodeCtrl.dispose();
    _deliveryFeeCtrl.dispose();
    _feeLimitCtrl.dispose();
    _perKmFeeCtrl.dispose();
    _codLimitCtrl.dispose();
    _otherFeeCtrl.dispose();
    _otherLimitCtrl.dispose();
    super.dispose();
  }

  void _openTermsAndConditions() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const TermsConditionScreen(),
      ),
    );
  }

  void _syncControllersWithState(AddStoreState state) {
    if (_nameCtrl.text != state.storeName && state.storeName.isNotEmpty) {
      _nameCtrl.text = state.storeName;
    }
    if (_secCodeCtrl.text != state.secCodeText && state.secCodeText.isNotEmpty) {
      _secCodeCtrl.text = state.secCodeText;
    }
    final targetAddress = state.street.isNotEmpty
        ? state.street
        : state.formattedAddress;
    final cleanTarget =
        AddStoreController.sanitizePhysicalAddress(targetAddress);
    if (_addressCtrl.text != cleanTarget && cleanTarget.isNotEmpty) {
      _addressCtrl.text = cleanTarget;
    }
    if (_categoryDescCtrl.text != state.categoryDescription) {
      _categoryDescCtrl.text = state.categoryDescription;
    }
    if (_contactTimeCtrl.text != state.contactTime) {
      _contactTimeCtrl.text = state.contactTime;
    }
    if (_countryCtrl.text != state.countryText && state.countryText.isNotEmpty) {
      _countryCtrl.text = state.countryText;
    }
    if (_stateCtrl.text != state.stateText && state.stateText.isNotEmpty) {
      _stateCtrl.text = state.stateText;
    }
    if (_cityCtrl.text != state.cityText && state.cityText.isNotEmpty) {
      _cityCtrl.text = state.cityText;
    }
    if (_pincodeCtrl.text != state.pincodeText && state.pincodeText.isNotEmpty) {
      _pincodeCtrl.text = state.pincodeText;
    }
    // Step 2 controller initial sync (only once to allow full editing, clearing, and typing 0)
    if (!_step2Initialized && state.deliveryFee > 0) {
      _deliveryFeeCtrl.text = state.deliveryFee.toInt().toString();
      _feeLimitCtrl.text = state.feeLimit.toInt().toString();
      if (state.perKmFee > 0) {
        _perKmFeeCtrl.text = state.perKmFee.toInt().toString();
      }
      if (state.codLimitType == 'any') {
        _codLimitCtrl.text = '0';
      } else if (state.codLimit > 0) {
        _codLimitCtrl.text = state.codLimit.toInt().toString();
      }
      _step2Initialized = true;
    }
    // Step 3 controller initial sync
    if (!_step3Initialized) {
      _otherFeeCtrl.text = state.otherDeliveryFee > 0
          ? state.otherDeliveryFee.toInt().toString()
          : '60';
      _otherLimitCtrl.text = state.otherFeeLimit > 0
          ? state.otherFeeLimit.toInt().toString()
          : '2000';
      _step3Initialized = true;
    }
  }

  // ── Navigation ───────────────────────────────────────────────────────────

  void _goToStep(int step) {
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    ref.read(addStoreControllerProvider.notifier).setStep(step);
    if (_pageController.hasClients) {
      _pageController.jumpToPage(step);
    }
  }

  void _onNextPressed(AddStoreState state, AddStoreController notifier) {
    if (state.isSingleStepFlow) {
      final err = notifier.validateStep1();
      if (err != null) {
        _showError(err);
        return;
      }
      _submitStore(notifier);
      return;
    }

    if (state.currentStep == 0) {
      final err = notifier.validateStep1();
      if (err != null) {
        _showError(err);
        return;
      }
      _goToStep(1);
    } else if (state.currentStep == 1) {
      final err = notifier.validateStep2();
      if (err != null) {
        _showError(err);
        return;
      }
      _goToStep(2);
    } else if (state.currentStep == 2) {
      _submitStore(notifier);
    }
  }

  void _onBackPressed(AddStoreState state) {
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    if (state.currentStep > 0) {
      _goToStep(state.currentStep - 1);
    } else {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _submitStore(AddStoreController notifier) async {
    final success = await notifier.submitStore();
    if (!mounted) return;

    if (success) {
      final state = ref.read(addStoreControllerProvider);
      final isOthersCategory = state.selectedCategory?.id == 'others';

      if (isOthersCategory) {
        // Case A: Category 'Others' -> Navigate directly to Confirmation / Acknowledgment Screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const OthersAcknowledgmentScreen(),
          ),
        );
      } else {
        // Case B: Normal Category -> Completely REMOVE popup/dialog, show brief Toast/SnackBar, immediately redirect to Dashboard
        final message = state.successMessage?.trim();
        final toastText = (message != null && message.isNotEmpty)
            ? message
            : 'Store created successfully';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(toastText),
            backgroundColor: const Color(0xFF388E3C),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );

        ref.read(storesProvider.notifier).fetchMerchantStores();
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } else {
      final err = ref.read(addStoreControllerProvider).error ??
          AppStrings.storeCreationFailed;
      _showError(err);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFD32F2F),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Location Picker Trigger ──────────────────────────────────────────────

  Future<void> _openLocationPicker(AddStoreController notifier) async {
    final picked = await Navigator.of(context).push<PickedLocationData>(
      MaterialPageRoute(
        builder: (_) => const SelectStoreLocationScreen(),
      ),
    );

    if (picked != null && mounted) {
      notifier.updateLocationFromMap(picked);
      final rawAddr = picked.formattedAddress.isNotEmpty
          ? picked.formattedAddress
          : (picked.street.isNotEmpty ? picked.street : '');
      _addressCtrl.text = AddStoreController.sanitizePhysicalAddress(rawAddr);
      _countryCtrl.text = picked.country.isNotEmpty ? picked.country : 'India';
      _stateCtrl.text = picked.state;
      _cityCtrl.text = picked.city;
      _pincodeCtrl.text = picked.postalCode;
    }
  }

  // ── OTP Dialog Trigger ───────────────────────────────────────────────────

  Future<void> _verifyPrimaryMobile(
      AddStoreState state, AddStoreController notifier) async {
    if (state.primaryNumber == null || state.primaryNumber.toString().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 10-digit primary mobile number'),
          backgroundColor: Color(0xFFD32F2F),
        ),
      );
      return;
    }

    await notifier.sendPrimaryOtp();
    if (!mounted) return;

    final verified = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => OtpVerifyDialog(
        mobileNumber: state.primaryNumber!,
        onVerify: (otp) => notifier.verifyPrimaryOtp(otp),
        onResend: () => notifier.sendPrimaryOtp(),
      ),
    );

    if (!mounted) return;
    if (verified == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.primaryMobileVerifiedSuccess),
          backgroundColor: Color(0xFF388E3C),
        ),
      );
    }
  }

  Future<void> _verifySecondaryMobile(
      AddStoreState state, AddStoreController notifier) async {
    if (state.secondaryNumber == null || state.secondaryNumber.toString().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 10-digit secondary mobile number'),
          backgroundColor: Color(0xFFD32F2F),
        ),
      );
      return;
    }

    await notifier.sendSecondaryOtp();
    if (!mounted) return;

    final verified = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => OtpVerifyDialog(
        mobileNumber: state.secondaryNumber!,
        onVerify: (otp) => notifier.verifySecondaryOtp(otp),
        onResend: () => notifier.sendSecondaryOtp(),
      ),
    );

    if (!mounted) return;
    if (verified == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.secondaryMobileVerifiedSuccess),
          backgroundColor: Color(0xFF388E3C),
        ),
      );
    }
  }

  // ── Time Picker Helpers ──────────────────────────────────────────────────

  Future<void> _pickTime({
    required bool isFrom,
    required AddStoreController notifier,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isFrom
          ? const TimeOfDay(hour: 9, minute: 0)
          : const TimeOfDay(hour: 21, minute: 0),
    );
    if (picked != null && mounted) {
      final formatted = picked.format(context);
      if (isFrom) {
        notifier.setDeliveryFrom(formatted);
      } else {
        notifier.setDeliveryTo(formatted);
      }
    }
  }



  // ── Build Method ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addStoreControllerProvider);
    final notifier = ref.read(addStoreControllerProvider.notifier);

    _syncControllersWithState(state);

    final bool isWholesale = state.isWholesale;

    final String pageTitle = isWholesale
        ? AppStrings.createWholesaleStoreTitle
        : AppStrings.createNewStoreTitle;

    return PopScope(
      canPop: state.currentStep == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _onBackPressed(state);
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => _onBackPressed(state),
          ),
          title: Text(
            pageTitle,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(state.isSingleStepFlow ? 3.0 : 50.0),
            child: Column(
              children: [
                if (!state.isSingleStepFlow) ...[
                  StepIndicator(
                    currentStep: state.currentStep,
                  ),
                ],
                SizedBox(
                  height: 3.0,
                  child: state.isCategoriesLoading
                      ? const LinearProgressIndicator(
                          minHeight: 3.0,
                          backgroundColor: Color(0xFFE3F2FD),
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)),
                        )
                      : (state.isSingleStepFlow
                          ? const SizedBox(height: 3.0)
                          : const Divider(height: 1, color: Color(0xFFE0E0E0))),
                ),
              ],
            ),
          ),
        ),
        body: SafeArea(
          child: IndexedStack(
            index: state.currentStep.clamp(0, 2),
            children: [
              _buildStep1(state, notifier),
              _buildStep2(state, notifier),
              _buildStep3(state, notifier),
            ],
          ),
        ),
        bottomNavigationBar: AnimatedPadding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          duration: const Duration(milliseconds: 100),
          child: SafeArea(
            child: _buildBottomBar(state, notifier),
          ),
        ),
      ),
    );
  }

  // ── Step 1: Store Basics, Media & Location ────────────────────────────────

  Widget _buildStep1(AddStoreState state, AddStoreController notifier) {
    final bool typeExists =
        state.storeTypes.any((t) => t.id == state.selectedType?.id);
    final bool categoryExists =
        state.categories.any((c) => c.id == state.selectedCategory?.id);

    return SingleChildScrollView(
      key: const PageStorageKey('add_store_step_1'),
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Store Type Dropdown
          const Text('Store Type *', style: _labelStyle),
          const SizedBox(height: 6),
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: _boxDecoration,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<StoreTypeModel>(
                isDense: true,
                isExpanded: true,
                iconSize: 22,
                value: typeExists
                    ? state.storeTypes
                        .firstWhere((t) => t.id == state.selectedType?.id)
                    : null,
                hint: const Text('Select Store Type',
                    style: TextStyle(fontSize: 14, color: Colors.grey)),
                items: state.storeTypes.map((t) {
                  return DropdownMenuItem<StoreTypeModel>(
                    value: t,
                    child: Text(t.name,
                        style: const TextStyle(fontSize: 14)),
                  );
                }).toList(),
                onChanged: notifier.onTypeChanged,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 2. Store Category Dropdown
          const Text('Store Category *', style: _labelStyle),
          const SizedBox(height: 6),
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: _boxDecoration.copyWith(
              color: state.isCategoriesLoading
                  ? const Color(0xFFF5F5F5)
                  : Colors.white,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<StoreCategoryModel>(
                isDense: true,
                isExpanded: true,
                iconSize: 22,
                value: (categoryExists && !state.isCategoriesLoading)
                    ? state.categories
                        .firstWhere((c) => c.id == state.selectedCategory?.id)
                    : null,
                hint: const Text(
                  'Select Store Category',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                items: state.isCategoriesLoading
                    ? null
                    : state.categories.map((c) {
                        return DropdownMenuItem<StoreCategoryModel>(
                          value: c,
                          child: Text(c.displayName,
                              style: const TextStyle(fontSize: 14)),
                        );
                      }).toList(),
                onChanged: state.isCategoriesLoading
                    ? null
                    : notifier.onCategoryChanged,
              ),
            ),
          ),

          // "Others" category extra fields
          if (state.selectedCategory?.id == 'others') ...[
            const SizedBox(height: 16),
            const Text('Category Description *', style: _labelStyle),
            const SizedBox(height: 6),
            TextField(
              controller: _categoryDescCtrl,
              style: _inputTextStyle,
              cursorHeight: _cursorHeight,
              cursorWidth: _cursorWidth,
              onChanged: notifier.setCategoryDescription,
              decoration: _inputDecoration('Describe your store products'),
            ),
            const SizedBox(height: 16),
            const Text('Convenient Contact Time', style: _labelStyle),
            const SizedBox(height: 6),
            TextField(
              controller: _contactTimeCtrl,
              style: _inputTextStyle,
              cursorHeight: _cursorHeight,
              cursorWidth: _cursorWidth,
              onChanged: notifier.setContactTime,
              decoration: _inputDecoration('e.g. 10:00 AM - 02:00 PM'),
            ),
          ],

          const SizedBox(height: 16),

          // 3. Store Name
          const Text('Store Name *', style: _labelStyle),
          const SizedBox(height: 6),
          TextField(
            controller: _nameCtrl,
            style: _inputTextStyle,
            cursorHeight: _cursorHeight,
            cursorWidth: _cursorWidth,
            onChanged: notifier.setStoreName,
            decoration: _inputDecoration('Enter store display name'),
          ),

          const SizedBox(height: 20),

          // 4. Media Picker on Page 1 (Legacy Android exact parity)
          StoreImagePicker(
            images: state.images,
            onImagesChanged: notifier.setImages,
          ),

          const SizedBox(height: 20),

          // 5. Primary Mobile Number with OTP Verification
          const Text('Primary Mobile Number *', style: _labelStyle),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                decoration: _boxDecoration,
                child: const Text(
                  '+91',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _primaryMnoCtrl,
                  style: _inputTextStyle,
                  cursorHeight: _cursorHeight,
                  cursorWidth: _cursorWidth,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  onChanged: (val) =>
                      notifier.setPrimaryNumber(int.tryParse(val)),
                  decoration: _inputDecoration('10-digit number'),
                ),
              ),
              const SizedBox(width: 8),
              state.isPrimaryVerified
                  ? Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF81C784)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle,
                              size: 16, color: Color(0xFF388E3C)),
                          SizedBox(width: 4),
                          Text(
                            'Verified',
                            style: TextStyle(
                              color: Color(0xFF388E3C),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ElevatedButton(
                      onPressed: () => _verifyPrimaryMobile(state, notifier),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1976D2),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(70, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Verify', style: TextStyle(fontSize: 12)),
                    ),
            ],
          ),

          const SizedBox(height: 16),

          // Secondary Contact (Optional)
          const Text('Secondary number (Optional)', style: _labelStyle),
          const SizedBox(height: 6),
          // Full-width Type Selector Dropdown
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: _boxDecoration,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isDense: true,
                isExpanded: true,
                value: state.secondaryType,
                items: const [
                  DropdownMenuItem(
                    value: 'mobile',
                    child: Text('Secondary Mobile', style: TextStyle(fontSize: 13)),
                  ),
                  DropdownMenuItem(
                    value: 'landline',
                    child: Text('Landline Number', style: TextStyle(fontSize: 13)),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    notifier.setSecondaryType(val);
                    if (val == 'mobile') {
                      _secCodeCtrl.text = '+91';
                    } else {
                      _secCodeCtrl.text = '';
                    }
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Input Layout Behavior
          if (state.secondaryType == 'mobile') ...[
            Row(
              children: [
                Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  decoration: _boxDecoration,
                  child: const Text(
                    '+91',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _secMnoCtrl,
                    style: _inputTextStyle,
                    cursorHeight: _cursorHeight,
                    cursorWidth: _cursorWidth,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    onChanged: (val) =>
                        notifier.setSecondaryNumber(int.tryParse(val)),
                    decoration: _inputDecoration('Enter Secondary Number'),
                  ),
                ),
                const SizedBox(width: 8),
                state.isSecondaryVerified
                    ? Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF81C784)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle,
                                size: 16, color: Color(0xFF388E3C)),
                            SizedBox(width: 4),
                            Text(
                              'Verified',
                              style: TextStyle(
                                color: Color(0xFF388E3C),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ElevatedButton(
                        onPressed: () =>
                            _verifySecondaryMobile(state, notifier),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1976D2),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(70, 40),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Verify',
                            style: TextStyle(fontSize: 12)),
                      ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                SizedBox(
                  width: 85,
                  child: TextField(
                    controller: _secCodeCtrl,
                    style: _inputTextStyle,
                    cursorHeight: _cursorHeight,
                    cursorWidth: _cursorWidth,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(5),
                    ],
                    onChanged: notifier.setSecCodeText,
                    decoration: _inputDecoration('Code'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _secMnoCtrl,
                    style: _inputTextStyle,
                    cursorHeight: _cursorHeight,
                    cursorWidth: _cursorWidth,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(11),
                    ],
                    onChanged: (val) =>
                        notifier.setSecondaryNumber(int.tryParse(val)),
                    decoration: _inputDecoration('Enter Secondary Number'),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 20),

          // 6. Store Address & Map Location Picker
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Store Address *', style: _labelStyle),
              Text(
                state.latitude != 0.0
                    ? 'GPS: ${state.latitude.toStringAsFixed(3)}, ${state.longitude.toStringAsFixed(3)}'
                    : 'Location not picked',
                style: TextStyle(
                  fontSize: 11,
                  color: state.latitude != 0.0
                      ? const Color(0xFF388E3C)
                      : const Color(0xFFD32F2F),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _addressCtrl,
                  style: _inputTextStyle,
                  cursorHeight: _cursorHeight,
                  cursorWidth: _cursorWidth,
                  minLines: 3,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  onChanged: notifier.setStreet,
                  decoration: _inputDecoration('Street address / Building name'),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _openLocationPicker(notifier),
                borderRadius: BorderRadius.circular(10),
                child: const SizedBox(
                  height: 85,
                  width: 44,
                  child: Center(
                    child: Icon(
                      Icons.location_on,
                      color: Color(0xFFD32F2F),
                      size: 30,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'To select store address click on the right side map button.',
            style: TextStyle(fontSize: 11, color: Color(0xFFD32F2F)),
          ),

          const SizedBox(height: 16),

          // 7. Cascading Country & State (Matches Android CountrySpinner & StateSpinner)
          Builder(
            builder: (context) {
              final displayedCountries = List<String>.from(state.countries);
              if (state.selectedCountry != null &&
                  state.selectedCountry!.isNotEmpty &&
                  !displayedCountries.contains(state.selectedCountry)) {
                displayedCountries.insert(0, state.selectedCountry!);
              }

              final displayedStates = List<String>.from(state.states);
              if (state.selectedState != null &&
                  state.selectedState!.isNotEmpty &&
                  !displayedStates.contains(state.selectedState)) {
                displayedStates.insert(0, state.selectedState!);
              }

              final selectedCountryVal = (state.selectedCountry != null &&
                      displayedCountries.contains(state.selectedCountry))
                  ? state.selectedCountry
                  : (displayedCountries.isNotEmpty ? displayedCountries.first : null);

              final selectedStateVal = (state.selectedState != null &&
                      displayedStates.contains(state.selectedState))
                  ? state.selectedState
                  : (displayedStates.isNotEmpty ? displayedStates.first : null);

              return Row(
                children: [
                  // Country Dropdown
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Country *', style: _labelStyle),
                        const SizedBox(height: 6),
                        Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: _boxDecoration,
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isDense: true,
                              isExpanded: true,
                              value: selectedCountryVal,
                              hint: const Text('Select Country', style: TextStyle(fontSize: 13, color: Colors.grey)),
                              items: displayedCountries.map((c) {
                                return DropdownMenuItem<String>(
                                  value: c,
                                  child: Text(c, style: const TextStyle(fontSize: 13)),
                                );
                              }).toList(),
                              onChanged: notifier.onCountryChanged,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // State Dropdown
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('State *', style: _labelStyle),
                        const SizedBox(height: 6),
                        Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: _boxDecoration,
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isDense: true,
                              isExpanded: true,
                              value: selectedStateVal,
                              hint: const Text('Select State', style: TextStyle(fontSize: 13, color: Colors.grey)),
                              items: displayedStates.map((s) {
                                return DropdownMenuItem<String>(
                                  value: s,
                                  child: Text(s, style: const TextStyle(fontSize: 13)),
                                );
                              }).toList(),
                              onChanged: notifier.onStateChanged,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 16),

          // 8. Cascading City & Pin Code (Matches Android CitySpinner & edt_pincode)
          Builder(
            builder: (context) {
              final currentSelectedState =
                  (state.selectedState ?? '').trim().toLowerCase();
              final stateCities = state.allLocations
                  .where((l) =>
                      l.state.trim().toLowerCase() == currentSelectedState)
                  .toList();

              final displayedCities = List<LocationModel>.from(stateCities);
              if (state.selectedCity != null &&
                  state.selectedCity!.state.trim().toLowerCase() ==
                      currentSelectedState &&
                  !displayedCities.any((c) => c.id == state.selectedCity!.id)) {
                displayedCities.insert(0, state.selectedCity!);
              }

              // Deduplicate by ID / city name to prevent duplicate DropdownMenuItem keys
              final seenCityKeys = <String>{};
              final uniqueCities = displayedCities.where((c) {
                final key = c.id.isNotEmpty ? c.id : c.city.toLowerCase();
                return seenCityKeys.add(key);
              }).toList();

              // Sort dropdown items alphabetically (A to Z) case-insensitively
              uniqueCities.sort((a, b) =>
                  a.city.toLowerCase().compareTo(b.city.toLowerCase()));

              final selectedCityVal = (state.selectedCity != null &&
                      state.selectedCity!.state.trim().toLowerCase() ==
                          currentSelectedState &&
                      uniqueCities.any((c) =>
                          c.id == state.selectedCity!.id ||
                          c.city.toLowerCase() ==
                              state.selectedCity!.city.toLowerCase()))
                  ? uniqueCities.firstWhere((c) =>
                      c.id == state.selectedCity!.id ||
                      c.city.toLowerCase() ==
                          state.selectedCity!.city.toLowerCase())
                  : (uniqueCities.isNotEmpty ? uniqueCities.first : null);

              return Row(
                children: [
                  // City Dropdown
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('City *', style: _labelStyle),
                        const SizedBox(height: 6),
                        Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: _boxDecoration,
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<LocationModel>(
                              isDense: true,
                              isExpanded: true,
                              value: selectedCityVal,
                              hint: const Text('Select City', style: TextStyle(fontSize: 13, color: Colors.grey)),
                              items: uniqueCities.map((c) {
                                return DropdownMenuItem<LocationModel>(
                                  value: c,
                                  child: Text(c.city, style: const TextStyle(fontSize: 13)),
                                );
                              }).toList(),
                              onChanged: notifier.onCityChanged,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Pincode
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Pin Code *', style: _labelStyle),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _pincodeCtrl,
                          style: _inputTextStyle,
                          cursorHeight: _cursorHeight,
                          cursorWidth: _cursorWidth,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                          onChanged: notifier.setPincodeText,
                          decoration: _inputDecoration('6-digit code'),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Step 2: Operations, Hours/Slots & Fulfillment ────────────────────────

  Widget _buildStep2(AddStoreState state, AddStoreController notifier) {
    final isWholesale = state.isWholesale;

    final distanceOptions = state.deliveryDistanceOptions.isNotEmpty
        ? state.deliveryDistanceOptions
        : AddStoreController.computeDeliveryDistanceOptions(
            category: state.selectedCategory,
            isWholesale: isWholesale,
          );
    final selectedRadiusInt = state.deliveryRadius.toInt();
    final selectedRadius = distanceOptions.contains(selectedRadiusInt)
        ? state.deliveryRadius
        : AddStoreController.computeDefaultDeliveryRadius(
            category: state.selectedCategory,
            isWholesale: isWholesale,
            options: distanceOptions,
          ).toDouble();

    return SingleChildScrollView(
      key: const PageStorageKey('add_store_step_2'),
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Delivery / Shipping Details Title
          const Text(AppStrings.deliveryShippingDetailsTitle,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          // 2. Max Delivery Distance (Wholesale: 5-50 km step 5; Standard: dynamic by category)
          const Text(AppStrings.maxDeliveryDistanceLabel, style: _labelStyle),
          const SizedBox(height: 6),
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: _boxDecoration,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<double>(
                key: const Key('max_delivery_distance_dropdown'),
                isDense: true,
                isExpanded: true,
                value: selectedRadius,
                items: distanceOptions.map((km) {
                  return DropdownMenuItem<double>(
                    value: km.toDouble(),
                    child: Text('$km km', style: const TextStyle(fontSize: 13)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) notifier.setDeliveryRadius(val);
                },
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Wholesale Specific Ordering: Time Slots directly after Max Delivery Distance
          if (isWholesale) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Select delivery time slots:*',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Orders Limit ',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '(Optional)',
                        style: TextStyle(
                          color: Color(0xFFE53935),
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Column(
              children: state.wholesaleTimeSlots.map((slot) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Checkbox(
                        key: Key('wholesale_slot_cb_${slot.id}'),
                        value: slot.isSelected,
                        activeColor: const Color(0xFF1976D2),
                        onChanged: (val) => notifier.toggleWholesaleTimeSlot(
                            slot.id, val ?? false),
                      ),
                      Expanded(
                        child: Text(
                          slot.slotName,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: SizedBox(
                          width: 75,
                          height: 38,
                          child: TextFormField(
                            key: Key('wholesale_slot_limit_${slot.id}'),
                            enabled: slot.isSelected,
                            initialValue:
                                slot.limit > 0 ? slot.limit.toString() : '',
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            style: const TextStyle(fontSize: 13),
                            decoration: const InputDecoration(
                              isDense: true,
                              hintText: 'Limit',
                              hintStyle: TextStyle(
                                  color: Colors.grey, fontSize: 12),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 8),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (val) {
                              final l = int.tryParse(val) ?? 0;
                              notifier.updateWholesaleTimeSlotLimit(
                                  slot.id, l);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 14),

            // Delivery by: * (Shop, Agency, Self pickup horizontal row)
            const Text(AppStrings.deliveryByLabel, style: _labelStyle),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _buildDeliveryCheckbox(
                    key: const Key('delivery_by_shop'),
                    label: AppStrings.deliveryByShop,
                    value: state.deliveryTypes.contains(1),
                    onChanged: () => notifier.toggleDeliveryType(1),
                  ),
                ),
                Expanded(
                  child: _buildDeliveryCheckbox(
                    key: const Key('delivery_by_agency'),
                    label: AppStrings.deliveryByAgency,
                    value: state.deliveryTypes.contains(2),
                    onChanged: () => notifier.toggleDeliveryType(2),
                  ),
                ),
                Expanded(
                  child: _buildDeliveryCheckbox(
                    key: const Key('delivery_by_self'),
                    label: AppStrings.deliveryBySelfPickup,
                    value: state.deliveryTypes.contains(3),
                    onChanged: () => notifier.toggleDeliveryType(3),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Delivery charges up to 2km
            const Text(
              'Delivery charges up to 2km:',
              style: _labelStyle,
            ),
            const SizedBox(height: 6),
            TextField(
              key: const Key('delivery_fee_input'),
              keyboardType: TextInputType.number,
              controller: _deliveryFeeCtrl,
              style: _inputTextStyle,
              cursorHeight: _cursorHeight,
              cursorWidth: _cursorWidth,
              onChanged: (val) =>
                  notifier.setDeliveryFee(double.tryParse(val) ?? 0.0),
              decoration: _inputDecoration(
                'Amount',
                helperText: AppStrings.applicableLessThanMinPurchaseLimit,
              ),
            ),

            const SizedBox(height: 14),

            // Minimum purchase limit & "Limit Applied" Row (Wholesale Flow)
            const Text(
              'Minimum purchase limit:',
              style: _labelStyle,
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                               Expanded(
                  child: TextField(
                    key: const Key('fee_limit_input'),
                    keyboardType: TextInputType.number,
                    controller: _feeLimitCtrl,
                    enabled: state.isLimitApplied,
                    style: _inputTextStyle,
                    cursorHeight: _cursorHeight,
                    cursorWidth: _cursorWidth,
                    onChanged: (val) =>
                        notifier.setFeeLimit(double.tryParse(val) ?? 0.0),
                    decoration: _inputDecoration(
                      AppStrings.minPurchaseAmountHint,
                    ),
                  ),
                ),
                 Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      key: const Key('limit_applied_checkbox'),
                      value: state.isLimitApplied,
                      activeColor: const Color(0xFF1976D2),
                      onChanged: (val) =>
                          notifier.setIsLimitApplied(val ?? false),
                    ),
                    const Text(
                      'Limit Applied',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(left: 12.0, top: 4.0, bottom: 4.0),
              child: Text(
                AppStrings.helperLimitAppliedDesc,
                maxLines: 3,
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFFE53935),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Delivery charge per km
            const Text(AppStrings.deliveryChargePerKmLabel, style: _labelStyle),
            const SizedBox(height: 6),
            TextField(
              keyboardType: TextInputType.number,
              controller: _perKmFeeCtrl,
              style: _inputTextStyle,
              cursorHeight: _cursorHeight,
              cursorWidth: _cursorWidth,
              onChanged: (val) =>
                  notifier.setPerKmFee(double.tryParse(val) ?? 0.0),
              decoration: _inputDecoration(
                'Amount',
                helperText: AppStrings.after2KmChargeApplicable,
              ),
            ),

            const SizedBox(height: 8),

            // Delivery charge applicable for subscription order?
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text(AppStrings.deliveryChargeSubsTitle,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              subtitle: const Text(AppStrings.deliveryChargeSubsSubtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
              value: state.isDeliveryFeeSubs,
              activeColor: const Color(0xFF1976D2),
              onChanged: notifier.setIsDeliveryFeeSubs,
            ),
          ] else ...[
            // Non-wholesale (B2C / D2C) fields
            const Text(
              'Delivery charges up to 2km:',
              style: _labelStyle,
            ),
            const SizedBox(height: 6),
            TextField(
              key: const Key('delivery_fee_input'),
              keyboardType: TextInputType.number,
              controller: _deliveryFeeCtrl,
              style: _inputTextStyle,
              cursorHeight: _cursorHeight,
              cursorWidth: _cursorWidth,
              onChanged: (val) =>
                  notifier.setDeliveryFee(double.tryParse(val) ?? 0.0),
              decoration: _inputDecoration(
                'Amount',
                helperText: AppStrings.applicableLessThanMinPurchaseLimit,
              ),
            ),

            const SizedBox(height: 14),

            // Minimum purchase limit (Non-Wholesale B2C/D2C Flow: Full width, no Limit Applied checkbox or helper text)
            const Text(
              'Minimum purchase limit:',
              style: _labelStyle,
            ),
            const SizedBox(height: 6),
            TextField(
              key: const Key('fee_limit_input'),
              keyboardType: TextInputType.number,
              controller: _feeLimitCtrl,
              style: _inputTextStyle,
              cursorHeight: _cursorHeight,
              cursorWidth: _cursorWidth,
              onChanged: (val) =>
                  notifier.setFeeLimit(double.tryParse(val) ?? 0.0),
              decoration: _inputDecoration(
                AppStrings.minPurchaseAmountHint,
              ),
            ),

            const SizedBox(height: 14),

            // Delivery charge per km
            const Text(AppStrings.deliveryChargePerKmLabel, style: _labelStyle),
            const SizedBox(height: 6),
            TextField(
              keyboardType: TextInputType.number,
              controller: _perKmFeeCtrl,
              style: _inputTextStyle,
              cursorHeight: _cursorHeight,
              cursorWidth: _cursorWidth,
              onChanged: (val) =>
                  notifier.setPerKmFee(double.tryParse(val) ?? 0.0),
              decoration: _inputDecoration(
                'Amount',
                helperText: AppStrings.after2KmChargeApplicable,
              ),
            ),

            const SizedBox(height: 8),

            // Delivery charge applicable for subscription order?
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text(AppStrings.deliveryChargeSubsTitle,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              subtitle: const Text(AppStrings.deliveryChargeSubsSubtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
              value: state.isDeliveryFeeSubs,
              activeColor: const Color(0xFF1976D2),
              onChanged: notifier.setIsDeliveryFeeSubs,
            ),

            const SizedBox(height: 12),

            // Delivery by: * (Shop, Agency, Self pickup horizontal row)
            const Text(AppStrings.deliveryByLabel, style: _labelStyle),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _buildDeliveryCheckbox(
                    key: const Key('delivery_by_shop'),
                    label: AppStrings.deliveryByShop,
                    value: state.deliveryTypes.contains(1),
                    onChanged: () => notifier.toggleDeliveryType(1),
                  ),
                ),
                Expanded(
                  child: _buildDeliveryCheckbox(
                    key: const Key('delivery_by_agency'),
                    label: AppStrings.deliveryByAgency,
                    value: state.deliveryTypes.contains(2),
                    onChanged: () => notifier.toggleDeliveryType(2),
                  ),
                ),
                Expanded(
                  child: _buildDeliveryCheckbox(
                    key: const Key('delivery_by_self'),
                    label: AppStrings.deliveryBySelfPickup,
                    value: state.deliveryTypes.contains(3),
                    onChanged: () => notifier.toggleDeliveryType(3),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),

            // B2C / D2C Hours
            const Text(AppStrings.deliveryTimeLabel,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(AppStrings.timeFromLabel, style: _labelStyle),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () =>
                            _pickTime(isFrom: true, notifier: notifier),
                        child: Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: _boxDecoration,
                          child: Row(
                            children: [
                              const Icon(Icons.access_time,
                                  size: 18, color: Color(0xFF1976D2)),
                              const SizedBox(width: 8),
                              Text(
                                state.deliveryFrom,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(AppStrings.timeToLabel, style: _labelStyle),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () =>
                            _pickTime(isFrom: false, notifier: notifier),
                        child: Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: _boxDecoration,
                          child: Row(
                            children: [
                              const Icon(Icons.access_time_filled,
                                  size: 18, color: Color(0xFF388E3C)),
                              const SizedBox(width: 8),
                              Text(
                                state.deliveryTo,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold),
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
          ],

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),

          // 3. Payment Methods
          const Text('Payment Options',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          // Cash on Delivery (COD)
          const Text(AppStrings.codTitle, style: _labelStyle),
          const SizedBox(height: 2),
          const Text(AppStrings.codSubtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          Row(
            children: [
              // 1. Dropdown (Any / Limit)
              Expanded(
                flex: 5,
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: _boxDecoration.copyWith(
                    color: (state.isCodEnabled && state.isCod) ? Colors.white : const Color(0xFFF5F5F5),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isDense: true,
                      isExpanded: true,
                      iconSize: 22,
                      value: state.codLimitType,
                      items: const [
                        DropdownMenuItem(
                            value: 'any',
                            child: Text(AppStrings.codAny,
                                style: TextStyle(fontSize: 13))),
                        DropdownMenuItem(
                            value: 'limit',
                            child: Text(AppStrings.codLimit,
                                style: TextStyle(fontSize: 13))),
                      ],
                      onChanged: (state.isCodEnabled && state.isCod)
                          ? (val) {
                              if (val != null) {
                                notifier.setCodLimitType(val);
                                if (val == 'any') {
                                  _codLimitCtrl.text = '0';
                                  notifier.setCodLimit(0.0);
                                }
                              }
                            }
                          : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // 2. Amount Text Input
              Expanded(
                flex: 5,
                child: TextField(
                  keyboardType: TextInputType.number,
                  controller: _codLimitCtrl,
                  enabled: state.isCodEnabled && state.isCod && state.codLimitType == 'limit',
                  style: (state.isCodEnabled && state.isCod && state.codLimitType == 'limit')
                      ? _inputTextStyle
                      : _inputTextStyle.copyWith(color: Colors.grey.shade600),
                  cursorHeight: _cursorHeight,
                  cursorWidth: _cursorWidth,
                  onChanged: (val) =>
                      notifier.setCodLimit(double.tryParse(val) ?? 0.0),
                  decoration: _inputDecoration(
                    AppStrings.maxCodHint,
                    fillColor: (state.isCodEnabled && state.isCod && state.codLimitType == 'limit')
                        ? Colors.white
                        : const Color(0xFFF5F5F5),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // 3. Toggle Switch
              Switch(
                key: const Key('cod_switch'),
                value: state.isCod,
                activeColor: const Color(0xFF1976D2),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onChanged: state.isCodEnabled
                    ? (val) {
                        if (!val && !state.isOnlinePayment) {
                          _showError(AppStrings.atLeastOnePaymentMethodRequired);
                          return;
                        }
                        notifier.setIsCod(val);
                      }
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            key: const Key('online_payment_switch'),
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text(AppStrings.onlinePaymentTitle,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: const Text(AppStrings.onlinePaymentSubtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            value: state.isOnlinePayment,
            activeColor: const Color(0xFF1976D2),
            onChanged: state.isOnlinePaymentEnabled
                ? (val) {
                    if (!val && !state.isCod) {
                      _showError(AppStrings.atLeastOnePaymentMethodRequired);
                      return;
                    }
                    notifier.setIsOnlinePayment(val);
                  }
                : null,
          ),

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),

          // 4. Return & Refund Policies
          // Return & Refund Policies (Dynamic based on Category)
          if ((!isWholesale && state.replacementAccepted) || state.refundAccepted) ...[
            const Text('Return & Refund Policies',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            if (!isWholesale && state.replacementAccepted) ...[
              // Replacement Dropdown (Hidden for Wholesale flows)
              Text(AppStrings.productReplacementWithinLabel, style: _labelStyle),
              const SizedBox(height: 6),
              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: _boxDecoration,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    key: const Key('replacement_dropdown'),
                    isDense: true,
                    isExpanded: true,
                    value: state.replacementOptions.containsKey(state.replacementDays)
                        ? state.replacementDays
                        : (state.replacementOptions.isNotEmpty
                            ? state.replacementOptions.keys.first
                            : null),
                    items: state.replacementOptions.entries.map((e) {
                      return DropdownMenuItem<int>(
                        value: e.key,
                        child: Text(e.value,
                            style: const TextStyle(fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) notifier.setReplacementDays(val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            if (state.refundAccepted) ...[
              // Refund Dropdown
              Text(AppStrings.refundWithinLabel, style: _labelStyle),
              const SizedBox(height: 6),
              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: _boxDecoration,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    key: const Key('refund_dropdown'),
                    isDense: true,
                    isExpanded: true,
                    value: state.refundOptions.containsKey(state.refundDays)
                        ? state.refundDays
                        : (state.refundOptions.isNotEmpty
                            ? state.refundOptions.keys.first
                            : null),
                    items: state.refundOptions.entries.map((e) {
                      return DropdownMenuItem<int>(
                        value: e.key,
                        child: Text(e.value,
                            style: const TextStyle(fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) notifier.setRefundDays(val);
                    },
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
          ],

          // 5. Working Days
          AvailabilityDaysRow(
            selectedDays: state.availability,
            onDaysChanged: notifier.setAvailability,
          ),
          const SizedBox(height: 24),


        ],
      ),
    );
  }

  // ── Step 3: Other Location Delivery AND Privacy & Terms Acceptance ─────────────────

  Widget _buildStep3(AddStoreState state, AddStoreController notifier) {
    final otherSupported = state.isOtherDeliverySupported;
    final otherActive = otherSupported && state.otherDeliveryEnabled;

    return SingleChildScrollView(
      key: const PageStorageKey('add_store_step_3'),
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Extended Delivery / Other Locations
          const Text(
            AppStrings.extendedDeliveryTitle,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              const Expanded(
                child: Text(
                  AppStrings.enableOtherLocations,
                  style: _labelStyle,
                ),
              ),
              Switch(
                value: otherActive,
                activeColor: const Color(0xFF1976D2),
                onChanged: otherSupported
                    ? notifier.setOtherDeliveryEnabled
                    : null,
              ),
            ],
          ),

          if (otherActive) ...[
            const SizedBox(height: 12),

            // Select Target Countries
            const Text(AppStrings.selectTargetCountriesLabel, style: _labelStyle),
            const SizedBox(height: 6),
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: _boxDecoration,
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isDense: true,
                  isExpanded: true,
                  value: 'India',
                  items: const [
                    DropdownMenuItem(
                      value: 'India',
                      child: Text('India', style: TextStyle(fontSize: 13)),
                    ),
                  ],
                  onChanged: (_) {},
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Delivery by: Shop & Agency checkboxes horizontally
            const Text(AppStrings.deliveryByLabel, style: _labelStyle),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text(AppStrings.deliveryByShop,
                        style: TextStyle(fontSize: 13)),
                    value: state.otherDeliveryTypes.contains(1),
                    activeColor: const Color(0xFF1976D2),
                    onChanged: (val) => notifier.toggleOtherDeliveryType(1),
                  ),
                ),
                Expanded(
                  child: CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text(AppStrings.deliveryByAgency,
                        style: TextStyle(fontSize: 13)),
                    value: state.otherDeliveryTypes.contains(2),
                    activeColor: const Color(0xFF1976D2),
                    onChanged: (val) => notifier.toggleOtherDeliveryType(2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Delivery Charge
            const Text(AppStrings.deliveryChargeLabel, style: _labelStyle),
            const SizedBox(height: 2),
            const Text(
              AppStrings.applicableLessThanMinPurchaseLimitStep3,
              style: TextStyle(fontSize: 11, color: Color(0xFFD32F2F)),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _otherFeeCtrl,
              keyboardType: TextInputType.number,
              style: _inputTextStyle,
              cursorHeight: _cursorHeight,
              cursorWidth: _cursorWidth,
              onChanged: (val) => notifier
                  .setOtherDeliveryFee(double.tryParse(val) ?? 60.0),
              decoration: _inputDecoration('Amount'),
            ),
            const SizedBox(height: 14),

            // Minimum purchase limit
            const Text(AppStrings.minPurchaseLimitLabelStep3, style: _labelStyle),
            const SizedBox(height: 6),
            TextField(
              controller: _otherLimitCtrl,
              keyboardType: TextInputType.number,
              style: _inputTextStyle,
              cursorHeight: _cursorHeight,
              cursorWidth: _cursorWidth,
              onChanged: (val) => notifier
                  .setOtherFeeLimit(double.tryParse(val) ?? 2000.0),
              decoration: _inputDecoration(AppStrings.minPurchaseAmountHintStep3),
            ),
          ],

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),

          // 2. Privacy: Enable private chat
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFD0D7DE)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  AppStrings.enablePrivateChat,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF212121),
                  ),
                ),
                Switch(
                  value: state.isPrivate,
                  activeColor: const Color(0xFF1976D2),
                  onChanged: notifier.setIsPrivate,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 3. Terms and Conditions (tightened layout & clickable link matching native)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Checkbox(
                    value: state.termsAccepted,
                    activeColor: const Color(0xFF1976D2),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    onChanged: (val) =>
                        notifier.setTermsAccepted(val ?? false),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text.rich(
                      TextSpan(
                        text: 'I agree to the BayFay shop ',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF212121),
                        ),
                        children: [
                          TextSpan(
                            text: 'terms of service and privacy policy.',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF1976D2),
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.w600,
                            ),
                            recognizer: _termsRecognizer,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 4. Store Overview Summary Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBBDEFB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Color(0xFF1976D2), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Store Overview',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1976D2),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _overviewRow('Name', state.storeName),
                _overviewRow(
                    'Category', state.selectedCategory?.displayName ?? '-'),
                _overviewRow('Type', state.selectedType?.name ?? '-'),
                _overviewRow('Address',
                    '${state.street}, ${state.cityText.isNotEmpty ? state.cityText : (state.selectedCity?.city ?? '')}'),
                _overviewRow('Pincode', state.pincodeText),
                _overviewRow('Photos', '${state.images.length} photos chosen'),
                _overviewRow('Working Days', '${state.availability.length} days active'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _overviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '-',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF212121),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryCheckbox({
    Key? key,
    required String label,
    required bool value,
    required VoidCallback onChanged,
  }) {
    return InkWell(
      key: key,
      onTap: onChanged,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                value: value,
                activeColor: const Color(0xFF1976D2),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onChanged: (_) => onChanged(),
              ),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom Navigation Bar ────────────────────────────────────────────────

  Widget _buildBottomBar(AddStoreState state, AddStoreController notifier) {
    final isSingleStep = state.isSingleStepFlow;
    final isLastStep = isSingleStep || state.currentStep == 2;

    if (state.isSubmitting) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton(
            onPressed: null,
            style: ElevatedButton.styleFrom(
              disabledBackgroundColor: const Color(0xFF90CAF9),
              disabledForegroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  'Creating store, please wait...',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
      ),
      child: Row(
        children: [
          if (!isSingleStep && state.currentStep > 0) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: () => _onBackPressed(state),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1976D2),
                  side: const BorderSide(color: Color(0xFF1976D2), width: 1.5),
                  minimumSize: const Size(double.infinity, 46),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Previous',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: ElevatedButton(
              onPressed: () => _onNextPressed(state, notifier),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 46),
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                isLastStep ? 'Create Store' : 'Next',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Styles ───────────────────────────────────────────────────────────────

  static const _labelStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: Color(0xFF37474F),
  );

  static const _inputTextStyle = TextStyle(
    fontSize: 14,
    color: Color(0xFF212121),
  );

  static const double _cursorHeight = 18.0;
  static const double _cursorWidth = 1.5;

  static final _boxDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(10),
    border: Border.all(color: const Color(0xFFD0D7DE)),
  );

  static InputDecoration _inputDecoration(
    String hint, {
    String? helperText,
    Color? fillColor,
  }) {
    return InputDecoration(
      isDense: true,
      hintText: hint,
      helperText: helperText,
      helperStyle: const TextStyle(
        fontSize: 11,
        color: Color(0xFFD32F2F),
        fontStyle: FontStyle.italic,
      ),
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
      filled: true,
      fillColor: fillColor ?? Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFD0D7DE)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFD0D7DE)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF1976D2), width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
    );
  }

}
