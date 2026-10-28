class StoreMessageItem {
  final String id;
  final String orderId;
  final String storeId;
  final String categoryId;
  final String customerName;
  final String date;
  final int badgeCount;
  final String lastMessage;

  const StoreMessageItem({
    this.id = '',
    this.orderId = '',
    this.storeId = '',
    this.categoryId = '',
    this.customerName = '',
    this.date = '',
    this.badgeCount = 0,
    this.lastMessage = '',
  });

  factory StoreMessageItem.fromJson(Map<String, dynamic> json) {
    return StoreMessageItem(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      orderId: (json['order_id'] ?? json['orderId'] ?? '').toString(),
      storeId: (json['store_id'] ?? '').toString(),
      categoryId: (json['category_id'] ?? '').toString(),
      customerName: (json['customer_name'] ?? json['customerName'] ?? 'Customer').toString(),
      date: (json['date'] ?? '').toString(),
      badgeCount: (json['badge'] as num?)?.toInt() ?? 0,
      lastMessage: (json['last_message'] ?? json['message'] ?? '').toString(),
    );
  }
}

class StoreMessagesState {
  final bool isLoading;
  final List<StoreMessageItem> messages;
  final String? errorMessage;

  const StoreMessagesState({
    this.isLoading = false,
    this.messages = const [],
    this.errorMessage,
  });

  StoreMessagesState copyWith({
    bool? isLoading,
    List<StoreMessageItem>? messages,
    String? errorMessage,
    bool clearError = false,
  }) {
    return StoreMessagesState(
      isLoading: isLoading ?? this.isLoading,
      messages: messages ?? this.messages,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
