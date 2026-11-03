import 'package:flutter/material.dart';

enum ButtonVariant { primary, secondary, outline, ghost }

class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.variant = ButtonVariant.primary,
    this.isLoading = false,
    this.fullWidth = false,
    this.height = 46,
    this.borderRadius = 8,
  });

  final String text;
  final VoidCallback? onPressed;
  final Widget? icon;
  final ButtonVariant variant;
  final bool isLoading;
  final bool fullWidth;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget child = isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        : Row(
            mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                icon!,
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          );

    final radius = BorderRadius.circular(borderRadius);

    switch (variant) {
      case ButtonVariant.primary:
        return SizedBox(
          width: fullWidth ? double.infinity : null,
          height: height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6818), Color(0xFFFF8533)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: radius,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6818).withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: radius),
                padding: const EdgeInsets.symmetric(horizontal: 18),
              ),
              child: child,
            ),
          ),
        );

      case ButtonVariant.secondary:
        return SizedBox(
          width: fullWidth ? double.infinity : null,
          height: height,
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFF16202E) : const Color(0xFFE2E8F0),
              foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: radius,
                side: BorderSide(
                  color: isDark ? const Color(0xFF283548) : const Color(0xFFCBD5E1),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18),
            ),
            child: child,
          ),
        );

      case ButtonVariant.outline:
        return SizedBox(
          width: fullWidth ? double.infinity : null,
          height: height,
          child: OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
              side: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
              ),
              shape: RoundedRectangleBorder(borderRadius: radius),
              padding: const EdgeInsets.symmetric(horizontal: 18),
            ),
            child: child,
          ),
        );

      case ButtonVariant.ghost:
        return SizedBox(
          width: fullWidth ? double.infinity : null,
          height: height,
          child: TextButton(
            onPressed: isLoading ? null : onPressed,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFFF6818),
              shape: RoundedRectangleBorder(borderRadius: radius),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            child: child,
          ),
        );
    }
  }
}

