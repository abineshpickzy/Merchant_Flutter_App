import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayfay_merchant_flutter/features/dashboard/model/store_model.dart';
import '../model/shop_info_model.dart';
import '../repository/shop_info_repository.dart';

final shopInfoControllerProvider = StateNotifierProvider.autoDispose
    .family<ShopInfoController, ShopInfoState, StoreModel>((ref, store) {
  final repo = ref.read(shopInfoRepositoryProvider);
  return ShopInfoController(repo: repo, store: store);
});

class ShopInfoController extends StateNotifier<ShopInfoState> {
  final ShopInfoRepository _repo;
  final StoreModel _store;

  ShopInfoController({
    required ShopInfoRepository repo,
    required StoreModel store,
  })  : _repo = repo,
        _store = store,
        super(const ShopInfoState()) {
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final res = await _repo.getShopInfo(shopId: _store.id);

    if (res == null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load shop information',
      );
      return;
    }

    state = state.copyWith(
      isLoading: false,
      shopPhotos: res.shopPhotos,
      certificates: res.certificates,
      descriptions: res.descriptions,
      videoUrls: res.videoUrls,
    );
  }

  void addShopPhoto(String photoPath) {
    if (photoPath.isNotEmpty) {
      final list = List<String>.from(state.shopPhotos)..add(photoPath);
      state = state.copyWith(shopPhotos: list);
    }
  }

  void removeShopPhoto(int index) {
    if (index >= 0 && index < state.shopPhotos.length) {
      final list = List<String>.from(state.shopPhotos)..removeAt(index);
      state = state.copyWith(shopPhotos: list);
    }
  }

  void addCertificate(String path) {
    if (path.isNotEmpty) {
      final list = List<String>.from(state.certificates)..add(path);
      state = state.copyWith(certificates: list);
    }
  }

  void removeCertificate(int index) {
    if (index >= 0 && index < state.certificates.length) {
      final list = List<String>.from(state.certificates)..removeAt(index);
      state = state.copyWith(certificates: list);
    }
  }

  void addDescription(String text) {
    final clean = text.trim();
    if (clean.isNotEmpty) {
      final list = List<String>.from(state.descriptions)..add(clean);
      state = state.copyWith(descriptions: list);
    }
  }

  void removeDescription(int index) {
    if (index >= 0 && index < state.descriptions.length) {
      final list = List<String>.from(state.descriptions)..removeAt(index);
      state = state.copyWith(descriptions: list);
    }
  }

  bool addVideoUrl(String url) {
    final clean = url.trim();
    if (clean.isEmpty) return false;

    // Check basic url pattern
    final uri = Uri.tryParse(clean);
    if (uri == null || (!uri.isAbsolute)) {
      return false;
    }

    final list = List<String>.from(state.videoUrls)..add(clean);
    state = state.copyWith(videoUrls: list);
    return true;
  }

  void removeVideoUrl(int index) {
    if (index >= 0 && index < state.videoUrls.length) {
      final list = List<String>.from(state.videoUrls)..removeAt(index);
      state = state.copyWith(videoUrls: list);
    }
  }

  Future<({bool success, String message})> saveShopInfo() async {
    state = state.copyWith(isSaving: true, errorMessage: null);

    final res = await _repo.saveShopInfo(
      shopId: _store.id,
      shopPhotos: state.shopPhotos,
      certificates: state.certificates,
      descriptions: state.descriptions,
      videoUrls: state.videoUrls,
    );

    state = state.copyWith(isSaving: false);

    if (res.success) {
      state = state.copyWith(successMessage: res.message);
    } else {
      state = state.copyWith(errorMessage: res.message);
    }

    return (success: res.success, message: res.message);
  }
}
