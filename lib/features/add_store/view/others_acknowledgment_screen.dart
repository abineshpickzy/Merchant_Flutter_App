import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../dashboard/controller/dashboard_controller.dart';

/// Confirmation / Acknowledgment Screen for 'Others' category store creation
/// Displays support contact message and email sales@bayfay.com with an outlined blue OK button.
class OthersAcknowledgmentScreen extends ConsumerWidget {
  const OthersAcknowledgmentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Merchant Signup',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE0E0E0)),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.mark_email_read_outlined,
                size: 64,
                color: Color(0xFF1976D2),
              ),
              const SizedBox(height: 24),
              const Text(
                'Our support team will contact you as soon as possible to proceed further. Thank you for your interest to open a shop with us.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Our support team email id : sales@bayfay.com',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1976D2),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: 140,
                height: 44,
                child: OutlinedButton(
                  onPressed: () {
                    ref.read(storesProvider.notifier).fetchMerchantStores();
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1976D2),
                    side: const BorderSide(color: Color(0xFF1976D2), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
