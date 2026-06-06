import 'package:flutter/material.dart';

/// Reusable signed-out prompt body for protected screens.
///
/// This widget is intentionally presentation-only: callers keep owning route
/// decisions, auth state checks, surrounding Scaffold/AppBar chrome, and the
/// sign-in callback.
class AuthRequiredPrompt extends StatelessWidget {
  const AuthRequiredPrompt({
    super.key,
    required this.message,
    required this.primaryButtonLabel,
    required this.onPrimaryPressed,
    this.icon,
    this.subtitle,
    this.padding = const EdgeInsets.all(24),
    this.center = true,
    this.mainAxisAlignment = MainAxisAlignment.center,
    this.messageStyle,
    this.contentWrapper,
  });

  final Widget? icon;
  final String message;
  final String? subtitle;
  final String primaryButtonLabel;
  final VoidCallback onPrimaryPressed;
  final EdgeInsetsGeometry padding;
  final bool center;
  final MainAxisAlignment mainAxisAlignment;
  final TextStyle? messageStyle;
  final Widget Function(BuildContext context, Widget child)? contentWrapper;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: mainAxisAlignment,
      children: [
        if (icon != null) ...[icon!, const SizedBox(height: 12)],
        Text(message, textAlign: TextAlign.center, style: messageStyle),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(subtitle!, textAlign: TextAlign.center),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: onPrimaryPressed,
          child: Text(primaryButtonLabel),
        ),
      ],
    );

    final wrapped = contentWrapper?.call(context, content) ?? content;
    final padded = Padding(padding: padding, child: wrapped);
    return center ? Center(child: padded) : padded;
  }
}
