import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/constants/app_strings.dart';

/// Image picker for store photos.
/// Matches Android requirement: minimum 2 images, up to 5 images.
/// Handles runtime permission checks for Camera and Gallery with rationale dialogs.
class StoreImagePicker extends StatelessWidget {
  final List<File> images;
  final ValueChanged<List<File>> onImagesChanged;
  final Future<bool> Function(ImageSource source)? permissionChecker;
  final VoidCallback? onOpenSettings;

  const StoreImagePicker({
    super.key,
    required this.images,
    required this.onImagesChanged,
    this.permissionChecker,
    this.onOpenSettings,
  });

  /// Displays an explanation alert dialog directing the user to App Settings.
  static Future<void> showPermissionDeniedDialog(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onOpenSettings,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF212121),
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF616161),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              AppStrings.cancel,
              style: TextStyle(
                color: Color(0xFF757575),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1976D2),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              if (onOpenSettings != null) {
                onOpenSettings();
              } else {
                openAppSettings();
              }
            },
            child: const Text(AppStrings.openAppSettingsAction),
          ),
        ],
      ),
    );
  }

  Future<bool> _verifyCameraPermission(BuildContext context) async {
    try {
      final status = await Permission.camera.status;
      if (status.isGranted || status.isLimited) {
        return true;
      }
      final requested = await Permission.camera.request();
      if (requested.isGranted || requested.isLimited) {
        return true;
      }
      if (requested.isPermanentlyDenied) {
        if (context.mounted) {
          showPermissionDeniedDialog(
            context,
            title: AppStrings.cameraPermissionRequiredTitle,
            message: AppStrings.cameraPermissionRequiredMsg,
            onOpenSettings: onOpenSettings,
          );
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error verifying camera permission: $e');
      return false;
    }
  }

  Future<bool> _verifyGalleryPermission(BuildContext context) async {
    try {
      if (!kIsWeb && Platform.isAndroid) {
        final photosStatus = await Permission.photos.status;
        final storageStatus = await Permission.storage.status;

        if (photosStatus.isGranted ||
            photosStatus.isLimited ||
            storageStatus.isGranted ||
            storageStatus.isLimited) {
          return true;
        }

        // Request photos first (Android 13+)
        final requestedPhotos = await Permission.photos.request();
        if (requestedPhotos.isGranted || requestedPhotos.isLimited) {
          return true;
        }

        // If not granted, try requesting storage (legacy Android)
        final requestedStorage = await Permission.storage.request();
        if (requestedStorage.isGranted || requestedStorage.isLimited) {
          return true;
        }

        if (requestedPhotos.isPermanentlyDenied ||
            requestedStorage.isPermanentlyDenied) {
          if (context.mounted) {
            showPermissionDeniedDialog(
              context,
              title: AppStrings.galleryPermissionRequiredTitle,
              message: AppStrings.galleryPermissionRequiredAndroidMsg,
              onOpenSettings: onOpenSettings,
            );
          }
        }
        return false;
      } else {
        final status = await Permission.photos.status;
        if (status.isGranted || status.isLimited) {
          return true;
        }
        final requested = await Permission.photos.request();
        if (requested.isGranted || requested.isLimited) {
          return true;
        }
        if (requested.isPermanentlyDenied) {
          if (context.mounted) {
            showPermissionDeniedDialog(
              context,
              title: AppStrings.galleryPermissionRequiredTitle,
              message: AppStrings.galleryPermissionRequiredIosMsg,
              onOpenSettings: onOpenSettings,
            );
          }
        }
        return false;
      }
    } catch (e) {
      debugPrint('Error verifying gallery permission: $e');
      return false;
    }
  }

  Future<void> _handleOptionSelected(
    BuildContext context,
    ImageSource source,
  ) async {
    final bool hasPermission;
    if (permissionChecker != null) {
      hasPermission = await permissionChecker!(source);
    } else if (source == ImageSource.camera) {
      hasPermission = await _verifyCameraPermission(context);
    } else {
      hasPermission = await _verifyGalleryPermission(context);
    }

    if (!hasPermission) return;
    if (!context.mounted) return;

    await _pickImage(context, source);
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    final int remainingSlots = 5 - images.length;
    if (remainingSlots <= 0) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.maxImagesAllowed)),
        );
      }
      return;
    }

    try {
      // Ensure Android PhotoPicker is enabled so the OS limits checkboxes in the gallery UI
      if (!kIsWeb && Platform.isAndroid) {
        final platform = ImagePickerPlatform.instance;
        if (platform is ImagePickerAndroid) {
          platform.useAndroidPhotoPicker = true;
        }
      }

      final picker = ImagePicker();
      if (source == ImageSource.gallery) {
        if (remainingSlots == 1) {
          // Android PickMultipleVisualMedia requires limit >= 2.
          // For exactly 1 slot, single image picker enforces selecting only 1 image.
          final XFile? pickedFile = await picker.pickImage(
            source: ImageSource.gallery,
            maxWidth: 1024,
            maxHeight: 1024,
            imageQuality: 80,
          );
          if (pickedFile != null) {
            final combined = [...images, File(pickedFile.path)].take(5).toList();
            onImagesChanged(combined);
          }
        } else {
          // Pass remainingSlots directly to the image picker plugin's limit parameter
          final List<XFile> pickedFiles = await picker.pickMultiImage(
            limit: remainingSlots,
            maxWidth: 1024,
            maxHeight: 1024,
            imageQuality: 80,
          );
          if (pickedFiles.isNotEmpty) {
            // Safety Net Validation:
            // In case the platform picker does not strictly enforce the limit, enforce a slice in Dart
            final allowedFiles = pickedFiles.take(remainingSlots).toList();

            if (pickedFiles.length > remainingSlots && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text(AppStrings.maxImagesAllowed)),
              );
            }

            final newFiles = allowedFiles.map((x) => File(x.path)).toList();
            final combined = [...images, ...newFiles].take(5).toList();
            onImagesChanged(combined);
          }
        }
      } else {
        if (images.length >= 5) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(AppStrings.maxImagesAllowed)),
            );
          }
          return;
        }
        final pickedFile = await picker.pickImage(
          source: source,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 80,
        );
        if (pickedFile != null) {
          final combined = [...images, File(pickedFile.path)].take(5).toList();
          onImagesChanged(combined);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  void _showPickerBottomSheet(BuildContext context) {
    if (images.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.maxImagesAllowed)),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF388E3C)),
              title: const Text(AppStrings.takePhoto),
              onTap: () {
                Navigator.of(context).pop();
                _handleOptionSelected(context, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF1976D2)),
              title: const Text(AppStrings.chooseFromGallery),
              onTap: () {
                Navigator.of(context).pop();
                _handleOptionSelected(context, ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _removeImage(int index) {
    final updated = List<File>.from(images)..removeAt(index);
    onImagesChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final isMaxReached = images.length >= 5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              AppStrings.storeImagesTitle,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF212121),
              ),
            ),
            Text(
              '${images.length}/5 (Min 2 required)',
              style: TextStyle(
                fontSize: 12,
                color: images.length < 2 ? const Color(0xFFE53935) : Colors.grey[600],
                fontWeight: images.length < 2 ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 72,
          child: Row(
            children: [
              // Left side: Thumbnails array
              Expanded(
                child: images.isEmpty
                    ? Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9F9F9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                        ),
                        child: Text(
                          'No images added yet (Min 2, Max 5)',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      )
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: images.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFB0BEC5)),
                                  image: DecorationImage(
                                    image: FileImage(images[index]),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 2,
                                right: 2,
                                child: GestureDetector(
                                  onTap: () => _removeImage(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),

              const SizedBox(width: 10),

              // Right side: 'Add Photo' / camera icon button
              Opacity(
                opacity: isMaxReached ? 0.4 : 1.0,
                child: InkWell(
                  onTap: isMaxReached
                      ? () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text(AppStrings.maxImagesAllowed)),
                          );
                        }
                      : () => _showPickerBottomSheet(context),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isMaxReached
                            ? const Color(0xFFE0E0E0)
                            : const Color(0xFF1976D2),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo_outlined,
                          size: 24,
                          color: isMaxReached
                              ? Colors.grey
                              : const Color(0xFF1976D2),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppStrings.addPhoto,
                          style: TextStyle(
                            fontSize: 10,
                            color: isMaxReached
                                ? Colors.grey
                                : const Color(0xFF1976D2),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
