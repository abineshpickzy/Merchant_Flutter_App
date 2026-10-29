import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayfay_merchant_flutter/features/dashboard/model/store_model.dart';
import '../model/configure_shop_ui_model.dart';
import '../repository/configure_shop_ui_repository.dart';

final configureShopUiControllerProvider = StateNotifierProvider.autoDispose
    .family<ConfigureShopUiController, ConfigureShopUiState, StoreModel>(
  (ref, store) {
    final repo = ref.read(configureShopUiRepositoryProvider);
    return ConfigureShopUiController(repo: repo, store: store);
  },
);

class ConfigureShopUiController extends StateNotifier<ConfigureShopUiState> {
  final ConfigureShopUiRepository _repo;
  final StoreModel _store;

  ConfigureShopUiController({
    required ConfigureShopUiRepository repo,
    required StoreModel store,
  })  : _repo = repo,
        _store = store,
        super(const ConfigureShopUiState()) {
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final res = await _repo.getFrameList(
      shopId: _store.id,
      categoryId: _store.categoryId,
    );

    if (!mounted) return;

    if (res == null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load UI frame configuration',
      );
      return;
    }

    state = state.copyWith(
      isLoading: false,
      frameTypes: res.frameTypes,
      selectedFrameId: res.selectedFrameId != 0
          ? res.selectedFrameId
          : (res.frameTypes.isNotEmpty ? res.frameTypes.first.id : 0),
    );
  }

  void selectFrame(int frameId) {
    state = state.copyWith(selectedFrameId: frameId);
  }

  Future<({bool success, String message})> saveConfiguration() async {
    state = state.copyWith(isSaving: true, errorMessage: null);

    final res = await _repo.saveFrame(
      shopId: _store.id,
      categoryId: _store.categoryId,
      frameId: state.selectedFrameId,
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
