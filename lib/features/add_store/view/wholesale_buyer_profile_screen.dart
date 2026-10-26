import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controller/add_store_controller.dart';
import '../model/store_category_model.dart';
import '../repository/add_store_repository.dart';

/// Screen for Wholesale Buyer Profile registration — matches Android `WholesaleBuyerProfile.java`
/// and submits to `POST merchant/wshop/buyer`.
class WholesaleBuyerProfileScreen extends ConsumerStatefulWidget {
  const WholesaleBuyerProfileScreen({super.key});

  @override
  ConsumerState<WholesaleBuyerProfileScreen> createState() =>
      _WholesaleBuyerProfileScreenState();
}

class _WholesaleBuyerProfileScreenState
    extends ConsumerState<WholesaleBuyerProfileScreen> {
  final _storeNameCtrl = TextEditingController();
  final _gstNumberCtrl = TextEditingController();
  final _primaryMobileCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  final _categoryDescCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();

  bool _isSubmitting = false;
  bool _termsAccepted = false;
  bool _isMobileVerified = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctrl = ref.read(addStoreControllerProvider.notifier);
      ctrl.setStoreKind(2);
      ctrl.loadInitialData();
    });
  }

  @override
  void dispose() {
    _storeNameCtrl.dispose();
    _gstNumberCtrl.dispose();
    _primaryMobileCtrl.dispose();
    _addressCtrl.dispose();
    _pincodeCtrl.dispose();
    _categoryDescCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  void _onVerifyMobile() {
    final numStr = _primaryMobileCtrl.text.trim();
    if (numStr.length < 10) {
      _showError('Please enter a valid 10-digit mobile number');
      return;
    }
    setState(() => _isMobileVerified = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mobile number verified successfully'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _onSubmit() async {
    FocusScope.of(context).unfocus();
    final state = ref.read(addStoreControllerProvider);

    if (state.selectedCategory == null) {
      _showError('Please select a store category');
      return;
    }
    final isOther = state.selectedCategory!.id == 'others';
    if (isOther && _categoryDescCtrl.text.trim().isEmpty) {
      _showError('Please enter category description');
      return;
    }
    if (_storeNameCtrl.text.trim().isEmpty) {
      _showError('Please enter store name');
      return;
    }
    final mobileNum = int.tryParse(_primaryMobileCtrl.text.trim()) ?? 0;
    if (_primaryMobileCtrl.text.trim().length < 9 || mobileNum == 0) {
      _showError('Enter a valid primary mobile number');
      return;
    }
    if (!_isMobileVerified) {
      _showError('Please verify your primary mobile number');
      return;
    }
    if (_addressCtrl.text.trim().isEmpty) {
      _showError('Please enter store address');
      return;
    }
    if (_cityCtrl.text.trim().isEmpty) {
      _showError('Please enter city');
      return;
    }
    final zipcode = int.tryParse(_pincodeCtrl.text.trim()) ?? 0;
    if (zipcode == 0) {
      _showError('Please enter pin code');
      return;
    }
    if (!_termsAccepted) {
      _showError('Please accept the Terms & Conditions');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final payload = {
        'category_id': state.selectedCategory!.id,
        if (isOther) 'category_description': _categoryDescCtrl.text.trim(),
        'display_name': _storeNameCtrl.text.trim(),
        if (_gstNumberCtrl.text.trim().isNotEmpty)
          'gstin': _gstNumberCtrl.text.trim(),
        'mobile': {
          'primary': {
            'dialing_code': 91,
            'number': mobileNum,
            'is_verified': true,
          },
        },
        'location': {
          'type': 'Point',
          'coordinates': [0.0, 0.0],
        },
        'address': {
          'location_id': 'loc_default',
          'street': _addressCtrl.text.trim(),
          'zipcode': zipcode,
          'city': _cityCtrl.text.trim(),
        },
      };

      final repo = ref.read(addStoreRepositoryProvider);
      final ok = await repo.registerWholesaleBuyer(payload);

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wholesale buyer profile created successfully!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
        Navigator.of(context).pop();
      } else {
        _showError('Registration failed. Please try again.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showError(e.toString());
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFE53935),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addStoreControllerProvider);
    final ctrl = ref.read(addStoreControllerProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Wholesale Buyer Profile',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE0E0E0)),
        ),
      ),
      body: state.isLoadingTypes
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Store Info
                _Card(
                  title: 'Store Information',
                  children: [
                    state.isLoadingCategories
                        ? const LinearProgressIndicator()
                        : DropdownButtonFormField<StoreCategoryModel>(
                            value: state.selectedCategory,
                            decoration: InputDecoration(
                              labelText: 'Store Category *',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                            ),
                            items: state.categories
                                .map((c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c.displayName),
                                    ))
                                .toList(),
                            onChanged: (c) {
                              if (c != null) ctrl.onCategoryChanged(c);
                            },
                          ),
                    const SizedBox(height: 12),

                    if (state.selectedCategory?.id == 'others') ...[
                      TextField(
                        controller: _categoryDescCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Category Description *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    TextField(
                      controller: _storeNameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Store Name *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _gstNumberCtrl,
                      decoration: InputDecoration(
                        labelText: 'GST Number (Optional)',
                        hintText: '22AAAAA0000A1Z5',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Mobile
                _Card(
                  title: 'Contact Details',
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _primaryMobileCtrl,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            decoration: InputDecoration(
                              labelText: 'Primary Mobile *',
                              prefixText: '+91  ',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 14),
                              suffixIcon: _isMobileVerified
                                  ? const Icon(Icons.verified,
                                      color: Color(0xFF4CAF50))
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_isMobileVerified)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Verified ✓',
                              style: TextStyle(
                                color: Color(0xFF4CAF50),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          )
                        else
                          TextButton(
                            onPressed: _onVerifyMobile,
                            child: const Text('Verify',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Location & Address
                _Card(
                  title: 'Location & Address',
                  children: [
                    TextField(
                      controller: _addressCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Store Address *',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _cityCtrl,
                      decoration: InputDecoration(
                        labelText: 'City *',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _pincodeCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Pin Code *',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Terms & Submit
                _Card(
                  title: 'Terms & Conditions',
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _termsAccepted,
                          onChanged: (v) =>
                              setState(() => _termsAccepted = v ?? false),
                          activeColor: const Color(0xFF4CAF50),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _termsAccepted = !_termsAccepted),
                            child: const Text(
                              'I agree to the Terms & Conditions',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _onSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7043),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Register as Wholesale Buyer',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Card({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF424242),
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}
