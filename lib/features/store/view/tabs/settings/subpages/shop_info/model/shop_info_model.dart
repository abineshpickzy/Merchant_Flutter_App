// Model for Shop Info (1:1 with Android shopInfoView & ShopInfoFragment)

class ShopInfoData {
  final List<String> shopPhotos;
  final List<String> certificates;
  final List<String> descriptions;
  final List<String> videoUrls;

  const ShopInfoData({
    this.shopPhotos = const [],
    this.certificates = const [],
    this.descriptions = const [],
    this.videoUrls = const [],
  });

  factory ShopInfoData.fromJson(Map<String, dynamic> json) {
    final about = json['about_shop'] as Map<String, dynamic>? ?? json;

    List<String> parseList(dynamic raw) {
      if (raw is List) {
        return raw.map((e) => e.toString()).toList();
      }
      return const [];
    }

    return ShopInfoData(
      shopPhotos: parseList(about['shop_photo']),
      certificates: parseList(about['certificate']),
      descriptions: parseList(about['description']),
      videoUrls: parseList(about['video_url']),
    );
  }
}

class ShopInfoState {
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;
  final List<String> shopPhotos;
  final List<String> certificates;
  final List<String> descriptions;
  final List<String> videoUrls;

  const ShopInfoState({
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
    this.shopPhotos = const [],
    this.certificates = const [],
    this.descriptions = const [],
    this.videoUrls = const [],
  });

  ShopInfoState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
    List<String>? shopPhotos,
    List<String>? certificates,
    List<String>? descriptions,
    List<String>? videoUrls,
  }) {
    return ShopInfoState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
      successMessage: successMessage,
      shopPhotos: shopPhotos ?? this.shopPhotos,
      certificates: certificates ?? this.certificates,
      descriptions: descriptions ?? this.descriptions,
      videoUrls: videoUrls ?? this.videoUrls,
    );
  }
}
