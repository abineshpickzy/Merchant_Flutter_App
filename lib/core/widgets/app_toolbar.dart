import 'package:flutter/material.dart';
import 'package:bayfay_merchant_flutter/core/constants/app_constants.dart';

/// Standardized 50px top navigation toolbar matching Android's @color/tool_bg (#F5F5F5)
/// with 2px bottom border (#E3E3E3) and Roboto 16px title.
class AppToolbar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final bool showBack;

  const AppToolbar({
    super.key,
    required this.title,
    this.onBack,
    this.actions,
    this.showBack = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(50);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF5F5F5),
        border: Border(
          bottom: BorderSide(color: Color(0xFFE3E3E3), width: 2),
        ),
      ),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: showBack
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFF616161),
                  size: 18,
                ),
                onPressed: onBack ?? () => Navigator.of(context).pop(),
              )
            : null,
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: AppFonts.roboto,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF616161),
          ),
        ),
        actions: actions,
      ),
    );
  }
}
