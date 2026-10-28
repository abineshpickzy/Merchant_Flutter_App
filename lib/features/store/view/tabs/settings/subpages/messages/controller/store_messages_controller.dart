import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayfay_merchant_flutter/features/dashboard/model/store_model.dart';
import '../model/store_messages_model.dart';
import '../repository/store_messages_repository.dart';

final storeMessagesControllerProvider = StateNotifierProvider.autoDispose
    .family<StoreMessagesController, StoreMessagesState, StoreModel>((ref, store) {
  final repository = ref.read(storeMessagesRepositoryProvider);
  return StoreMessagesController(repository, store);
});

class StoreMessagesController extends StateNotifier<StoreMessagesState> {
  final StoreMessagesRepository _repository;
  final StoreModel store;

  StoreMessagesController(this._repository, this.store)
      : super(const StoreMessagesState(isLoading: true)) {
    loadMessages();
  }

  Future<void> loadMessages({bool isRefresh = false}) async {
    state = state.copyWith(isLoading: !isRefresh, clearError: true);
    try {
      final messages = await _repository.getChatList(storeId: store.id);
      if (!mounted) return;
      state = state.copyWith(isLoading: false, messages: messages);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load messages: $e',
      );
    }
  }
}
