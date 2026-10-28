import 'package:flutter/material.dart';

/// Common 45dp Toolbar used by all store tab screens, matching Android toolbar layout
/// (`tool_bg`: #F5F5F5, `tool_text`: #616161, 14sp bold ProductSans, left `home.png`, 1dp bottom divider).
class StoreTabAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onHomeTap;

  const StoreTabAppBar({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
    this.onHomeTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60.0);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 60.0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: Row(
                  children: [
                    leading ??
                        InkWell(
                          onTap: onHomeTap ??
                              () => Navigator.of(context, rootNavigator: true)
                                  .popUntil((route) => route.isFirst),
                          child: Padding(
                            padding: const EdgeInsets.all(11.0),
                            child: Image.asset(
                              'assets/images/home.png',
                              width: 22,
                              height: 22,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF616161),
                          fontFamily: 'ProductSans',
                        ),
                      ),
                    ),
                    if (trailing != null)
                      trailing!
                    else
                      const SizedBox(width: 44), // Balances the left 44px home button
                  ],
                ),
              ),
              const Divider(
                height: 1,
                thickness: 1,
                color: Color(0xFFE0E0E0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
