import 'package:flutter/material.dart';

import '../core/theme.dart';

/// A tappable stat tile used across admin/driver dashboards. Shows an
/// animated count, a status dot + icon, and a subtle press/scale effect so
/// it reads clearly as an interactive filter, not just a static number.
class AnimatedStatCard extends StatefulWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;
  final bool selected;

  const AnimatedStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.onTap,
    this.selected = false,
  });

  @override
  State<AnimatedStatCard> createState() => _AnimatedStatCardState();
}

class _AnimatedStatCardState extends State<AnimatedStatCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap == null ? null : (_) => setState(() => _pressed = true),
      onTapCancel: widget.onTap == null ? null : () => setState(() => _pressed = false),
      onTapUp: widget.onTap == null ? null : (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.fleet.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: widget.selected ? widget.color : context.fleet.divider,
              width: widget.selected ? 1.4 : 1,
            ),
            boxShadow: widget.selected
                ? [BoxShadow(color: widget.color.withOpacity(0.18), blurRadius: 16, offset: const Offset(0, 6))]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: AppGradients.tint(widget.color),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(widget.icon, size: 17, color: widget.color),
                  ),
                  if (widget.onTap != null)
                    Icon(Icons.chevron_right_rounded, size: 18, color: context.fleet.textSecondary.withOpacity(0.6)),
                ],
              ),
              const SizedBox(height: 14),
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: widget.value),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (context, val, _) => Text(
                  '$val',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: context.fleet.textPrimary),
                ),
              ),
              const SizedBox(height: 2),
              Text(widget.label, style: TextStyle(fontSize: 12.5, color: context.fleet.textSecondary, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
