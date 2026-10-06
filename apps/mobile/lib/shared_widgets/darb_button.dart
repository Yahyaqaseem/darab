import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/darb_icons.dart';

enum DarbButtonVariant { primary, secondary, outlined, danger }
enum DarbButtonSize { small, medium, large }

class DarbButton extends StatefulWidget {
  const DarbButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = DarbButtonVariant.primary,
    this.size = DarbButtonSize.medium,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = false,
  });

  final String text;
  final VoidCallback? onPressed;
  final DarbButtonVariant variant;
  final DarbButtonSize size;
  final DarbIconType? icon;
  final DarbIconType? trailingIcon;
  final bool isLoading;
  final bool isFullWidth;

  @override
  State<DarbButton> createState() => _DarbButtonState();
}

class _DarbButtonState extends State<DarbButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
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
    final isDisabled = widget.onPressed == null || widget.isLoading;

    // 1. Determine Colors based on variant
    Color backgroundColor;
    Color textColor;
    Color borderColor;

    switch (widget.variant) {
      case DarbButtonVariant.primary:
        backgroundColor = DarbColors.primaryYellow;
        textColor = DarbColors.textInversePrimary; // Dark text on yellow
        borderColor = DarbColors.primaryYellow;
        break;
      case DarbButtonVariant.secondary:
        backgroundColor = DarbColors.surface;
        textColor = DarbColors.textPrimary;
        borderColor = DarbColors.border;
        break;
      case DarbButtonVariant.outlined:
        backgroundColor = Colors.transparent;
        textColor = DarbColors.textPrimary;
        borderColor = DarbColors.border;
        break;
      case DarbButtonVariant.danger:
        backgroundColor = DarbColors.dangerRed;
        textColor = Colors.white;
        borderColor = DarbColors.dangerRed;
        break;
    }

    if (isDisabled) {
      backgroundColor = DarbColors.surface.withOpacity(0.5);
      textColor = DarbColors.textDisabled;
      borderColor = DarbColors.border.withOpacity(0.5);
    }

    // 2. Determine Sizes
    double height;
    EdgeInsetsGeometry padding;
    TextStyle textStyle;
    double iconSize;

    switch (widget.size) {
      case DarbButtonSize.small:
        height = 36;
        padding = const EdgeInsets.symmetric(horizontal: DarbSpacing.md);
        textStyle = DarbTypography.caption.copyWith(fontWeight: FontWeight.w600);
        iconSize = 16;
        break;
      case DarbButtonSize.medium:
        height = 48;
        padding = const EdgeInsets.symmetric(horizontal: DarbSpacing.lg);
        textStyle = DarbTypography.body.copyWith(fontWeight: FontWeight.w700);
        iconSize = 20;
        break;
      case DarbButtonSize.large:
        height = 56;
        padding = const EdgeInsets.symmetric(horizontal: DarbSpacing.xl);
        textStyle = DarbTypography.section.copyWith(fontWeight: FontWeight.w700);
        iconSize = 24;
        break;
    }

    // 3. Build Content
    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading) ...[
          SizedBox(
            width: iconSize,
            height: iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(textColor),
            ),
          ),
          const SizedBox(width: DarbSpacing.md),
        ] else if (widget.icon != null) ...[
          DarbIcon(widget.icon!, size: iconSize, color: textColor),
          const SizedBox(width: DarbSpacing.md),
        ],
        Flexible(
          child: Text(
            widget.text,
            style: textStyle.copyWith(color: textColor),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (!widget.isLoading && widget.trailingIcon != null) ...[
          const SizedBox(width: DarbSpacing.md),
          DarbIcon(widget.trailingIcon!, size: iconSize, color: textColor),
        ],
      ],
    );

    // 4. Wrap with material button
    final button = ScaleTransition(
      scale: _scaleAnimation,
      child: Material(
        color: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderColor, width: 1.5),
        ),
        child: GestureDetector(
          onTapDown: isDisabled ? null : (_) => _controller.forward(),
          onTapUp: isDisabled ? null : (_) {
            _controller.reverse();
            widget.onPressed?.call();
          },
          onTapCancel: isDisabled ? null : () => _controller.reverse(),
          child: InkWell(
            onTap: isDisabled ? null : () {},
            borderRadius: BorderRadius.circular(12),
            splashColor: textColor.withOpacity(0.1),
            highlightColor: textColor.withOpacity(0.05),
            child: Container(
              height: height,
              padding: padding,
              alignment: Alignment.center,
              child: content,
            ),
          ),
        ),
      ),
    );

    return widget.isFullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}
