import 'dart:ui';
import 'package:flutter/material.dart';

/// Frosted-glass surface tokens, matching the app's brand hues (teal-blue
/// primary, dark-navy ink, warm cream / deep navy grounds) rather than a
/// generic Material surface. One place so every screen reads as one system.
class GlassTokens {
  final Color bg1;
  final Color bg2;
  final Color card;
  final Color cardBorder;
  final Color ink;
  final Color inkSoft;
  final Color shadow;
  final Color switchOff;
  final Color accent;

  const GlassTokens({
    required this.bg1,
    required this.bg2,
    required this.card,
    required this.cardBorder,
    required this.ink,
    required this.inkSoft,
    required this.shadow,
    required this.switchOff,
    required this.accent,
  });

  static const light = GlassTokens(
    bg1: Color(0xFFF6F1D1),
    bg2: Color(0xFFDCEAE3),
    card: Color(0x99FFFFFF),
    cardBorder: Color(0xBFFFFFFF),
    ink: Color(0xFF0B2027),
    inkSoft: Color(0x990B2027),
    shadow: Color(0x290B2027),
    switchOff: Color(0x240B2027),
    accent: Color(0xFF40798C),
  );

  static const dark = GlassTokens(
    bg1: Color(0xFF0B2027),
    bg2: Color(0xFF12313A),
    card: Color(0x8C162A32),
    cardBorder: Color(0x17FFFFFF),
    ink: Color(0xFFF3F6F5),
    inkSoft: Color(0x9EF3F6F5),
    shadow: Color(0x73000000),
    switchOff: Color(0x24FFFFFF),
    accent: Color(0xFF6FA8BB),
  );

  static GlassTokens of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

/// Background: a soft radial gradient mesh rather than a flat fill --
/// the one atmosphere effect worth its cost, since it's the ground every
/// glass card is composited over.
class GlassBackground extends StatelessWidget {
  final Widget child;
  const GlassBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.7, -1.05),
          radius: 1.3,
          colors: [t.bg2, t.bg1],
          stops: const [0.0, 0.65],
        ),
      ),
      child: child,
    );
  }
}

/// A frosted card: translucent fill, blurred backdrop, hairline border,
/// soft shadow. The one repeated "object" every grouped surface in the
/// app is built from.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(0),
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: t.card,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: t.cardBorder),
            boxShadow: [BoxShadow(color: t.shadow, blurRadius: 32, offset: const Offset(0, 14))],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// One row inside a GlassCard: leading icon chip, title/subtitle, trailing
/// content. Every settings/schedule row shares this so spacing and
/// baselines line up without re-deriving them per screen.
class GlassRow extends StatelessWidget {
  final Widget icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;

  const GlassRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: t.ink)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: TextStyle(fontSize: 13, color: t.inkSoft)),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
    return Column(
      children: [
        if (showDivider) Divider(height: 1, thickness: 1, color: t.cardBorder, indent: 18, endIndent: 18),
        onTap != null ? InkWell(onTap: onTap, child: row) : row,
      ],
    );
  }
}

/// Icon chip used at the leading edge of a GlassRow, tinted with the
/// accent color at low opacity rather than a flat neutral square.
class GlassIconChip extends StatelessWidget {
  final IconData icon;
  const GlassIconChip({super.key, required this.icon});

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: t.accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(icon, size: 18, color: t.accent),
    );
  }
}

class GlassStatusPill extends StatelessWidget {
  final String label;
  final Color dotColor;
  const GlassStatusPill({super.key, required this.label, required this.dotColor});

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    return GlassCard(
      radius: 999,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.ink)),
        ],
      ),
    );
  }
}

class GlassSectionTitle extends StatelessWidget {
  final String text;
  const GlassSectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: t.inkSoft),
      ),
    );
  }
}
