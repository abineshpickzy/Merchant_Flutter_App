import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/app.dart';
import 'core/config/app_config.dart';
import 'core/storage/local_storage_service.dart';

import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();  
  
  // Enable modern Android PhotoPicker so OS-level selection limits are enforced in UI
  try {
    if (!kIsWeb && Platform.isAndroid) {
      final platform = ImagePickerPlatform.instance;
      if (platform is ImagePickerAndroid) {
        platform.useAndroidPhotoPicker = true;
      }
    }
  } catch (e) {
    debugPrint('[ImagePicker] Failed to configure Android Photo Picker: $e');
  }

  // Initialize Firebase safely (graceful fallback on desktop or without services)
  try {
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e, stack) {
    debugPrint('[Firebase] Warning: Firebase initialization skipped ($e)\n$stack');
  }

  // Auto-detect active flavor from `--flavor` command line flag; defaults to dev
  final activeFlavor = appFlavor?.toLowerCase() ?? 'dev';

  switch (activeFlavor) {
    case 'qa':
      AppConfig.init(
        environment: Environment.qa,
        serverUrl: 'https://qa-api.bayfay.com/merchant/',
        appName: 'Merchant-Qa',
        paymentEnvironment: 2,
      );
      break;

    case 'prod':
      AppConfig.init(
        environment: Environment.prod,
        serverUrl: 'https://store-api.bayfay.com/merchant/',
        appName: 'Merchant',
        paymentEnvironment: 0,
      );
      break;

    case 'dev':
    default:
      AppConfig.init(
        environment: Environment.dev,
        serverUrl: 'https://store-devapi.bayfay.com/merchant/',
        appName: 'Merchant-Dev',
        paymentEnvironment: 2,
      );
      break;
  }

  // Initialize shared preferences before launching UI
  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const BayfayMerchantApp(),
    ),
  );
}
