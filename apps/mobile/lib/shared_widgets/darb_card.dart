import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class DarbCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final bool isInteractive;
  final Color? backgroundColor;
  final bool hasShadow;
  final double borderRadius;

  const DarbCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(DarbSpacing.lg),
    this.onTap,
    this.isInteractive = false,
    this.backgroundColor,
    this.hasShadow = true,
    this.borderRadius = 16.0,
  });

  @override
  State<DarbCard> createState() => _DarbCardState();
}

class _DarbCardState extends State<DarbCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardContent = Container(
      padding: widget.padding ?? EdgeInsets.zero,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? (isDark ? DarbColors.card : Colors.white),
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(
          color: isDark ? DarbColors.border.withOpacity(0.5) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          if (!isDark && widget.hasShadow)
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: widget.child,
    );

    if (widget.isInteractive && widget.onTap != null) {
      return ScaleTransition(
        scale: _scaleAnimation,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTapDown: (_) => _controller.forward(),
            onTapUp: (_) {
              _controller.reverse();
              widget.onTap?.call();
            },
            onTapCancel: () => _controller.reverse(),
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: cardContent,
            ),
          ),
        ),
      );
    }

    return cardContent;
  }
}
