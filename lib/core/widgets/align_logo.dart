import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

/// Path of the Align "A" mark. It is a raster rather than a vector because the
/// artwork carries soft 3D shading and a separate gradient per ribbon.
/// Regenerate with `python tool/gen_align_brand.py` — the same master also
/// produces every launcher icon and native splash raster.
const kAlignMarkAsset = 'assets/img/logo/align-mark.png';

/// Aspect ratio (w/h) of the artwork — it is noticeably wider than it is tall.
const kAlignMarkAspect = 1300 / 1048;

/// The gradient "A" mark on its own.
class AlignMark extends StatelessWidget {
  const AlignMark({super.key, this.size = 72, this.glow = false});

  /// Width of the mark. Height follows from [kAlignMarkAspect].
  final double size;

  /// Draws the brand glow behind the mark (splash / auth hero use it).
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final mark = Image.asset(
      kAlignMarkAsset,
      width: size,
      // Sizing both axes up front keeps the layout stable: an Image with only
      // a width reports zero height until the first frame is decoded, which
      // makes the splash lock-up jump.
      height: size / kAlignMarkAspect,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      // The asset is 1024px on its long side; decoding it at full size for a
      // 30px header logo would hold megabytes in the image cache for nothing.
      cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
    );
    if (!glow) return mark;
    return Stack(
      alignment: Alignment.center,
      children: [
        // The glow is cast by a rounded box tucked behind the mark so the
        // shadow follows the logo's mass rather than its exact outline.
        Container(
          width: size * 0.6,
          height: size * 0.6 / kAlignMarkAspect,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.24),
            boxShadow: AppShadows.alignGlow,
          ),
        ),
        mark,
      ],
    );
  }
}

/// The wide-tracked "ALIGN" wordmark.
class AlignWordmark extends StatelessWidget {
  const AlignWordmark({super.key, this.fontSize = 30, this.color});

  final double fontSize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      'ALIGN',
      style: GoogleFonts.poppins(
        fontSize: fontSize,
        fontWeight: FontWeight.w300,
        letterSpacing: fontSize * 0.28,
        height: 1.1,
        color: color ?? context.colors.text,
      ),
      // The trailing letter-spacing on the "N" would otherwise pull the
      // wordmark off-centre.
      textAlign: TextAlign.center,
    );
  }
}

/// Mark + wordmark + optional tagline — the full lock-up used on the splash,
/// the onboarding header and the auth screen.
class AlignLogo extends StatelessWidget {
  const AlignLogo({
    super.key,
    this.markSize = 88,
    this.fontSize = 30,
    this.tagline,
    this.glow = true,
  });

  final double markSize;
  final double fontSize;

  /// Shown under the wordmark when set (e.g. 'Your life, in balance.').
  final String? tagline;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AlignMark(size: markSize, glow: glow),
        SizedBox(height: markSize * 0.16),
        // Padding compensates for the trailing letter-space so the wordmark
        // optically centres under the mark.
        Padding(
          padding: EdgeInsets.only(left: fontSize * 0.28),
          child: AlignWordmark(fontSize: fontSize, color: c.text),
        ),
        if (tagline != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            tagline!,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.2,
              color: c.textSubtle,
            ),
          ),
        ],
      ],
    );
  }
}
