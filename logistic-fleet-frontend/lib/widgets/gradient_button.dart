import 'package:flutter/material.dart';

import '../core/theme.dart';

/// An attractive gradient-filled button for primary / secondary CTAs.
///
/// By default it *wraps its content* (only as wide as label + icon) so it can
/// be centered on a page without stretching edge-to-edge — pass [expand] to
/// make it fill the available width instead. Disabled state (null [onPressed])
/// falls back to a muted grey fill with no shadow.
class GradientButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Gradient gradient;
  final bool expand;
  final bool busy;
  final EdgeInsetsGeometry padding;

  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.gradient = AppGradients.brand,
    this.expand = false,
    this.busy = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: enabled ? gradient : null,
        color: enabled ? null : context.fleet.textSecondary.withOpacity(0.22),
        borderRadius: BorderRadius.circular(14),
        boxShadow: enabled ? AppShadows.brand : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: enabled ? onPressed : null,
          child: Padding(
            padding: padding,
            child: Row(
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (busy) ...[
                  const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                ] else if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: 19),
                  const SizedBox(width: 9),
                ],
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
