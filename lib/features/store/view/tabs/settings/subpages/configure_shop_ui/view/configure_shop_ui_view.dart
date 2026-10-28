import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayfay_merchant_flutter/features/dashboard/model/store_model.dart';
import 'package:bayfay_merchant_flutter/features/store/view/widgets/store_tab_app_bar.dart';
import '../controller/configure_shop_ui_controller.dart';
import '../model/configure_shop_ui_model.dart';

class ConfigureShopUiView extends ConsumerWidget {
  final StoreModel store;

  const ConfigureShopUiView({super.key, required this.store});

  Future<void> _handleSave(
    BuildContext context,
    ConfigureShopUiController controller,
  ) async {
    final res = await controller.saveConfiguration();
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res.message),
        backgroundColor: res.success ? Colors.green : Colors.red,
      ),
    );

    if (res.success) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(configureShopUiControllerProvider(store));
    final controller =
        ref.read(configureShopUiControllerProvider(store).notifier);

    final isBusy = state.isLoading || state.isSaving;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: StoreTabAppBar(
        title: '${store.displayName} - Shop UI',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF616161)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        trailing: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: SizedBox(
            width: 76,
            height: 36,
            child: ElevatedButton(
              onPressed:
                  isBusy ? null : () => _handleSave(context, controller),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                elevation: 0,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: state.isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          if (isBusy)
            const LinearProgressIndicator(
              minHeight: 2.5,
              backgroundColor: Color(0xFFE3F2FD),
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF297BFE)),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Shop Presentation Frame:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Choose the layout structure that will be presented to your buyers in the Bayfay customer app.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 14),

                  // Spinner matching configure_spinner
                  Container(
                    height: 44,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: state.frameTypes
                                .any((f) => f.id == state.selectedFrameId)
                            ? state.selectedFrameId
                            : (state.frameTypes.isNotEmpty
                                ? state.frameTypes.first.id
                                : null),
                        isExpanded: true,
                        items: state.frameTypes
                            .map((f) => DropdownMenuItem<int>(
                                  value: f.id,
                                  child: Text(
                                    f.name,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            controller.selectFrame(val);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // UI Preview / Illustration Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.dashboard_customize_outlined,
                          size: 48,
                          color: Color(0xFF2196F3),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          state.frameTypes
                                  .firstWhere(
                                    (f) => f.id == state.selectedFrameId,
                                    orElse: () =>
                                        const ShopFrameType(id: 0, name: 'Default Frame'),
                                  )
                                  .name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Active layout for your storefront. Changes reflect immediately for customers browsing your store products.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
