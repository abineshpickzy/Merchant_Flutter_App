import 'package:flutter/material.dart';

/// Modal dialog for SMS OTP verification matching Android alert_otp.xml
class StoreDetailsOtpDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final bool isLoading;
  final Future<({bool success, String message})> Function(int otp) onVerify;
  final VoidCallback onResend;

  const StoreDetailsOtpDialog({
    super.key,
    this.title = 'OTP Verification',
    this.subtitle = 'Please enter the OTP sent to your registered mobile number',
    this.isLoading = false,
    required this.onVerify,
    required this.onResend,
  });

  @override
  State<StoreDetailsOtpDialog> createState() => _StoreDetailsOtpDialogState();
}

class _StoreDetailsOtpDialogState extends State<StoreDetailsOtpDialog> {
  final TextEditingController _otpController = TextEditingController();
  bool _verifying = false;
  String? _errorText;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final otpStr = _otpController.text.trim();
    if (otpStr.length < 4) {
      setState(() => _errorText = 'Please enter valid OTP');
      return;
    }

    final otp = int.tryParse(otpStr);
    if (otp == null) {
      setState(() => _errorText = 'Please enter digits only');
      return;
    }

    setState(() {
      _verifying = true;
      _errorText = null;
    });

    final res = await widget.onVerify(otp);

    if (mounted) {
      setState(() => _verifying = false);
      if (res.success) {
        Navigator.of(context).pop(true);
      } else {
        setState(() => _errorText = res.message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Top Shield / Verification Icon matching Android ic_otp_verify_img
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified_user_rounded,
                color: Color(0xFF2196F3),
                size: 32,
              ),
            ),
            const SizedBox(height: 12),

            // Title
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              widget.subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16),

            // OTP Input
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                letterSpacing: 6,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                counterText: '',
                hintText: '• • • • • •',
                hintStyle: TextStyle(color: Colors.grey.shade400, letterSpacing: 4),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF2196F3), width: 1.5),
                ),
              ),
            ),

            if (_errorText != null) ...[
              const SizedBox(height: 6),
              Text(
                _errorText!,
                style: const TextStyle(color: Colors.red, fontSize: 11),
              ),
            ],

            const SizedBox(height: 12),

            // Resend OTP link
            Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: widget.onResend,
                child: const Text(
                  'Resend OTP',
                  style: TextStyle(
                    color: Color(0xFF2196F3),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Buttons: Cancel & Submit
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.grey.shade400),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _verifying ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _verifying
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Submit',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
