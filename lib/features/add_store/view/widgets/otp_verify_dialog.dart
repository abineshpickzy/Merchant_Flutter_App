import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_strings.dart';

/// Modal dialog for verifying 6-digit OTP for store mobile number.
class OtpVerifyDialog extends StatefulWidget {
  final int mobileNumber;
  final Future<bool> Function(int otp) onVerify;
  final VoidCallback onResend;

  const OtpVerifyDialog({
    super.key,
    required this.mobileNumber,
    required this.onVerify,
    required this.onResend,
  });

  @override
  State<OtpVerifyDialog> createState() => _OtpVerifyDialogState();
}

class _OtpVerifyDialogState extends State<OtpVerifyDialog> {
  final TextEditingController _otpCtrl = TextEditingController();
  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _otpCtrl.text.trim();
    if (text.isEmpty || text.length < 4) {
      setState(() => _errorText = AppStrings.enterValidOtp);
      return;
    }

    final otp = int.tryParse(text);
    if (otp == null) {
      setState(() => _errorText = AppStrings.enterNumericOtp);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final success = await widget.onVerify(otp);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _errorText = AppStrings.invalidOtpTryAgain);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        AppStrings.verifyMobileNumber,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${AppStrings.weHaveSentCodeTo} +91 ${widget.mobileNumber}',
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _otpCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
            ),
            onChanged: (val) {
              if (_errorText != null) {
                setState(() => _errorText = null);
              }
            },
            decoration: InputDecoration(
              hintText: '• • • • • •',
              hintStyle: const TextStyle(letterSpacing: 4, color: Colors.grey),
              errorText: _errorText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: _isLoading
                  ? null
                  : () {
                      widget.onResend();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(AppStrings.otpResentSuccessMsg),
                        ),
                      );
                    },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Text(
                  AppStrings.resendOtp,
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF1976D2),
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: Color(0xFF1976D2),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        Row(
          children: [
            // Cancel button on the Left
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: Color(0xFFBDBDBD)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  AppStrings.cancel,
                  style: TextStyle(
                    color: Color(0xFF757575),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Verify button on the Right
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        AppStrings.verify,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

