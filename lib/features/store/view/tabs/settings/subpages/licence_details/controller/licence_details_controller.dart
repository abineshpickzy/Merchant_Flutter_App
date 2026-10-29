import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayfay_merchant_flutter/features/dashboard/model/store_model.dart';
import '../model/licence_details_model.dart';
import '../repository/licence_details_repository.dart';

final licenceDetailsControllerProvider = StateNotifierProvider.autoDispose
    .family<LicenceDetailsController, LicenceDetailsState, StoreModel>(
  (ref, store) {
    final repo = ref.read(licenceDetailsRepositoryProvider);
    return LicenceDetailsController(repo: repo, store: store);
  },
);

class LicenceDetailsController extends StateNotifier<LicenceDetailsState> {
  final LicenceDetailsRepository _repo;
  final StoreModel _store;

  LicenceDetailsController({
    required LicenceDetailsRepository repo,
    required StoreModel store,
  })  : _repo = repo,
        _store = store,
        super(const LicenceDetailsState()) {
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final res = await _repo.getLicenceDetails(
      shopId: _store.id,
      categoryId: _store.categoryId,
    );

    if (!mounted) return;

    if (res == null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load licence details',
      );
      return;
    }

    state = state.copyWith(
      isLoading: false,
      gstin: res.gstin,
      pan: res.pan,
      fssai: res.fssai,
      isAutoInvoice: res.isAutoInvoice,
    );
  }

  void setGstin(String val) {
    state = state.copyWith(gstin: val.trim().toUpperCase());
  }

  void setPan(String val) {
    state = state.copyWith(pan: val.trim().toUpperCase());
  }

  void setFssai(String val) {
    state = state.copyWith(fssai: val.trim());
  }

  void setAutoInvoice(bool val) {
    state = state.copyWith(isAutoInvoice: val);
  }

  Future<({bool success, String message})> saveLicence() async {
    final gstin = state.gstin.trim();
    if (gstin.isNotEmpty && gstin.length < 15) {
      return (
        success: false,
        message: 'GSTIN must be 15 characters length.'
      );
    }

    final pan = state.pan.trim();
    if (pan.isNotEmpty && pan.length < 10) {
      return (
        success: false,
        message: 'PAN must be 10 characters length.'
      );
    }

    final fssai = state.fssai.trim();
    if (fssai.isNotEmpty && fssai.length < 14) {
      return (
        success: false,
        message: 'fssai must be 14 digits length.'
      );
    }

    state = state.copyWith(isSaving: true, errorMessage: null);

    final res = await _repo.saveLicenceDetails(
      shopId: _store.id,
      gstin: gstin,
      pan: pan,
      fssai: fssai,
      isAutoInvoice: state.isAutoInvoice,
    );

    if (!mounted) return (success: false, message: '');
    state = state.copyWith(isSaving: false);

    if (res.success) {
      state = state.copyWith(successMessage: res.message);
    } else {
      state = state.copyWith(errorMessage: res.message);
    }

    return (success: res.success, message: res.message);
  }
}
