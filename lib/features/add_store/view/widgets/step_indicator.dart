import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';

/// Step indicator widget for the 3-step Add Store flow.
class StepIndicator extends StatelessWidget {
  final int currentStep; // 0, 1, 2
  final bool isSingleStep;

  const StepIndicator({
    super.key,
    required this.currentStep,
    this.isSingleStep = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isSingleStep) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStep(0, AppStrings.storeInfoStep),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          _buildStep(0, AppStrings.storeInfoStep),
          _buildDivider(0),
          _buildStep(1, AppStrings.operationsStep),
          _buildDivider(1),
          _buildStep(2, AppStrings.mediaSubmitStep),
        ],
      ),
    );
  }

  Widget _buildStep(int stepIndex, String title) {
    final isDone = currentStep > stepIndex;
    final isActive = currentStep == stepIndex;

    final circleColor = isDone
        ? const Color(0xFF388E3C)
        : (isActive ? const Color(0xFF1976D2) : const Color(0xFFB0BEC5));

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: circleColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text(
                    '${stepIndex + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? const Color(0xFF212121) : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(int stepIndex) {
    final isDone = currentStep > stepIndex;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        height: 2,
        color: isDone ? const Color(0xFF388E3C) : const Color(0xFFE0E0E0),
      ),
    );
  }
}
