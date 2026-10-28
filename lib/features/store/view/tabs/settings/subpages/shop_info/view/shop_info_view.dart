import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayfay_merchant_flutter/features/dashboard/model/store_model.dart';
import 'package:bayfay_merchant_flutter/features/store/view/widgets/store_tab_app_bar.dart';
import '../controller/shop_info_controller.dart';

class ShopInfoView extends ConsumerStatefulWidget {
  final StoreModel store;

  const ShopInfoView({super.key, required this.store});

  @override
  ConsumerState<ShopInfoView> createState() => _ShopInfoViewState();
}

class _ShopInfoViewState extends ConsumerState<ShopInfoView> {
  late TextEditingController _descController;
  late TextEditingController _videoUrlController;

  @override
  void initState() {
    super.initState();
    _descController = TextEditingController();
    _videoUrlController = TextEditingController();
  }

  @override
  void dispose() {
    _descController.dispose();
    _videoUrlController.dispose();
    super.dispose();
  }

  Future<void> _handleSave(ShopInfoController controller) async {
    final res = await controller.saveShopInfo();
    if (!mounted) return;

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

  void _showAddPhotoMockDialog(ShopInfoController controller, bool isCert) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isCert ? 'Add Certificate Image' : 'Add Shop Photo',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            hintText: 'Enter image URL or asset path',
            hintStyle: TextStyle(fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
            ),
            onPressed: () {
              final text = textController.text.trim();
              if (text.isNotEmpty) {
                if (isCert) {
                  controller.addCertificate(text);
                } else {
                  controller.addShopPhoto(text);
                }
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shopInfoControllerProvider(widget.store));
    final controller =
        ref.read(shopInfoControllerProvider(widget.store).notifier);

    final isBusy = state.isLoading || state.isSaving;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: StoreTabAppBar(
        title: 'Shop Info',
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
              onPressed: isBusy ? null : () => _handleSave(controller),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Shop Photos
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionHeader('Shop Photos'),
                      TextButton.icon(
                        onPressed: () =>
                            _showAddPhotoMockDialog(controller, false),
                        icon: const Icon(Icons.add_a_photo, size: 16),
                        label: const Text('Add Photo',
                            style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (state.shopPhotos.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.photo_library_outlined,
                              size: 36, color: Colors.grey),
                          SizedBox(height: 6),
                          Text(
                            'No shop photos uploaded yet',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: state.shopPhotos.length,
                        itemBuilder: (ctx, i) {
                          return Container(
                            width: 100,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    state.shopPhotos[i],
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Center(
                                      child: Icon(Icons.broken_image,
                                          color: Colors.grey),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: InkWell(
                                    onTap: () => controller.removeShopPhoto(i),
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(2),
                                      child: const Icon(Icons.close,
                                          size: 14, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 20),

                  // 2. Certificates & Awards
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionHeader('Certificates / Awards'),
                      TextButton.icon(
                        onPressed: () =>
                            _showAddPhotoMockDialog(controller, true),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Certificate',
                            style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (state.certificates.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.workspace_premium_outlined,
                              size: 36, color: Colors.grey),
                          SizedBox(height: 6),
                          Text(
                            'No certificates uploaded yet',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: state.certificates.length,
                        itemBuilder: (ctx, i) {
                          return Container(
                            width: 100,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    state.certificates[i],
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Center(
                                      child: Icon(Icons.broken_image,
                                          color: Colors.grey),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: InkWell(
                                    onTap: () =>
                                        controller.removeCertificate(i),
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(2),
                                      child: const Icon(Icons.close,
                                          size: 14, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 20),

                  // 3. About Store / Description
                  _buildSectionHeader('Description / About Store'),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _descController,
                          maxLines: 2,
                          style: const TextStyle(
                              fontSize: 13, color: Colors.black87),
                          decoration: InputDecoration(
                            hintText: 'Enter about store description',
                            hintStyle: const TextStyle(
                                fontSize: 13, color: Colors.grey),
                            contentPadding: const EdgeInsets.all(10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2196F3),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        onPressed: () {
                          if (_descController.text.trim().isNotEmpty) {
                            controller
                                .addDescription(_descController.text.trim());
                            _descController.clear();
                          }
                        },
                        child: const Text('Add',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (state.descriptions.isNotEmpty)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: state.descriptions.length,
                      itemBuilder: (ctx, i) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  state.descriptions[i],
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.black87),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    size: 18, color: Colors.red),
                                onPressed: () =>
                                    controller.removeDescription(i),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 20),

                  // 4. Video Links
                  _buildSectionHeader('Video Links (YouTube / Web)'),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: TextField(
                            controller: _videoUrlController,
                            style: const TextStyle(
                                fontSize: 13, color: Colors.black87),
                            decoration: InputDecoration(
                              hintText: 'https://youtube.com/...',
                              hintStyle: const TextStyle(
                                  fontSize: 13, color: Colors.grey),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2196F3),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        onPressed: () {
                          final ok = controller
                              .addVideoUrl(_videoUrlController.text.trim());
                          if (ok) {
                            _videoUrlController.clear();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter a valid video URL'),
                              ),
                            );
                          }
                        },
                        child: const Text('Add Link',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (state.videoUrls.isNotEmpty)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: state.videoUrls.length,
                      itemBuilder: (ctx, i) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.play_circle_fill,
                                  size: 18, color: Colors.red),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  state.videoUrls[i],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF2196F3),
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    size: 18, color: Colors.red),
                                onPressed: () =>
                                    controller.removeVideoUrl(i),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: Color(0xFF333333),
      ),
    );
  }
}
