import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/darb_icons.dart';

enum DarbButtonVariant { primary, secondary, danger, ghost, outline }
enum DarbButtonSize { small, medium, large }

class DarbButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final DarbButtonVariant variant;
  final DarbButtonSize size;
  final DarbIconType? icon;
  final DarbIconType? trailingIcon;
  final bool isLoading;
  final bool isFullWidth;

  const DarbButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = DarbButtonVariant.primary,
    this.size = DarbButtonSize.medium,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Determine sizes
    double height = 48.0;
    double fontSize = 16.0;
    double iconSize = 20.0;
    EdgeInsets padding = const EdgeInsets.symmetric(horizontal: DarbSpacing.xl);

    switch (size) {
      case DarbButtonSize.small:
        height = 36.0;
        fontSize = 14.0;
        iconSize = 16.0;
        padding = const EdgeInsets.symmetric(horizontal: DarbSpacing.lg);
        break;
      case DarbButtonSize.medium:
        height = 48.0;
        fontSize = 16.0;
        iconSize = 20.0;
        padding = const EdgeInsets.symmetric(horizontal: DarbSpacing.xl);
        break;
      case DarbButtonSize.large:
        height = 56.0;
        fontSize = 18.0;
        iconSize = 24.0;
        padding = const EdgeInsets.symmetric(horizontal: DarbSpacing.xxl);
        break;
    }

    // 2. Determine colors based on variant
    Color backgroundColor;
    Color textColor;
    Color borderColor = Colors.transparent;

    final isDisabled = onPressed == null || isLoading;

    switch (variant) {
      case DarbButtonVariant.primary:
        backgroundColor = DarbColors.primaryEmerald;
        textColor = DarbColors.textInversePrimary;
        break;
      case DarbButtonVariant.secondary:
        backgroundColor = DarbColors.surface;
        textColor = DarbColors.textPrimary;
        break;
      case DarbButtonVariant.danger:
        backgroundColor = DarbColors.dangerRed.withOpacity(0.15);
        textColor = DarbColors.dangerRed;
        borderColor = DarbColors.dangerRed.withOpacity(0.3);
        break;
      case DarbButtonVariant.ghost:
        backgroundColor = Colors.transparent;
        textColor = DarbColors.primaryEmerald;
        break;
      case DarbButtonVariant.outline:
        backgroundColor = Colors.transparent;
        textColor = DarbColors.textPrimary;
        borderColor = DarbColors.border;
        break;
    }

    if (isDisabled) {
      backgroundColor = DarbColors.surface.withOpacity(0.5);
      textColor = DarbColors.textDisabled;
      borderColor = Colors.transparent;
    }

    // 3. Build inner content
    Widget content = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: iconSize,
            height: iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              valueColor: AlwaysStoppedAnimation<Color>(textColor),
            ),
          ),
          const SizedBox(width: DarbSpacing.md),
        ] else if (icon != null) ...[
          DarbIcon(icon!, size: iconSize, color: textColor),
          const SizedBox(width: DarbSpacing.md),
        ],
        Text(
          text,
          style: DarbTypography.section.copyWith(
            color: textColor,
            fontSize: fontSize,
            height: 1.2,
          ),
        ),
        if (!isLoading && trailingIcon != null) ...[
          const SizedBox(width: DarbSpacing.md),
          DarbIcon(trailingIcon!, size: iconSize, color: textColor),
        ],
      ],
    );

    // 4. Wrap with material button
    final button = Material(
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: 1.5),
      ),
      child: InkWell(
        onTap: isDisabled ? null : onPressed,
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
    );

    return isFullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}
