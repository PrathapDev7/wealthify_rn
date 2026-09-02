"""Generates every Align brand asset from one source of truth.

The source of truth is the artwork itself: `tool/brand/align-mark-master.png`,
a transparent 1300x1048 render of the three-ribbon "A" (left limb green ->
cyan, right limb blue -> magenta, and the wave passing under them). It is not
bundled with the app; this script scales it into everything that is:

  * assets/img/logo/align-mark.png       transparent mark, 1024 long side (in-app)
  * tool/brand/align-icon.png            1024 rounded-square launcher source
  * tool/brand/align-icon-square.png / align-adaptive-fg.png
                                         sources for flutter_launcher_icons
  * tool/brand/align-splash.png          native-splash source
  * android/  res drawables + mipmaps (splash, android12splash, launcher)
  * ios/      AppIcon.appiconset + LaunchImage.imageset
  * web/      favicon + PWA icons + the web splash under web/splash/img

The mark has soft 3D shading and a separate gradient per ribbon, so it stays a
raster rather than a vector - `AlignMark` renders the PNG with `Image.asset`.
To change the logo, replace the master and re-run this script; nothing else
encodes the artwork.

Run from the Flutter project root:  python tool/gen_align_brand.py
Requires Pillow only (no numpy / no native SVG rasterizer).
"""

from __future__ import annotations

import os
from PIL import Image, ImageChops, ImageDraw, ImageMath

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MASTER = os.path.join(ROOT, 'tool', 'brand', 'align-mark-master.png')

INK = (0x0B, 0x11, 0x22)  # dark navy icon / splash background

# ---------------------------------------------------------------------------
# Alpha-correct scaling
# ---------------------------------------------------------------------------
#
# Pillow resamples the colour channels without regard to alpha, so the fully
# transparent black around the mark averages into its rim and leaves a dark
# halo - very visible once a 1300px master is squeezed into a 48px launcher
# icon. Premultiplying before the resize and dividing the alpha back out
# afterwards is the standard fix.


def _premultiply(img: Image.Image) -> Image.Image:
    r, g, b, a = img.split()
    m = ImageChops.multiply
    return Image.merge('RGBA', (m(r, a), m(g, a), m(b, a), a))


def _unpremultiply(img: Image.Image) -> Image.Image:
    r, g, b, a = img.split()

    def straighten(c: Image.Image) -> Image.Image:
        # max(a, 1) keeps the division defined; a wholly transparent pixel then
        # gets a meaningless colour, which is exactly what alpha 0 means.
        return ImageMath.lambda_eval(
            lambda v: v['convert'](
                v['min']((v['c'] * 255 + 127) / v['max'](v['a'], 1), 255), 'L'),
            c=c, a=a)

    return Image.merge('RGBA', (straighten(r), straighten(g), straighten(b), a))


def scaled(img: Image.Image, size: tuple[int, int]) -> Image.Image:
    """Halo-free resize of an image that has a transparent background."""
    if img.size == size:
        return img.copy()
    return _unpremultiply(_premultiply(img).resize(size, Image.LANCZOS))


# ---------------------------------------------------------------------------
# The mark
# ---------------------------------------------------------------------------

_master_cache: Image.Image | None = None


def master() -> Image.Image:
    """The artwork, cropped tight to its ink."""
    global _master_cache
    if _master_cache is None:
        img = Image.open(MASTER).convert('RGBA')
        # Trimming here is what lets `scale` below mean the fraction of the box
        # the *ink* covers rather than the fraction of some arbitrary canvas.
        box = img.getchannel('A').getbbox()
        _master_cache = img.crop(box) if box else img
    return _master_cache


def mark_raster(long_side: int) -> Image.Image:
    """The mark alone, `long_side` px along its longer axis, no padding."""
    src = master()
    w, h = src.size
    if w >= h:
        size = (long_side, max(1, round(long_side * h / w)))
    else:
        size = (max(1, round(long_side * w / h)), long_side)
    return scaled(src, size)


def mark_image(size: int, scale: float = 1.0) -> Image.Image:
    """The mark centred on a transparent size x size canvas.

    `scale` is the fraction of the box the ink covers on its long side, so
    icon_image(mark_scale=0.62) really does give a mark 62% as wide as the tile.
    """
    mark = mark_raster(max(1, round(size * scale)))
    out = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    out.alpha_composite(mark, ((size - mark.width) // 2,
                               (size - mark.height) // 2))
    return out


# ---------------------------------------------------------------------------
# Tiles
# ---------------------------------------------------------------------------

SS = 4  # supersampling factor for the rounded-corner mask


def rounded_square(size: int, radius_ratio: float,
                   bg: tuple[int, int, int]) -> Image.Image:
    big = size * SS
    mask = Image.new('L', (big, big), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [0, 0, big - 1, big - 1], radius=int(big * radius_ratio), fill=255)
    mask = mask.resize((size, size), Image.LANCZOS)
    tile = Image.new('RGBA', (size, size), bg + (255,))
    out = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    out.paste(tile, (0, 0), mask)
    return out


def icon_image(size: int, bg: tuple[int, int, int] = INK, rounded: bool = True,
               mark_scale: float = 0.62) -> Image.Image:
    base = (rounded_square(size, 0.225, bg) if rounded
            else Image.new('RGBA', (size, size), bg + (255,)))
    base.alpha_composite(mark_image(size, mark_scale))
    return base


def save(img: Image.Image, *rel: str) -> None:
    path = os.path.join(ROOT, *rel)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path, optimize=True)
    print('  ' + os.path.relpath(path, ROOT).replace('\\', '/'))


# ---------------------------------------------------------------------------
# Platform asset sets
# ---------------------------------------------------------------------------

# The mark is 1.24x wider than it is tall, so these long-side fractions can run
# a little larger than they would for a square logo - what has to fit inside a
# safe zone is the diagonal, not the width.
ICON_SCALE = 0.62      # rounded launcher tile
SPLASH_SCALE = 0.56    # splash screens
ADAPTIVE_SCALE = 0.48  # Android adaptive foreground (66% safe circle)
MASKABLE_SCALE = 0.50  # PWA maskable (80% safe circle)

ANDROID_SPLASH = {'mdpi': 256, 'hdpi': 384, 'xhdpi': 512, 'xxhdpi': 768,
                  'xxxhdpi': 1024}
ANDROID_FOREGROUND = {'mdpi': 108, 'hdpi': 162, 'xhdpi': 216, 'xxhdpi': 324,
                      'xxxhdpi': 432}
ANDROID_LAUNCHER = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144,
                    'xxxhdpi': 192}

# flutter_native_splash used to emit these and has since been uninstalled, so
# this script owns them. web/index.html centres the <img> at its intrinsic CSS
# size, which means the 1x variant alone decides how large the splash reads:
# 256 CSS px, matching the native surfaces.
WEB_SPLASH = {'1x': 256, '2x': 512, '3x': 768, '4x': 1024}

IOS_ICONS = [
    ('Icon-App-1024x1024@1x.png', 1024), ('Icon-App-20x20@1x.png', 20),
    ('Icon-App-20x20@2x.png', 40), ('Icon-App-20x20@3x.png', 60),
    ('Icon-App-29x29@1x.png', 29), ('Icon-App-29x29@2x.png', 58),
    ('Icon-App-29x29@3x.png', 87), ('Icon-App-40x40@1x.png', 40),
    ('Icon-App-40x40@2x.png', 80), ('Icon-App-40x40@3x.png', 120),
    ('Icon-App-50x50@1x.png', 50), ('Icon-App-50x50@2x.png', 100),
    ('Icon-App-57x57@1x.png', 57), ('Icon-App-57x57@2x.png', 114),
    ('Icon-App-60x60@2x.png', 120), ('Icon-App-60x60@3x.png', 180),
    ('Icon-App-72x72@1x.png', 72), ('Icon-App-72x72@2x.png', 144),
    ('Icon-App-76x76@1x.png', 76), ('Icon-App-76x76@2x.png', 152),
    ('Icon-App-83.5x83.5@2x.png', 167),
]


def main() -> None:
    rel = os.path.relpath(MASTER, ROOT).replace(os.sep, '/')
    print(f'Align brand assets from {rel} {master().size} ->')

    # Source assets ---------------------------------------------------------
    # The in-app mark is cropped tight to its ink; AlignMark letterboxes it
    # inside a square box, so baked-in padding would only shrink it.
    save(mark_raster(1024), 'assets', 'img', 'logo', 'align-mark.png')
    save(icon_image(1024), 'tool', 'brand', 'align-icon.png')
    # Native splash source: the bare mark on transparency, so the
    # windowSplashScreenBackground colour shows through.
    save(mark_image(1024, SPLASH_SCALE),
         'tool', 'brand', 'align-splash.png')

    # Sources for `dart run flutter_launcher_icons`. It rewrites the same
    # android/ios files this script already emits, so they must agree: the
    # launcher source is an opaque square (iOS rejects alpha and would flatten
    # the rounded corners to white), and the adaptive foreground is padded so
    # the mark survives the 66% safe-zone crop.
    save(icon_image(1024, rounded=False),
         'tool', 'brand', 'align-icon-square.png')
    save(mark_image(1024, ADAPTIVE_SCALE),
         'tool', 'brand', 'align-adaptive-fg.png')

    # Android ---------------------------------------------------------------
    for dpi, px in ANDROID_SPLASH.items():
        img = mark_image(px, SPLASH_SCALE)
        save(img, 'android', 'app', 'src', 'main', 'res',
             f'drawable-{dpi}', 'splash.png')
        save(img, 'android', 'app', 'src', 'main', 'res',
             f'drawable-{dpi}', 'android12splash.png')
        save(img, 'android', 'app', 'src', 'main', 'res',
             f'drawable-night-{dpi}', 'android12splash.png')
    for name in ('drawable', 'drawable-v21'):
        save(Image.new('RGB', (1, 1), INK), 'android', 'app', 'src', 'main',
             'res', name, 'background.png')
    for dpi, px in ANDROID_FOREGROUND.items():
        save(mark_image(px, ADAPTIVE_SCALE), 'android', 'app', 'src', 'main',
             'res', f'drawable-{dpi}', 'ic_launcher_foreground.png')
    for dpi, px in ANDROID_LAUNCHER.items():
        save(icon_image(px, mark_scale=ICON_SCALE), 'android', 'app', 'src',
             'main', 'res', f'mipmap-{dpi}', 'ic_launcher.png')

    # iOS -------------------------------------------------------------------
    for name, px in IOS_ICONS:
        # App Store / springboard art must be opaque and square; iOS applies
        # its own mask.
        save(icon_image(px, rounded=False, mark_scale=ICON_SCALE),
             'ios', 'Runner', 'Assets.xcassets', 'AppIcon.appiconset', name)
    for name, px in (('LaunchImage.png', 256), ('LaunchImage@2x.png', 512),
                     ('LaunchImage@3x.png', 768)):
        save(mark_image(px, SPLASH_SCALE), 'ios', 'Runner', 'Assets.xcassets',
             'LaunchImage.imageset', name)
    save(Image.new('RGB', (1, 1), INK), 'ios', 'Runner', 'Assets.xcassets',
         'LaunchBackground.imageset', 'background.png')

    # Web -------------------------------------------------------------------
    save(icon_image(16, rounded=False), 'web', 'favicon.png')
    save(icon_image(192), 'web', 'icons', 'Icon-192.png')
    save(icon_image(512), 'web', 'icons', 'Icon-512.png')
    save(icon_image(192, rounded=False, mark_scale=MASKABLE_SCALE),
         'web', 'icons', 'Icon-maskable-192.png')
    save(icon_image(512, rounded=False, mark_scale=MASKABLE_SCALE),
         'web', 'icons', 'Icon-maskable-512.png')
    # The page paints #0B1122 behind these, so they stay transparent like every
    # other splash raster. Light and dark are the same art on purpose.
    for suffix, px in WEB_SPLASH.items():
        img = mark_image(px, SPLASH_SCALE)
        save(img, 'web', 'splash', 'img', 'light-' + suffix + '.png')
        save(img, 'web', 'splash', 'img', 'dark-' + suffix + '.png')

    print('done. Contents.json for the iOS icon set is unchanged (same sizes).')


if __name__ == '__main__':
    main()
