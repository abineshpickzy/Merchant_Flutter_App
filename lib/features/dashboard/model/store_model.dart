import 'package:equatable/equatable.dart';

class StoreModel extends Equatable {
  final String id;
  final String displayName;
  final String? categoryImage;
  final String? privateIcon;
  final String? categoryId;
  final bool isOpen;
  final int newOrderCount;
  final int status;
  final bool isWholeSale;
  final bool isExternal;
  final bool isRestaurant;
  final double rating;

  const StoreModel({
    required this.id,
    required this.displayName,
    this.categoryImage,
    this.privateIcon,
    this.categoryId,
    this.isOpen = true,
    this.newOrderCount = 0,
    this.status = 1,
    this.isWholeSale = false,
    this.isExternal = false,
    this.isRestaurant = false,
    this.rating = 0.0,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    double parseRating(dynamic r) {
      if (r == null) return 0.0;
      if (r is num) return r.toDouble();
      if (r is Map<String, dynamic>) {
        final avg = r['avg_rating'] ?? r['avg'] ?? r['rating'] ?? 0.0;
        if (avg is num) return avg.toDouble();
        return double.tryParse(avg.toString()) ?? 0.0;
      }
      return double.tryParse(r.toString()) ?? 0.0;
    }

    return StoreModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? json['name'] as String? ?? 'Store',
      categoryImage: json['category_image'] as String? ?? json['image'] as String?,
      privateIcon: json['private_icon'] as String?,
      categoryId: json['category_id'] as String?,
      isOpen: json['is_open'] as bool? ?? true,
      newOrderCount: (json['new_order_count'] as num?)?.toInt() ?? 0,
      status: (json['status'] as num?)?.toInt() ?? 1,
      isWholeSale: json['is_wholesale'] as bool? ?? false,
      isExternal: json['is_external'] as bool? ?? false,
      isRestaurant: json['is_restaurants'] as bool? ?? false,
      rating: parseRating(json['store_rating']),
    );
  }

  /// Computes the store image URL matching Android StoresListAdapter GlideUrl logic
  String getImageUrl(String baseUrl) {
    final file = (privateIcon != null && privateIcon!.isNotEmpty)
        ? privateIcon
        : categoryImage;
    if (file == null || file.isEmpty) return '';

    // Return absolute URLs directly if file is already a full http/https URL
    if (file.startsWith('http://') || file.startsWith('https://')) {
      return file;
    }

    // Ensure baseUrl ends with '/'
    final normalizedBaseUrl = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';

    // final openParam = isOpen ? '' : '&is_open=false';
    final dims = isOpen ? 'width=200&height=200' : 'width=300&height=300';
    return '${normalizedBaseUrl}merchant/category/image?file=$file&$dims';
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'display_name': displayName,
      'category_image': categoryImage,
      'private_icon': privateIcon,
      'category_id': categoryId,
      'is_open': isOpen,
      'new_order_count': newOrderCount,
      'status': status,
      'is_wholesale': isWholeSale,
      'is_external': isExternal,
      'is_restaurants': isRestaurant,
      'store_rating': {'avg_rating': rating},
    };
  }

  StoreModel copyWith({
    String? id,
    String? displayName,
    String? categoryImage,
    String? privateIcon,
    String? categoryId,
    bool? isOpen,
    int? newOrderCount,
    int? status,
    bool? isWholeSale,
    bool? isExternal,
    bool? isRestaurant,
    double? rating,
  }) {
    return StoreModel(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      categoryImage: categoryImage ?? this.categoryImage,
      privateIcon: privateIcon ?? this.privateIcon,
      categoryId: categoryId ?? this.categoryId,
      isOpen: isOpen ?? this.isOpen,
      newOrderCount: newOrderCount ?? this.newOrderCount,
      status: status ?? this.status,
      isWholeSale: isWholeSale ?? this.isWholeSale,
      isExternal: isExternal ?? this.isExternal,
      isRestaurant: isRestaurant ?? this.isRestaurant,
      rating: rating ?? this.rating,
    );
  }

  @override
  List<Object?> get props => [
        id,
        displayName,
        categoryImage,
        privateIcon,
        categoryId,
        isOpen,
        newOrderCount,
        status,
        isWholeSale,
        isExternal,
        isRestaurant,
        rating,
      ];
}
