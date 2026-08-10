from __future__ import annotations

import json
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
BRAND_DIR = ROOT / "assets" / "branding"
SOURCE_DIR = ROOT / "tooling" / "brand_sources" / "official"

MARK_PRIMARY = SOURCE_DIR / "lugta_mark_primary.png"
MARK_MONOCHROME = SOURCE_DIR / "lugta_mark_monochrome.png"
WORDMARK_PRIMARY = SOURCE_DIR / "lugta_wordmark_primary.png"
WORDMARK_PURPLE = SOURCE_DIR / "lugta_wordmark_purple.png"
WORDMARK_WHITE = SOURCE_DIR / "lugta_wordmark_white.png"

WHITE = (255, 255, 255, 255)
TRANSPARENT = (0, 0, 0, 0)


def official_artwork(path: Path) -> Image.Image:
    """Load an official export and trim only its transparent outer canvas."""

    image = Image.open(path).convert("RGBA")
    bounds = image.getchannel("A").getbbox()
    if bounds is None:
        raise ValueError(f"Official artwork is fully transparent: {path}")
    return image.crop(bounds)


def contain(
    artwork: Image.Image,
    size: tuple[int, int],
    *,
    fraction: float,
    background: tuple[int, int, int, int] = TRANSPARENT,
) -> Image.Image:
    """Place artwork on a deterministic canvas without changing its ratio."""

    canvas = Image.new("RGBA", size, background)
    scale = min(
        size[0] * fraction / artwork.width,
        size[1] * fraction / artwork.height,
    )
    rendered = artwork.resize(
        (
            max(1, round(artwork.width * scale)),
            max(1, round(artwork.height * scale)),
        ),
        Image.Resampling.LANCZOS,
    )
    canvas.alpha_composite(
        rendered,
        (
            (size[0] - rendered.width) // 2,
            (size[1] - rendered.height) // 2,
        ),
    )
    return canvas


def save_png(image: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, format="PNG", optimize=True)


def app_icon(size: int, *, safe_fraction: float = 0.78) -> Image.Image:
    return contain(
        official_artwork(MARK_PRIMARY),
        (size, size),
        fraction=safe_fraction,
        background=WHITE,
    )


def adaptive_foreground(size: int, *, monochrome: bool = False) -> Image.Image:
    source = MARK_MONOCHROME if monochrome else MARK_PRIMARY
    return contain(
        official_artwork(source),
        (size, size),
        fraction=0.68,
    )


def generate_flutter_assets() -> None:
    save_png(
        contain(official_artwork(MARK_PRIMARY), (1024, 1024), fraction=0.84),
        BRAND_DIR / "lugta_icon_mark.png",
    )
    save_png(app_icon(1024), BRAND_DIR / "lugta_app_icon.png")
    save_png(
        contain(official_artwork(WORDMARK_PRIMARY), (1800, 760), fraction=0.94),
        BRAND_DIR / "lugta_wordmark_ink.png",
    )
    save_png(
        contain(official_artwork(WORDMARK_WHITE), (1800, 760), fraction=0.94),
        BRAND_DIR / "lugta_wordmark_white.png",
    )
    save_png(
        contain(official_artwork(WORDMARK_PURPLE), (1800, 760), fraction=0.94),
        BRAND_DIR / "lugta_wordmark_mono.png",
    )


def generate_android_icons() -> None:
    res = ROOT / "android" / "app" / "src" / "main" / "res"
    legacy_sizes = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    adaptive_sizes = {
        "mipmap-mdpi": 108,
        "mipmap-hdpi": 162,
        "mipmap-xhdpi": 216,
        "mipmap-xxhdpi": 324,
        "mipmap-xxxhdpi": 432,
    }
    for folder, size in legacy_sizes.items():
        icon = app_icon(size)
        save_png(icon, res / folder / "ic_launcher.png")
        save_png(icon, res / folder / "ic_launcher_round.png")
    for folder, size in adaptive_sizes.items():
        save_png(
            adaptive_foreground(size),
            res / folder / "ic_launcher_foreground.png",
        )
        save_png(
            adaptive_foreground(size, monochrome=True),
            res / folder / "ic_launcher_monochrome.png",
        )

    launch_wordmark = contain(
        official_artwork(WORDMARK_WHITE),
        (640, 240),
        fraction=0.9,
    )
    save_png(launch_wordmark, res / "drawable-nodpi" / "launch_logo.png")


def generate_ios_icons() -> None:
    icon_dir = ROOT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
    manifest = json.loads((icon_dir / "Contents.json").read_text(encoding="utf-8"))
    master = app_icon(1024).convert("RGB")
    for entry in manifest["images"]:
        filename = entry.get("filename")
        if not filename:
            continue
        points = float(entry["size"].split("x")[0])
        scale = int(entry["scale"].removesuffix("x"))
        pixels = round(points * scale)
        save_png(
            master.resize((pixels, pixels), Image.Resampling.LANCZOS),
            icon_dir / filename,
        )

    launch_dir = ROOT / "ios" / "Runner" / "Assets.xcassets" / "LaunchImage.imageset"
    inverse = official_artwork(WORDMARK_WHITE)
    for scale in (1, 2, 3):
        size = (220 * scale, 180 * scale)
        launch = contain(inverse, size, fraction=0.82)
        suffix = "" if scale == 1 else f"@{scale}x"
        save_png(launch, launch_dir / f"LaunchImage{suffix}.png")


def generate_web_icons() -> None:
    web = ROOT / "web"
    regular = app_icon(512)
    maskable = app_icon(512, safe_fraction=0.64)
    save_png(
        regular.resize((192, 192), Image.Resampling.LANCZOS),
        web / "icons" / "Icon-192.png",
    )
    save_png(regular, web / "icons" / "Icon-512.png")
    save_png(
        maskable.resize((192, 192), Image.Resampling.LANCZOS),
        web / "icons" / "Icon-maskable-192.png",
    )
    save_png(maskable, web / "icons" / "Icon-maskable-512.png")
    save_png(
        regular.resize((64, 64), Image.Resampling.LANCZOS),
        web / "favicon.png",
    )


def main() -> None:
    for required in (
        MARK_PRIMARY,
        MARK_MONOCHROME,
        WORDMARK_PRIMARY,
        WORDMARK_PURPLE,
        WORDMARK_WHITE,
    ):
        if not required.exists():
            raise SystemExit(f"Missing official Lugta artwork: {required}")
    BRAND_DIR.mkdir(parents=True, exist_ok=True)
    generate_flutter_assets()
    generate_android_icons()
    generate_ios_icons()
    generate_web_icons()


if __name__ == "__main__":
    main()
