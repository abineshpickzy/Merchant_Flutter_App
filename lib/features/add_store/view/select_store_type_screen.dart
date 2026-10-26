import 'package:flutter/material.dart';
import '../../../core/constants/app_strings.dart';
import 'add_store_form_screen.dart';
import '../controller/add_store_controller.dart';
import 'wholesale_buyer_profile_screen.dart';

/// Store type selection screen — mirrors Android's `SelectStoreType` activity
/// and `create_digital_store_home_layout.xml`.
class SelectStoreTypeScreen extends StatelessWidget {
  const SelectStoreTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          AppStrings.createDigitalStore,
          style: TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE0E0E0)),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                AppStrings.selectStoreType,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF212121),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                AppStrings.chooseStoreTypeSubtitle,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),

              // Grid of 4 store type cards
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.05,
                  children: [
                    _StoreTypeCard(
                      label: AppStrings.b2cRetail,
                      subtitle: AppStrings.b2cRetailSubtitle,
                      icon: Icons.storefront_outlined,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF42A5F5), Color(0xFF1976D2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      onTap: () => _openForm(context, storeKind: 0, storeFlow: StoreFlow.b2c),
                    ),
                    _StoreTypeCard(
                      label: AppStrings.d2c,
                      subtitle: AppStrings.d2cSubtitle,
                      icon: Icons.local_shipping_outlined,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF66BB6A), Color(0xFF388E3C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      onTap: () => _openForm(context, storeKind: 4, storeFlow: StoreFlow.d2c),
                    ),
                    _StoreTypeCard(
                      label: AppStrings.b2bWholesale,
                      subtitle: AppStrings.b2bWholesaleSubtitle,
                      icon: Icons.warehouse_outlined,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF7043), Color(0xFFE64A19)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      onTap: () => _openForm(context, storeKind: 1, storeFlow: StoreFlow.wholesale),
                    ),
                    _StoreTypeCard(
                      label: AppStrings.buyFromWholesale,
                      subtitle: AppStrings.buyFromWholesaleSubtitle,
                      icon: Icons.shopping_cart_outlined,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFAB47BC), Color(0xFF7B1FA2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      onTap: () => _openWholesaleBuyer(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openForm(BuildContext context, {required int storeKind, StoreFlow? storeFlow}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddStoreFormScreen(storeKind: storeKind, storeFlow: storeFlow),
      ),
    );
  }

  void _openWholesaleBuyer(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const WholesaleBuyerProfileScreen(),
      ),
    );
  }
}

// ── Store Type Card ──────────────────────────────────────────────────────────

class _StoreTypeCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _StoreTypeCard({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withAlpha(76),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.white, size: 32),
              const Spacer(),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withAlpha(200),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
