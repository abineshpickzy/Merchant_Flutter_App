import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayfay_merchant_flutter/core/network/api_client.dart';
import 'package:bayfay_merchant_flutter/core/network/api_endpoints.dart';
import '../model/additional_settings_model.dart';

final additionalSettingsRepositoryProvider =
    Provider<AdditionalSettingsRepository>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return AdditionalSettingsRepository(apiClient);
});

class AdditionalSettingsRepository {
  final ApiClient _apiClient;

  const AdditionalSettingsRepository(this._apiClient);

  /// Fetch initial settings matching Android callSettingDelivery (@POST "shop/view/delivery")
  Future<({
    double packagePrice,
    int pricingType,
    int? minLimit,
    bool agencyResponsibility,
    bool allowAutoOpenClose,
    bool isAutomatic,
    List<ShopTimingSlot> timingSlots,
  })?> getAdditionalSettings({
    required String shopId,
    required dynamic categoryId,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.shopViewDelivery,
        data: {
          'shop_id': shopId,
          'category_id': categoryId,
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true) {
        final innerData = data['data'];
        if (innerData is Map<String, dynamic>) {
          final delivery = innerData['delivery'] as Map<String, dynamic>? ?? {};
          final pkg = delivery['packaging_charge'] as Map<String, dynamic>? ?? {};
          final autoOpenClose = innerData['allow_auto_openclose'] == true;
          final timingRsp = innerData['shop_timing'] as Map<String, dynamic>? ?? {};
          final isAuto = timingRsp['is_automatic'] == true;
          final models = timingRsp['shoptiming_models'] as List<dynamic>?;

          final slots = <ShopTimingSlot>[];
          if (models != null) {
            for (final m in models) {
              if (m is Map<String, dynamic>) {
                slots.add(ShopTimingSlot(
                  startTime: m['start_time']?.toString() ?? '',
                  endTime: m['end_time']?.toString() ?? '',
                ));
              }
            }
          }

          return (
            packagePrice: (pkg['package_price'] as num?)?.toDouble() ?? 0.0,
            pricingType: (pkg['pricing_type'] as num?)?.toInt() ?? 2,
            minLimit: (pkg['min_limit'] as num?)?.toInt(),
            agencyResponsibility: pkg['agency_responsibility'] == true,
            allowAutoOpenClose: autoOpenClose,
            isAutomatic: isAuto,
            timingSlots: slots,
          );
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Save additional settings matching Android sendAdditionalSettingsData (@POST "shop/addSettings")
  Future<({bool success, String message})> saveAdditionalSettings({
    required String shopId,
    required dynamic categoryId,
    required double packagePrice,
    required int pricingType,
    required int? minLimit,
    required bool agencyResponsibility,
    required bool isAutomatic,
    required List<ShopTimingSlot> timingSlots,
  }) async {
    try {
      final packagingCharge = <String, dynamic>{
        'package_price': packagePrice,
        'pricing_type': pricingType,
        'agency_responsibility': agencyResponsibility,
      };
      if (minLimit != null) {
        packagingCharge['min_limit'] = minLimit;
      }

      final shopTiming = <String, dynamic>{
        'is_automatic': isAutomatic,
      };
      if (isAutomatic) {
        shopTiming['shop_open_close'] = timingSlots.map((s) => s.toJson()).toList();
      }

      final response = await _apiClient.post(
        ApiEndpoints.shopAddSettings,
        data: {
          'shop_id': shopId,
          'category_id': categoryId,
          'packaging_charge': packagingCharge,
          'shop_timing': shopTiming,
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final success = data['success'] == true;
        final message = data['message']?.toString() ??
            (success
                ? 'Additional settings saved successfully'
                : 'Failed to update additional settings');
        return (success: success, message: message);
      }
      return (success: false, message: 'Invalid response from server');
    } catch (e) {
      return (success: false, message: e.toString());
    }
  }
}
