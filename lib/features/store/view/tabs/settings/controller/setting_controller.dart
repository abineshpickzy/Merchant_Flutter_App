import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayfay_merchant_flutter/features/dashboard/model/store_model.dart';
import '../model/setting_model.dart';
import '../repository/setting_repository.dart';

final settingControllerProvider = StateNotifierProvider.autoDispose
    .family<SettingController, SettingState, StoreModel>((ref, store) {
  final repository = ref.read(settingRepositoryProvider);
  return SettingController(repository, store);
});

class SettingController extends StateNotifier<SettingState> {
  final SettingRepository _repository;
  final StoreModel store;

  SettingController(this._repository, this.store)
      : super(const SettingState(isLoading: true)) {
    loadSettings();
  }

  /// Load basic settings from backend
  Future<void> loadSettings() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final categoryId = store.categoryId ?? '';
      final data = await _repository.getSettingBasic(
        shopId: store.id,
        categoryId: categoryId,
      );

      if (!mounted) return;

      if (data != null) {
        state = state.copyWith(isLoading: false, data: data);
      } else {
        // Fallback to current store model if API returns null/empty
        final fallback = SettingData(
          id: store.id,
          displayName: store.displayName,
          categoryName: store.displayName,
          categoryType: store.displayName,
          categoryImage: store.categoryImage ?? store.privateIcon ?? '',
          isOpen: store.isOpen,
          isBusy: false,
          shopStatus: 3,
        );
        state = state.copyWith(isLoading: false, data: fallback);
      }
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load settings: $e',
      );
    }
  }

  /// Toggle Shop Open/Close
  Future<bool> setShopOpen(bool isOpen) async {
    state = state.copyWith(isUpdating: true, clearError: true, clearSuccess: true);
    final previousData = state.data;

    // Optimistically update
    if (state.data != null) {
      state = state.copyWith(data: state.data!.copyWith(isOpen: isOpen));
    }

    final categoryId = store.categoryId ?? '';
    final result = await _repository.updateSetting(
      SettingUpdateRequest(
        categoryId: categoryId,
        shopId: store.id,
        isOpen: isOpen,
        privateIsOpen: isOpen,
      ),
    );

    if (!mounted) return false;
    state = state.copyWith(isUpdating: false);

    if (result.success) {
      state = state.copyWith(successMessage: result.message);
      await loadSettings();
      return true;
    } else {
      // Revert on failure
      state = state.copyWith(data: previousData, errorMessage: result.message);
      return false;
    }
  }

  /// Toggle Busy Status
  Future<bool> setShopBusy(bool isBusy) async {
    state = state.copyWith(isUpdating: true, clearError: true, clearSuccess: true);
    final previousData = state.data;

    // Optimistically update
    if (state.data != null) {
      state = state.copyWith(data: state.data!.copyWith(isBusy: isBusy));
    }

    final categoryId = store.categoryId ?? '';
    final result = await _repository.updateSetting(
      SettingUpdateRequest(
        categoryId: categoryId,
        shopId: store.id,
        isBusy: isBusy,
      ),
    );

    if (!mounted) return false;
    state = state.copyWith(isUpdating: false);

    if (result.success) {
      state = state.copyWith(successMessage: result.message);
      await loadSettings();
      return true;
    } else {
      // Revert on failure
      state = state.copyWith(data: previousData, errorMessage: result.message);
      return false;
    }
  }

  /// Toggle Private Shop Open/Close
  Future<bool> setPrivateShopOpen(bool isOpen) async {
    state = state.copyWith(isUpdating: true, clearError: true, clearSuccess: true);
    final previousData = state.data;

    // Optimistically update
    if (state.data?.privateShop != null) {
      final updatedPrivate = state.data!.privateShop!.copyWith(isOpen: isOpen);
      state = state.copyWith(data: state.data!.copyWith(privateShop: updatedPrivate));
    }

    final categoryId = store.categoryId ?? '';
    final result = await _repository.updateSetting(
      SettingUpdateRequest(
        categoryId: categoryId,
        shopId: store.id,
        privateIsOpen: isOpen,
      ),
    );

    if (!mounted) return false;
    state = state.copyWith(isUpdating: false);

    if (result.success) {
      state = state.copyWith(successMessage: result.message);
      await loadSettings();
      return true;
    } else {
      // Revert on failure
      state = state.copyWith(data: previousData, errorMessage: result.message);
      return false;
    }
  }

  /// Detach Shop
  Future<({bool success, String message})> detachShop() async {
    state = state.copyWith(isUpdating: true);
    final result = await _repository.detachShop(shopId: store.id);
    if (!mounted) return result;
    state = state.copyWith(isUpdating: false);
    return result;
  }
}
