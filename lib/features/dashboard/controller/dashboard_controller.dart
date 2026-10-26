import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayfay_merchant_flutter/core/providers/location_service_provider.dart';
import 'package:bayfay_merchant_flutter/core/storage/local_storage_service.dart';
import 'package:bayfay_merchant_flutter/core/storage/secure_storage_service.dart';
import '../model/metric_models.dart';
import '../model/store_model.dart';
import '../repository/dashboard_repository.dart';

/// Authorization headers provider for fetching secure store category images
final authHeaderProvider =
    AutoDisposeFutureProvider<Map<String, String>>((ref) async {
  try {
    final storage = ref.read(secureStorageServiceProvider);
    final token = await storage.getAccessToken();
    final schema = await storage.getAccessSchema();
    if (token != null && token.isNotEmpty) {
      return {'Authorization': '$schema $token'};
    }
  } catch (_) {
    // Graceful fallback for widget tests or unauthenticated storage reads
  }
  return const {};
});

/// Active bottom navigation tab index (0: Stores, 1: Orders, 2: Inventory, 3: Account)
final dashboardIndexProvider = StateProvider<int>((ref) => 0);

/// Store category filter ('All', 'Retail', 'Wholesale')
final storeFilterProvider = StateProvider<String>((ref) => 'All');

/// Store text search query
final storeSearchQueryProvider = StateProvider<String>((ref) => '');

/// Unread notification count provider (matching HomeActivity.getNotificationCount)
final notificationCountProvider = AutoDisposeFutureProvider<int>((ref) async {
  final repository = ref.read(dashboardRepositoryProvider);
  return repository.fetchNotificationCount();
});

/// Business value metrics provider (API-078: POST merchant/business/value)
final businessValueProvider =
    AutoDisposeFutureProvider<BusinessValueModel>((ref) async {
  final repository = ref.read(dashboardRepositoryProvider);
  final location = ref.watch(locationServiceProvider);
  return repository.fetchBusinessValue(
    latitude: location.currentPosition?.latitude,
    longitude: location.currentPosition?.longitude,
  );
});

/// Partner / Sales analytics metrics provider (API-077: POST merchant/partner/info)
final partnerInfoProvider =
    AutoDisposeFutureProvider<PartnerInfoModel>((ref) async {
  final repository = ref.read(dashboardRepositoryProvider);
  final location = ref.watch(locationServiceProvider);
  return repository.fetchPartnerInfo(
    latitude: location.currentPosition?.latitude,
    longitude: location.currentPosition?.longitude,
  );
});

/// List of merchant stores provider
final storesProvider =
    AutoDisposeAsyncNotifierProvider<StoresNotifier, List<StoreModel>>(() {
  return StoresNotifier();
});

/// Alias provider for targeted dashboard stores controller access
final dashboardControllerProvider = storesProvider;

class StoresNotifier extends AutoDisposeAsyncNotifier<List<StoreModel>> {
  @override
  FutureOr<List<StoreModel>> build() async {
    final repository = ref.read(dashboardRepositoryProvider);
    final stores = await repository.fetchStores();

    // Auto-select initial store if none is currently selected
    final currentSelected = ref.read(selectedStoreProvider);
    if (currentSelected == null && stores.isNotEmpty) {
      ref.read(selectedStoreProvider.notifier).selectStore(stores.first);
    }

    return stores;
  }

  Future<void> refreshStores() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(dashboardRepositoryProvider);
      final stores = await repository.fetchStores();

      final currentSelected = ref.read(selectedStoreProvider);
      if (stores.isNotEmpty) {
        if (currentSelected == null ||
            !stores.any((s) => s.id == currentSelected.id)) {
          ref.read(selectedStoreProvider.notifier).selectStore(stores.first);
        }
      }
      return stores;
    });
  }

  /// Targeted refresh method for merchant stores section only
  Future<void> fetchMerchantStores() => refreshStores();
  Future<void> refreshStoresOnly() => refreshStores();
}

/// Currently active / selected store notifier
final selectedStoreProvider =
    NotifierProvider<SelectedStoreNotifier, StoreModel?>(() {
  return SelectedStoreNotifier();
});

class SelectedStoreNotifier extends Notifier<StoreModel?> {
  static const String _storageKey = 'selected_merchant_store';

  @override
  StoreModel? build() {
    _loadPersistedStore();
    return null;
  }

  Future<void> _loadPersistedStore() async {
    try {
      final localStorage = ref.read(localStorageServiceProvider);
      final raw = localStorage.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        state = StoreModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      }
    } catch (_) {}
  }

  void selectStore(StoreModel store) {
    state = store;
    try {
      final localStorage = ref.read(localStorageServiceProvider);
      localStorage.setString(_storageKey, jsonEncode(store.toJson()));
    } catch (_) {}
  }
}

/// Filtered and searched stores list provider
final filteredStoresProvider = Provider.autoDispose<List<StoreModel>>((ref) {
  final storesAsync = ref.watch(storesProvider);
  final filter = ref.watch(storeFilterProvider);
  final query = ref.watch(storeSearchQueryProvider).toLowerCase().trim();

  return storesAsync.maybeWhen(
    data: (stores) {
      return stores.where((store) {
        // Category filter
        if (filter == 'Retail' && store.isWholeSale) return false;
        if (filter == 'Wholesale' && !store.isWholeSale) return false;

        // Search query
        if (query.isNotEmpty) {
          final matchesName = store.displayName.toLowerCase().contains(query);
          return matchesName;
        }

        return true;
      }).toList();
    },
    orElse: () => const [],
  );
});
