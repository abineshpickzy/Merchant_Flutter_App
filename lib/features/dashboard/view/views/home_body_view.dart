import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayfay_merchant_flutter/app/theme/app_colors.dart';
import '../../controller/dashboard_controller.dart';
import '../../model/metric_models.dart';
import '../../model/store_model.dart';
import 'package:bayfay_merchant_flutter/core/widgets/app_button.dart';
import '../widgets/home_skeleton_loader.dart';
import '../widgets/store_card.dart';

/// 1:1 Parity implementation of legacy Android fragment_home.xml
/// Displays the 3 top feature gradient cards, promotional scratch card banner,
/// and 3-column categorized store grid ("My Stores", "External Shops", "Wholesale Shops").
class HomeBodyView extends ConsumerStatefulWidget {
  const HomeBodyView({super.key});

  @override
  ConsumerState<HomeBodyView> createState() => _HomeBodyViewState();
}

class _HomeBodyViewState extends ConsumerState<HomeBodyView> {
  bool _showGuaranteedOrder = true;
  StoreModel? _selectedPromotionStore;

  Widget _buildSkeletonBox({
    required double width,
    required double height,
    double radius = 3,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  void _showBusinessValueDialog(
    BuildContext context,
    BusinessValueModel? businessValue,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Business Value',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF2B2B2B),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Value: ₹ ${businessValue?.businessValue ?? 0}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Customer / Lead Count: ${businessValue?.customersCount ?? 0}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'The business value projected here is based upon the transaction over the past 12 months. '
              'Every new user ₹800 will be added in your business value, share the shop link to your customers and increase the business value. Coming soon full feature update.',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Color(0xFF555555),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'OK',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSalesAnalyticsDialog(
    BuildContext context,
    PartnerInfoModel? partnerInfo,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Sales Analytics & Agency',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF2B2B2B),
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sales Turnover Overview:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '• Annual Turnover: ₹ ${partnerInfo?.annualTurnover ?? 0}',
                style: const TextStyle(fontSize: 13, color: Color(0xFF555555)),
              ),
              const SizedBox(height: 4),
              Text(
                '• Last 30 Days: ₹ ${partnerInfo?.last30DaysTurnover ?? 0}',
                style: const TextStyle(fontSize: 13, color: Color(0xFF555555)),
              ),
              if (partnerInfo != null && partnerInfo.agencyInfo.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Agency Privileges:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 4),
                ...partnerInfo.agencyInfo.map(
                  (info) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      '• $info',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF666666)),
                    ),
                  ),
                ),
              ],
              if (partnerInfo?.note != null &&
                  partnerInfo!.note!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  partnerInfo.note!,
                  style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF757575)),
                ),
              ],
              const SizedBox(height: 12),
              const Text(
                'Activate merchant agency to unlock multi-store management, dedicated support, and turnover bonuses.',
                style: TextStyle(
                    fontSize: 12, height: 1.4, color: Color(0xFF757575)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storesAsync = ref.watch(storesProvider);
    final allStores = storesAsync.valueOrNull ?? const [];

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(storesProvider.notifier).refreshStores();
        ref.invalidate(notificationCountProvider);
        ref.invalidate(businessValueProvider);
        ref.invalidate(partnerInfoProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top 3 Feature Gradient Cards (matching @id/header_lay)
            _buildHeaderCardsRow(context),

            const SizedBox(height: 10),

            // Guaranteed More Orders Card (matching @id/guranteed_layout)
            if (_showGuaranteedOrder && allStores.isNotEmpty)
              _buildGuaranteedOrderCard(allStores),

            const SizedBox(height: 6),

            // Isolated Categorized Stores Grid Section
            _buildStoresSection(storesAsync),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// Isolated stores section builder rendering store grid or isolated loading state
  Widget _buildStoresSection(AsyncValue<List<StoreModel>> storesAsync) {
    return storesAsync.when(
      data: (allStores) {
        // Categorize stores matching legacy Android HomeFragment & ShopsHeaderAdapter
        final myStores = allStores
            .where((s) => !s.isExternal && !s.isWholeSale)
            .toList();
        final externalStores =
            allStores.where((s) => s.isExternal).toList();
        final wholesaleStores =
            allStores.where((s) => s.isWholeSale).toList();

        final sections = <String, List<StoreModel>>{
          'My Stores': myStores,
          'External Shops': externalStores,
          'Wholesale Shops': wholesaleStores,
        };

        if (allStores.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 80.0),
            alignment: Alignment.center,
            child: const Text(
              'No Stores Available',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF666666),
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: sections.entries.map((entry) {
            final title = entry.key;
            final storeList = entry.value;

            if (storeList.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 4.0,
                        top: 12.0,
                        bottom: 8.0,
                      ),
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2B2B2B),
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        for (var i = 0; i < storeList.length; i += 3)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  for (var j = i; j < i + 3; j++) ...[
                                    if (j > i) const SizedBox(width: 6),
                                    Expanded(
                                      child:
                                          j < storeList.length
                                              ? StoreCard(
                                                store: storeList[j],
                                                onTap:
                                                    () =>
                                                        StoreCard.handleStoreTap(
                                                          context,
                                                          ref,
                                                          storeList[j],
                                                        ),
                                              )
                                              : const SizedBox.shrink(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              }).toList(),
        );
      },
      loading: () => const StoresSectionSkeletonLoader(),
      error: (err, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.error,
              ),
              const SizedBox(height: 12),
              Text(
                err.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.error),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.read(storesProvider.notifier).refreshStores(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Top 3 Feature Gradient Cards Row matching @id/header_lay
  Widget _buildHeaderCardsRow(BuildContext context) {
    final businessValueAsync = ref.watch(businessValueProvider);
    final partnerInfoAsync = ref.watch(partnerInfoProvider);

    return SizedBox(
      height: 125,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card 1: Buy From Wholesale Stores (gredient_bg_s1: #EC1F64 to #FF9800)
          Expanded(
            child: _buildGradientCard(
              gradientColors: const [Color(0xFFEC1F64), Color(0xFFFF9800)],
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Wholesale Stores Hub'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(
                      Icons.storefront_rounded,
                      size: 28,
                      color: Colors.white,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Buy From',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Wholesale Stores',
                                maxLines: 2,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  height: 1.15,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Card 2: Business Value (gredient_bg_s2: #9C27B0 to #2196F3)
          Expanded(
            child: _buildGradientCard(
              gradientColors: const [Color(0xFF9C27B0), Color(0xFF2196F3)],
              onTap: () => _showBusinessValueDialog(
                  context, businessValueAsync.valueOrNull),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(
                      Icons.dashboard_rounded,
                      size: 28,
                      color: Colors.white,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Business value',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(
                              Icons.people_alt_rounded,
                              size: 13,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            businessValueAsync.isLoading
                                ? _buildSkeletonBox(width: 24, height: 12)
                                : Text(
                                    '${businessValueAsync.valueOrNull?.customersCount ?? 0}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Nunito',
                                    ),
                                  ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Expanded(
                              child: businessValueAsync.isLoading
                                  ? _buildSkeletonBox(width: 48, height: 14)
                                  : Text(
                                      '₹ ${businessValueAsync.valueOrNull?.businessValue ?? 0}',
                                      maxLines: 1,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Card 3: Sales Analytics (matching Android @id/session_3 / @id/agency_stats_lay)
          Expanded(
            child: _buildGradientCard(
              gradientColors: const [Color(0xFF0275D8), Color(0xFF2196F3)],
              onTap: () =>
                  _showSalesAnalyticsDialog(context, partnerInfoAsync.valueOrNull),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 4.0, vertical: 6.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Last 1 Year',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontFamily: 'ProductSans',
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 2),
                        partnerInfoAsync.isLoading
                            ? _buildSkeletonBox(width: 44, height: 13)
                            : Text(
                                '₹ ${partnerInfoAsync.valueOrNull?.annualTurnover ?? 0}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontFamily: 'ProductSans',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ],
                    ),
                    const Divider(
                        color: Colors.white24, height: 6, thickness: 0.8),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Last 30 Days',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontFamily: 'ProductSans',
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 2),
                        partnerInfoAsync.isLoading
                            ? _buildSkeletonBox(width: 44, height: 13)
                            : Text(
                                '₹ ${partnerInfoAsync.valueOrNull?.last30DaysTurnover ?? 0}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontFamily: 'ProductSans',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientCard({
    required List<Color> gradientColors,
    required Widget child,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: gradientColors,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  /// Guaranteed More Orders Card matching @id/guranteed_layout
  Widget _buildGuaranteedOrderCard(List<StoreModel> allStores) {
    if (_selectedPromotionStore == null ||
        !allStores.any((s) => s.id == _selectedPromotionStore!.id)) {
      _selectedPromotionStore = allStores.isNotEmpty ? allStores.first : null;
    }

    return Card(
      elevation: 1.5,
      shadowColor: const Color(0x1F000000),
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(
          color: Color(0xFFE9ECEF),
          width: 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Top Row: Image on Left, Promo Details on Right
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Scratch Card / Promotion Circular Badge Icon with yellow/gold ring & green checkmark
                Image.asset(
                  'assets/images/ic_guranteed_tick.png',
                  width: 56,
                  height: 56,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFDE7),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFFC107), // yellow/gold outer ring
                        width: 3,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.check_rounded,
                        size: 32,
                        color: Color(0xFF1EA838), // green checkmark icon
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Right content details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Guaranteed More Orders',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF212529),
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Enable scratch card Promotion now.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF495057),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'The scratch card promo appears first when customer open the app.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6C757D),
                          height: 1.25,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'The promo applies only if the customer scratched your promo code.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6C757D),
                          height: 1.25,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        '20 % Discount above purchase limit ₹ 199',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1EA838),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Bottom Action Row: Store Selector Dropdown on Left (under image) & Pill Action Buttons on Right
            Row(
              children: [
                // Store Selector Dropdown on the Left (positioned below the image section): Light gray pill-shaped button (#EFF2F5)
                Expanded(
                  child: Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF2F5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFDEE2E6),
                        width: 0.8,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<StoreModel>(
                        isExpanded: true,
                        value: _selectedPromotionStore,
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Color(0xFF6C757D),
                          size: 18,
                        ),
                        items: allStores.map((store) {
                          return DropdownMenuItem<StoreModel>(
                            value: store,
                            child: Text(
                              store.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF333333),
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (newStore) {
                          if (newStore != null) {
                            setState(() {
                              _selectedPromotionStore = newStore;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Later Button: Fully rounded pill-shaped curved design (#8F9AA3)
                PillActionButton(
                  label: 'Later',
                  backgroundColor: const Color(0xFF8F9AA3),
                  textColor: Colors.white,
                  fontWeight: FontWeight.w600,
                  onPressed: () {
                    setState(() {
                      _showGuaranteedOrder = false;
                    });
                  },
                ),
                const SizedBox(width: 6),

                // Activate Button: Fully rounded pill-shaped curved design (#1EA838)
                PillActionButton(
                  label: 'Activate',
                  backgroundColor: const Color(0xFF1EA838),
                  textColor: Colors.white,
                  fontWeight: FontWeight.bold,
                  onPressed: () {
                    setState(() {
                      _showGuaranteedOrder = false;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Scratch card promotion activated for ${_selectedPromotionStore?.displayName ?? "store"}!',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
