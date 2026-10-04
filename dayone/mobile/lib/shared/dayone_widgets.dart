import 'package:flutter/material.dart';

import '../app/theme.dart';

class DayOneButton extends StatelessWidget {
  const DayOneButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = DayOneButtonVariant.primary,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final DayOneButtonVariant variant;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;
    final colors = switch (variant) {
      DayOneButtonVariant.primary => (Colors.white, DayOneColors.primary),
      DayOneButtonVariant.white => (DayOneColors.primaryDark, Colors.white),
      DayOneButtonVariant.ghost => (DayOneColors.primary, Colors.transparent),
      DayOneButtonVariant.soft => (DayOneColors.primaryDark, DayOneColors.primarySoft),
      DayOneButtonVariant.danger => (Colors.white, DayOneColors.danger),
    };
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: variant == DayOneButtonVariant.primary && enabled ? DayOneColors.gradient : null,
          color: variant == DayOneButtonVariant.primary
              ? (enabled ? null : const Color(0xFFEBC3D3))
              : colors.$2,
          borderRadius: BorderRadius.circular(999),
          border: variant == DayOneButtonVariant.ghost
              ? Border.all(color: enabled ? DayOneColors.primary : DayOneColors.border, width: 1.5)
              : null,
          boxShadow: variant == DayOneButtonVariant.primary && enabled
              ? const [BoxShadow(color: Color(0x52D9467F), blurRadius: 18, offset: Offset(0, 8))]
              : variant == DayOneButtonVariant.white
                  ? const [BoxShadow(color: Color(0x2E3C0A1E), blurRadius: 18, offset: Offset(0, 8))]
                  : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: enabled ? onPressed : null,
            child: Center(
              child: busy
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: variant == DayOneButtonVariant.white ? DayOneColors.primary : Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, size: 18, color: colors.$1),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          label,
                          style: TextStyle(color: colors.$1, fontWeight: FontWeight.w800, fontSize: 14.5),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

enum DayOneButtonVariant { primary, white, ghost, soft, danger }

class DayOneField extends StatelessWidget {
  const DayOneField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.obscure = false,
    this.textInputAction,
    this.onSubmitted,
    this.suffix,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool obscure;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: DayOneColors.text)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            obscureText: obscure,
            textInputAction: textInputAction,
            onSubmitted: onSubmitted,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: DayOneColors.text),
            decoration: InputDecoration(hintText: hint, suffixIcon: suffix),
          ),
        ],
      ),
    );
  }
}

class SoftCard extends StatelessWidget {
  const SoftCard({super.key, required this.child, this.color, this.onTap, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final Color? color;
  final VoidCallback? onTap;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? DayOneColors.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: DayOneColors.shadow,
      ),
      child: child,
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(borderRadius: BorderRadius.circular(22), onTap: onTap, child: card),
    );
  }
}
