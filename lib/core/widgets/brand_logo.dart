import 'package:flutter/material.dart';

/// Official Luqta brand artwork exported from the supplied visual identity.
abstract final class BrandAssets {
  static const String icon = 'assets/branding/lugta_icon_mark.png';
  static const String wordmarkInk = 'assets/branding/lugta_wordmark_ink.png';
  static const String wordmarkWhite =
      'assets/branding/lugta_wordmark_white.png';
}

class BrandIcon extends StatelessWidget {
  const BrandIcon({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Luqta',
      child: Image.asset(
        BrandAssets.icon,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        excludeFromSemantics: true,
      ),
    );
  }
}

class LugtaWordmark extends StatelessWidget {
  const LugtaWordmark({super.key, this.height = 52, this.inverse});

  final double height;
  final bool? inverse;

  @override
  Widget build(BuildContext context) {
    final useInverse =
        inverse ?? Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      image: true,
      label: 'Luqta',
      child: Image.asset(
        useInverse ? BrandAssets.wordmarkWhite : BrandAssets.wordmarkInk,
        height: height,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        excludeFromSemantics: true,
      ),
    );
  }
}
