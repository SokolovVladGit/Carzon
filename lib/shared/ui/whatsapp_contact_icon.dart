import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// WhatsApp brand glyph for contact actions (Lucide has no equivalent).
class WhatsappContactIcon extends StatelessWidget {
  const WhatsappContactIcon({super.key, this.size = 20});

  final double size;

  static const String _asset = 'assets/contact/whatsapp.svg';

  @override
  Widget build(BuildContext context) {
    final color =
        IconTheme.of(context).color ?? Theme.of(context).colorScheme.onSurface;
    return SvgPicture.asset(
      _asset,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
