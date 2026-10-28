// Model for Configure Shop UI (1:1 with Android SettingFrameResponse & SettingConfigureUiFragment)

class ShopFrameType {
  final int id;
  final String name;

  const ShopFrameType({required this.id, required this.name});

  factory ShopFrameType.fromJson(Map<String, dynamic> json) {
    return ShopFrameType(
      id: (json['_id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
    );
  }
}

class ConfigureShopUiState {
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;
  final List<ShopFrameType> frameTypes;
  final int selectedFrameId;

  const ConfigureShopUiState({
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
    this.frameTypes = const [],
    this.selectedFrameId = 0,
  });

  ConfigureShopUiState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
    List<ShopFrameType>? frameTypes,
    int? selectedFrameId,
  }) {
    return ConfigureShopUiState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
      successMessage: successMessage,
      frameTypes: frameTypes ?? this.frameTypes,
      selectedFrameId: selectedFrameId ?? this.selectedFrameId,
    );
  }
}
