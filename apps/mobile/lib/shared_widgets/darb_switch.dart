import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class DarbSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? label;
  final String? subtitle;

  const DarbSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final switchWidget = CupertinoSwitch(
      value: value,
      onChanged: onChanged,
      activeColor: DarbColors.primaryEmerald,
      trackColor: DarbColors.card,
    );

    if (label == null) {
      return switchWidget;
    }

    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: DarbSpacing.sm),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label!,
                    style: DarbTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: DarbSpacing.xs),
                    Text(
                      subtitle!,
                      style: DarbTypography.caption,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: DarbSpacing.md),
            switchWidget,
          ],
        ),
      ),
    );
  }
}
